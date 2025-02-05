#include "zernike.h"
#include <opencv2/opencv.hpp>
#include <fstream>
#include <sstream>
#include <cmath>

std::vector<ZernikeMoment> calcularMomentosZernike(const cv::Mat& imagen, int orden) {
    std::vector<ZernikeMoment> momentos;
    
    // Implementación del cálculo de momentos de Zernike
    // (esto depende de la librería que uses o si lo haces manualmente)

    return momentos;
}

std::map<std::string, std::vector<double>> cargarMomentosDesdeCSV(const std::string& rutaCSV) {
    std::map<std::string, std::vector<double>> datos;
    std::ifstream archivo(rutaCSV);
    std::string linea;

    while (std::getline(archivo, linea)) {
        std::stringstream ss(linea);
        std::string etiqueta;
        std::vector<double> valores;
        std::string valor;

        std::getline(ss, etiqueta, ',');
        while (std::getline(ss, valor, ',')) {
            valores.push_back(std::stod(valor));
        }

        datos[etiqueta] = valores;
    }

    return datos;
}

std::string clasificarConZernike(const std::vector<ZernikeMoment>& momentos, const std::map<std::string, std::vector<double>>& referencias) {
    double mejorDistancia = std::numeric_limits<double>::max();
    std::string mejorClase;

    for (const auto& [clase, refValores] : referencias) {
        double distancia = 0.0;

        for (size_t i = 0; i < momentos.size() && i < refValores.size(); ++i) {
            distancia += std::pow(momentos[i].magnitude - refValores[i], 2);
        }

        distancia = std::sqrt(distancia);
        if (distancia < mejorDistancia) {
            mejorDistancia = distancia;
            mejorClase = clase;
        }
    }

    return mejorClase;
}
