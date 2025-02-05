#include <opencv2/opencv.hpp>
#include "zernike.h"
#include <iostream>

using namespace cv;
using namespace std;

int main() {
    string imgPath;
    cout << "Ingrese la ruta de la imagen: ";
    cin >> imgPath;

    Mat img = imread(imgPath, IMREAD_GRAYSCALE);
    if (img.empty()) {
        cerr << "No se pudo cargar la imagen." << endl;
        return 1;
    }

    Mat binaria;
    threshold(img, binaria, 128, 255, THRESH_BINARY);

    vector<vector<double>> imagenProcesada(binaria.rows, vector<double>(binaria.cols));
    for (int i = 0; i < binaria.rows; i++) {
        for (int j = 0; j < binaria.cols; j++) {
            imagenProcesada[i][j] = binaria.at<uchar>(i, j) / 255.0;
        }
    }

    vector<ZernikeMoment> momentos = calcularMomentosZernike(imagenProcesada, 4);

    cout << "Momentos de Zernike:" << endl;
    for (const auto& m : momentos) {
        cout << "n=" << m.n << ", m=" << m.m << " -> Magnitud: " << m.magnitude << ", Fase: " << m.phase << endl;
    }

    return 0;
}
