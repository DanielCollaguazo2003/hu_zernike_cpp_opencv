#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <Foundation/Foundation.h>
#import "FilterApplicatorBridge.h"
#include "FilterApplicator.hpp"

@implementation FilterApplicatorBridge {
    FilterApplicator filterApplicator; // Instancia del aplicador de filtros
}

- (UIImage *) apply_filter: (UIImage *) image {
    @try {
        return [self apply_filter:image useClahe:0 withReferenceMat:NULL];
    }
    @catch (NSException *exception) {
        NSLog(@"Excepción inesperada en Objective-C: %@", exception.reason);
        return image; // Devolver la imagen original en caso de error inesperado
    }
}

- (void *)loadAndResizeImages:(NSArray<NSString *> *)imagePaths subFrameSize:(CGSize)subFrameSize {
    @try {
        // Convertir el array de NSStrings a std::vector<std::string>
        std::vector<std::string> paths;
        for (NSString *imagePath in imagePaths) {
            paths.push_back([imagePath UTF8String]);
        }

        // Crear un puntero al vector de imágenes redimensionadas
        std::vector<cv::Mat> *resizedImages = new std::vector<cv::Mat>(256);

        // Llamar a la función de C++ que procesa las imágenes
        if (!filterApplicator.loadAndResizeImages(paths, resizedImages, cv::Size(subFrameSize.width, subFrameSize.height))) {
            // Si ocurre un error en el proceso
            delete resizedImages; // Liberar memoria si falla
            NSLog(@"Error: no se pudieron cargar o redimensionar algunas imágenes.");
            return NULL;
        }

        // Retornar el puntero al vector
        return static_cast<void *>(resizedImages);
    }
    @catch (NSException *exception) {
        NSLog(@"Excepción inesperada: %@", exception.reason);
        return NULL;
    }
}

// Liberar memoria del Mat cargado
- (void)releaseMat:(void *)matPtr {
    if (matPtr != NULL) {
        Mat *mat = static_cast<Mat *>(matPtr);
        delete mat; // Liberar memoria
        matPtr = NULL;
    }
}

// Procesar imagen con referencia al Mat
- (UIImage *)apply_filter:(UIImage *)image useClahe:(int)useClahe withReferenceMat:(void *)referenceMatPtr{
    @try {
        return [self processImage:image useClahe:useClahe withReferenceMat:referenceMatPtr];
    }
    @catch (NSException *exception) {
        NSLog(@"Excepción inesperada en Objective-C: %@", exception.reason);
        return image; // Devolver la imagen original en caso de error inesperado
    }
}

// Método interno para aplicar el filtro
- (UIImage *)processImage:(UIImage *)image useClahe:(int)useClahe withReferenceMat:(void *)referenceMatPtr {
    UIImage *processedImage = image; // Imagen por defecto en caso de fallo

    try {
        // Convertir UIImage a cv::Mat
        cv::Mat opencvImage;
        UIImageToMat(image, opencvImage, true);

        if (opencvImage.empty() || opencvImage.cols < 10 || opencvImage.rows < 10) {
            NSLog(@"Imagen inválida tras la conversión: dimensiones (%d x %d)", opencvImage.cols, opencvImage.rows);
            return processedImage;
        }

        // Convertir espacio de color (RGBA a RGB)
        cv::Mat convertedColorSpaceImage;
        cv::cvtColor(opencvImage, convertedColorSpaceImage, cv::COLOR_RGBA2RGB);

        if (convertedColorSpaceImage.empty() || convertedColorSpaceImage.cols < 10 || convertedColorSpaceImage.rows < 10) {
            NSLog(@"Imagen inválida tras la conversión de espacio de color: dimensiones (%d x %d)", convertedColorSpaceImage.cols, convertedColorSpaceImage.rows);
            return processedImage;
        }

        // Aplicar filtro utilizando el Mat de referencia
        cv::Mat imageWithFilterApplied = filterApplicator.apply_filter(convertedColorSpaceImage, useClahe, referenceMatPtr);

        if (imageWithFilterApplied.empty() || imageWithFilterApplied.cols < 10 || imageWithFilterApplied.rows < 10) {
            NSLog(@"Imagen inválida tras aplicar el filtro: dimensiones (%d x %d)", imageWithFilterApplied.cols, imageWithFilterApplied.rows);
            return processedImage;
        }

        // Convertir cv::Mat a UIImage y devolver
        processedImage = MatToUIImage(imageWithFilterApplied);
    }
    catch (const cv::Exception &e) {
        NSLog(@"Excepción de OpenCV: %s", e.what());
    }
    catch (...) {
        NSLog(@"Excepción desconocida en OpenCV.");
    }

    return processedImage;
}

@end
