#import "ZernikeBridge.h"
#import "zernike.h"  // Implementación en C++ para calcular momentos de Zernike
#import <opencv2/opencv.hpp>
#import <fstream>
#import <sstream>

@implementation ZernikeBridge

cv::Mat UIImageToMat(UIImage *image) {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    cv::Mat mat(rows, cols, CV_8UC1);  // Escala de grises

    CGContextRef contextRef = CGBitmapContextCreate(mat.data, cols, rows, 8, mat.step[0], colorSpace, kCGImageAlphaNone);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);

    return mat;
}

std::vector<std::pair<std::string, std::vector<double>>> cargarCSV(const std::string& rutaCSV) {
    std::vector<std::pair<std::string, std::vector<double>>> datos;
    std::ifstream archivo(rutaCSV);
    std::string linea;

    if (!archivo.is_open()) {
        std::cerr << "Error: No se pudo abrir el archivo " << rutaCSV << std::endl;
        return datos;
    }

    std::getline(archivo, linea);  // Omitir cabecera
    while (std::getline(archivo, linea)) {
        std::stringstream ss(linea);
        std::string categoria;
        std::vector<double> momentos;
        std::string valor;

        std::getline(ss, categoria, ',');
        while (std::getline(ss, valor, ',')) {
            momentos.push_back(std::stod(valor));
        }
        datos.emplace_back(categoria, momentos);
    }

    return datos;
}

std::vector<double> calcularMomentosZernike(const cv::Mat& img) {
    std::vector<ZernikeMoment> momentos = calcularMomentosZernike(img, 10);
    std::vector<double> resultados;
    for (const auto& momento : momentos) {
        resultados.push_back(momento.magnitude);
    }
    return resultados;
}

double distanciaEuclidiana(const std::vector<double>& a, const std::vector<double>& b) {
    double suma = 0.0;
    for (size_t i = 0; i < a.size(); ++i) {
        suma += std::pow(a[i] - b[i], 2);
    }
    return std::sqrt(suma);
}

std::string clasificarImagen(const std::vector<double>& momentos, const std::vector<std::pair<std::string, std::vector<double>>>& datosCSV) {
    std::string mejorCategoria;
    double menorDistancia = std::numeric_limits<double>::max();

    for (const auto& [categoria, momentosCSV] : datosCSV) {
        double distancia = distanciaEuclidiana(momentos, momentosCSV);
        if (distancia < menorDistancia) {
            menorDistancia = distancia;
            mejorCategoria = categoria;
        }
    }

    return mejorCategoria;
}

// Predicción desde Swift
- (NSString *)predictWithImage:(UIImage *)image csvPath:(NSString *)csvPath {
    cv::Mat img = UIImageToMat(image);
    cv::threshold(img, img, 128, 255, cv::THRESH_BINARY);

    std::vector<double> momentos = calcularMomentosZernike(img);
    std::vector<std::pair<std::string, std::vector<double>>> datosCSV = cargarCSV([csvPath UTF8String]);

    if (datosCSV.empty()) {
        return @"Error: No se pudieron cargar los datos del CSV";
    }

    std::string categoria = clasificarImagen(momentos, datosCSV);
    return [NSString stringWithUTF8String:categoria.c_str()];
}

@end