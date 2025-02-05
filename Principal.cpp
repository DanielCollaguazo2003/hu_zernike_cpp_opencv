#include <opencv2/opencv.hpp>
#include <iostream>
#include <filesystem>
#include <fstream>

namespace fs = std::filesystem;

std::vector<double> calcularMomentosHu(const cv::Mat& img) {
    cv::Moments momentos = cv::moments(img, true);
    double hu[7];
    cv::HuMoments(momentos, hu);
    return std::vector<double>(hu, hu + 7);
}

int main() {
    std::string dataset_path = "./all-images";
    std::vector<std::string> categorias = {"circle", "square", "triangle"};
    std::ofstream archivoCSV("momentos.csv");
    archivoCSV << "categoria,m1,m2,m3,m4,m5,m6,m7" << std::endl;

    for (const auto& categoria : categorias) {
        std::string path_categoria = dataset_path + "/" + categoria;
        for (const auto& entry : fs::directory_iterator(path_categoria)) {
            std::string imagen_path = entry.path().string();
            
            cv::Mat img = cv::imread(imagen_path, cv::IMREAD_GRAYSCALE);
            if (img.empty()) {
                std::cerr << "No se pudo abrir la imagen: " << imagen_path << std::endl;
                continue;
            }
            
            cv::Mat binaria;
            cv::threshold(img, binaria, 128, 255, cv::THRESH_BINARY);
            
            std::vector<double> momentosHu = calcularMomentosHu(binaria);
            
            archivoCSV << categoria;
            for (double val : momentosHu) {
                archivoCSV << "," << val;
            }
            archivoCSV << std::endl;
        }
    }
    archivoCSV.close();
    std::cout << "Momentos de Hu guardados en momentos.csv" << std::endl;
    return 0;
}
