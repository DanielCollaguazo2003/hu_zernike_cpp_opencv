#ifndef ZERNIKE_H
#define ZERNIKE_H

#include <opencv2/opencv.hpp>
#include <vector>
#include <complex>

struct ZernikeMoment {
    int n, m;
    double magnitude, phase;
};

std::vector<std::vector<double>> convertirImagenAMatriz(const cv::Mat& img);

std::vector<ZernikeMoment> calcularMomentosZernike(const cv::Mat& img, int maxOrder);

#endif 
