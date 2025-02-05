#define OPENCV_DISABLE_MODULES
#define NOMINMAX
#undef NO
#import "ImageProcessor.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#undef check

using namespace cv;

@implementation ImageProcessor

// Convertir UIImage a Mat y calcular momentos de Hu
+ (NSArray<NSNumber *> *)calculateHuMomentsFromUIImage:(UIImage *)image {
    cv::Mat mat;
    UIImageToMat(image, mat);
    cv::cvtColor(mat, mat, cv::COLOR_RGBA2GRAY);
    cv::threshold(mat, mat, 128, 255, cv::THRESH_BINARY);

    cv::Moments momentos = cv::moments(mat, true);
    double hu[7];
    cv::HuMoments(momentos, hu);

    NSMutableArray *huArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < 7; i++) {
        [huArray addObject:[NSNumber numberWithDouble:hu[i]]];
    }
    return huArray;
}

+ (NSArray<NSNumber *> *)calculateZernikeMomentsFromImage:(UIImage *)image {
    // Convert UIImage to cv::Mat
    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    
    cv::Mat mat(height, width, CV_8UC1);
    CGContextRef context = CGBitmapContextCreate(mat.data, width, height, 8, mat.step[0], colorSpace, kCGImageAlphaNone);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    // Ensure grayscale
    if (mat.channels() == 3) {
        cvtColor(mat, mat, COLOR_BGR2GRAY);
    }
    
    // Apply thresholding to binarize the image
    threshold(mat, mat, 100, 255, THRESH_BINARY);

    // Compute Zernike Moments (Ejemplo con OpenCV)
    std::vector<Moments> moments;
    findContours(mat, moments, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);
    
    std::vector<double> zernikeFeatures;
    for (const auto& m : moments) {
        double hu[7];
        HuMoments(m, hu);
        for (double val : hu) {
            zernikeFeatures.push_back(val);
        }
    }

    // Convert vector to NSArray
    NSMutableArray *result = [NSMutableArray array];
    for (double val : zernikeFeatures) {
        [result addObject:@(val)];
    }

    return result;
}

// Calcular distancia euclidiana
+ (double)euclideanDistance:(std::vector<double>)a with:(std::vector<double>)b {
    double sum = 0.0;
    for (size_t i = 0; i < a.size(); i++) {
        sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
}

// Clasificar la imagen comparándola con el CSV
+ (NSString *)classifyImage:(UIImage *)image withCSV:(NSString *)csvPath {
    std::vector<std::pair<std::string, std::vector<double>>> datosCSV;

    // Leer CSV
    std::ifstream file([csvPath UTF8String]);
    if (!file.is_open()) {
        return @"Error al abrir el CSV";
    }
    
    std::string line;
    std::getline(file, line); // Omitir cabecera
    while (std::getline(file, line)) {
        std::stringstream ss(line);
        std::string categoria;
        std::vector<double> momentos;
        std::string valor;

        std::getline(ss, categoria, ',');
        while (std::getline(ss, valor, ',')) {
            momentos.push_back(std::stod(valor));
        }
        
        datosCSV.emplace_back(categoria, momentos);
    }

    // Obtener momentos de Hu de la imagen
    cv::Mat mat;
    UIImageToMat(image, mat);
    cv::cvtColor(mat, mat, cv::COLOR_RGBA2GRAY);
    cv::threshold(mat, mat, 128, 255, cv::THRESH_BINARY);

    cv::Moments momentos = cv::moments(mat, true);
    double hu[7];
    cv::HuMoments(momentos, hu);
    std::vector<double> momentosImagen(hu, hu + 7);

    // Clasificación
    std::string mejorCategoria;
    double menorDistancia = std::numeric_limits<double>::max();

    for (const auto& [categoria, momentos] : datosCSV) {
        double distancia = [ImageProcessor euclideanDistance:momentosImagen with:momentos];
        if (distancia < menorDistancia) {
            menorDistancia = distancia;
            mejorCategoria = categoria;
        }
    }

    return [NSString stringWithUTF8String:mejorCategoria.c_str()];
}

@end
