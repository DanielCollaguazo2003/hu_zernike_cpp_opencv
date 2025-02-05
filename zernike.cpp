#include "zernike.h"
#include <cmath>
#include <iostream>

using namespace std;

double factorial(int n) {
    return (n <= 1) ? 1 : n * factorial(n - 1);
}

double radialPolynomial(int n, int m, double r) {
    double sum = 0.0;
    for (int k = 0; k <= (n - m) / 2; k++) {
        double num = pow(-1, k) * factorial(n - k);
        double denom = factorial(k) * factorial((n + m) / 2 - k) * factorial((n - m) / 2 - k);
        sum += (num / denom) * pow(r, n - 2 * k);
    }
    return sum;
}

vector<vector<double>> convertirImagenAMatriz(const cv::Mat& img) {
    vector<vector<double>> matriz(img.rows, vector<double>(img.cols, 0.0));

    for (int i = 0; i < img.rows; i++) {
        for (int j = 0; j < img.cols; j++) {
            matriz[i][j] = img.at<uchar>(i, j) / 255.0;
        }
    }
    return matriz;
}

vector<ZernikeMoment> calcularMomentosZernike(const cv::Mat& img, int maxOrder) {
    vector<vector<double>> imgMatrix = convertirImagenAMatriz(img);
    int size = img.rows;
    vector<ZernikeMoment> momentos;

    for (int n = 0; n <= maxOrder; n++) {
        for (int m = -n; m <= n; m += 2) {
            complex<double> Znm(0, 0);

            for (int y = 0; y < size; y++) {
                for (int x = 0; x < size; x++) {
                    double r = sqrt(pow(x - size / 2, 2) + pow(y - size / 2, 2)) / (size / 2);
                    double theta = atan2(y - size / 2, x - size / 2);

                    if (r <= 1) {
                        double Rnm = radialPolynomial(n, abs(m), r);
                        complex<double> term(Rnm * cos(m * theta), -Rnm * sin(m * theta));
                        Znm += term * imgMatrix[y][x];
                    }
                }
            }

            ZernikeMoment zm;
            zm.n = n;
            zm.m = m;
            zm.magnitude = abs(Znm);
            zm.phase = arg(Znm);
            momentos.push_back(zm);
        }
    }
    return momentos;
}
