#include <opencv2/opencv.hpp>
#include <iostream>
#include <filesystem>
#include <fstream>
#include <vector>
#include <sstream>
#include <limits>
#include <cmath>

namespace fs = std::filesystem;

std::vector<double> calcularMomentosHu(const cv::Mat& img) {
    cv::Moments momentos = cv::moments(img, true);
    double hu[7];
    cv::HuMoments(momentos, hu);
    return std::vector<double>(hu, hu + 7);
}
std::vector<std::pair<std::string, std::vector<double>>> cargarMomentosDesdeCSV(const std::string& filename) {
    std::vector<std::pair<std::string, std::vector<double>>> datos;
    std::ifstream archivo(filename);
    std::string linea;
    
    if (!archivo.is_open()) {
        std::cerr << "Error al abrir el archivo CSV." << std::endl;
        return datos;
    }
    
    std::getline(archivo, linea);
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

double distanciaEuclidiana(const std::vector<double>& a, const std::vector<double>& b) {
    double suma = 0.0;
    for (size_t i = 0; i < a.size(); ++i) {
        suma += std::pow(a[i] - b[i], 2);
    }
    return std::sqrt(suma);
}

std::string clasificarImagen(const std::vector<double>& momentosImagen, const std::vector<std::pair<std::string, std::vector<double>>>& datosCSV) {
    std::string mejorCategoria;
    double menorDistancia = std::numeric_limits<double>::max();
    
    for (const auto& [categoria, momentos] : datosCSV) {
        double distancia = distanciaEuclidiana(momentosImagen, momentos);
        if (distancia < menorDistancia) {
            menorDistancia = distancia;
            mejorCategoria = categoria;
        }
    }
    
    return mejorCategoria;
}

int main() {
    std::string csv_path = "./momentos.csv";
    std::vector<std::pair<std::string, std::vector<double>>> datosCSV = cargarMomentosDesdeCSV(csv_path);
    
    if (datosCSV.empty()) {
        std::cerr << "No se pudieron cargar los datos del CSV." << std::endl;
        return 1;
    }
    
    std::string imagen_path;
    std::cout << "Ingrese la ruta de la imagen a clasificar: ";
    std::cin >> imagen_path;

    cv::Mat img = cv::imread(imagen_path, cv::IMREAD_GRAYSCALE);
    if (img.empty()) {
        std::cerr << "No se pudo abrir la imagen." << std::endl;
        return 1;
    }

    cv::Mat binaria;
    cv::threshold(img, binaria, 128, 255, cv::THRESH_BINARY);

    std::vector<double> momentosHu = calcularMomentosHu(binaria);

    std::string categoria = clasificarImagen(momentosHu, datosCSV);
    std::cout << "La imagen pertenece a la categoría: " << categoria << std::endl;
    
    return 0;
}