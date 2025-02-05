#ifndef ZERNIKE_H
#define ZERNIKE_H

#include <vector>
#include <string>
#include <opencv2/opencv.hpp>

struct ZernikeMoment {
    double magnitude;
    double angle;
};

// Calcula momentos de Zernike hasta cierto orden
std::vector<ZernikeMoment> calcularMomentosZernike(const cv::Mat& imagen, int orden);

// Cargar momentos desde un archivo CSV
std::map<std::string, std::vector<double>> cargarMomentosDesdeCSV(const std::string& rutaCSV);

// Clasificar la imagen comparando momentos de Zernike con los datos del CSV
std::string clasificarConZernike(const std::vector<ZernikeMoment>& momentos, const std::map<std::string, std::vector<double>>& referencias);

#endif
