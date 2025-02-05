#include "zernike.h"
#include <opencv2/opencv.hpp>
#include <iostream>
#include <fstream>
#include <filesystem>

namespace fs = std::filesystem;
using namespace std;

void guardarMomentosEnCSV(const string& filename, const vector<pair<string, vector<ZernikeMoment>>>& datos) {
    ofstream archivo(filename);
    if (!archivo.is_open()) {
        cerr << "Error al abrir el archivo CSV para escritura." << endl;
        return;
    }

    archivo << "categoria";
    for (int i = 0; i < datos[0].second.size(); i++) {
        archivo << ",Z" << datos[0].second[i].n << "_" << datos[0].second[i].m << "_mag";
        archivo << ",Z" << datos[0].second[i].n << "_" << datos[0].second[i].m << "_phase";
    }
    archivo << "\n";

    for (const auto& [categoria, momentos] : datos) {
        archivo << categoria;
        for (const auto& m : momentos) {
            archivo << "," << m.magnitude << "," << m.phase;
        }
        archivo << "\n";
    }

    archivo.close();
}

int main() {
    string dataset_path = "./all-images";
    int maxOrder = 4;

    vector<pair<string, vector<ZernikeMoment>>> datosCSV;

    for (const auto& entry : fs::directory_iterator(dataset_path)) {
        if (!entry.is_directory()) continue;
        
        string categoria = entry.path().filename().string();

        for (const auto& img_entry : fs::directory_iterator(entry.path())) {
            string img_path = img_entry.path().string();
            cv::Mat img = cv::imread(img_path, cv::IMREAD_GRAYSCALE);

            if (img.empty()) {
                cerr << "No se pudo abrir la imagen: " << img_path << endl;
                continue;
            }

            cv::Mat binaria;
            cv::threshold(img, binaria, 128, 255, cv::THRESH_BINARY);

            vector<ZernikeMoment> momentosZernike = calcularMomentosZernike(binaria, maxOrder);
            datosCSV.push_back({categoria, momentosZernike});
        }
    }

    string csv_path = "momentos_zernike.csv";
    guardarMomentosEnCSV(csv_path, datosCSV);
    
    cout << "CSV generado exitosamente: " << csv_path << endl;
    return 0;
}
