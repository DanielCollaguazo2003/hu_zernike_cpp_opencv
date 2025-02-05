#include "FilterApplicator.hpp"

using namespace cv;
using namespace std;

bool FilterApplicator::loadAndResizeImages(
    const std::vector<std::string> &imagePaths,
    std::vector<cv::Mat> *resizedImages,
    cv::Size targetSize) {

    for (size_t i = 0; i < imagePaths.size(); ++i) {
        // Cargar la imagen desde el path
        cv::Mat img = cv::imread(imagePaths[i], cv::IMREAD_GRAYSCALE);
        if (!img.empty()) {
            // Redimensionar la imagen
            cv::resize(img, img, targetSize);
            (*resizedImages)[i] = img; // Guardar en el vector
        } else {
            std::cerr << "Error: no se pudo cargar la imagen en " << imagePaths[i] << std::endl;
            return false; // Retornar error si alguna imagen falla
        }
    }

    return true; // Procesamiento exitoso
}

Mat FilterApplicator::apply_filter(Mat image) {
    flip(image, image, 1);
    int subFrameSize = 12;
    int width = 0, height = 0;
    
    flip(image, image, 1);
    resize(image, image, Size(), 0.3, 0.3);

    for (int i = 0; i < image.cols; i += subFrameSize) {
        for (int j = 0; j < image.rows; j += subFrameSize) {
            if (i + subFrameSize > image.cols) {
                width = image.cols - i;
            } else {
                width = subFrameSize;
            }

            if (j + subFrameSize > image.rows) {
                height = image.rows - j;
            } else {
                height = subFrameSize;
            }

            Mat subFrame = image(Rect(i, j, width, height));

            vector<Mat> canales;
            split(subFrame, canales);

            double promedioAzul = mean(canales[0])[0];
            double promedioVerde = mean(canales[1])[0];
            double promedioRojo = mean(canales[2])[0];

            rectangle(image, Rect(i, j, subFrameSize, subFrameSize), Scalar(promedioAzul, promedioVerde, promedioRojo), FILLED);
        }
    }

    return image;
}

Mat FilterApplicator::apply_filter(Mat image, int useClahe, void* referenceMatPtr) {
    if (referenceMatPtr == nullptr) {
        return image;
    }

    std::vector<cv::Mat>* refImages = static_cast<std::vector<cv::Mat>*>(referenceMatPtr);

    // Asegurar que `image` tiene 3 canales
    if (image.channels() != 3) {
        cvtColor(image, image, COLOR_GRAY2BGR);
    }

    int subFrameSize = 12;
    int width = 0, height = 0;

    resize(image, image, Size(), 0.3, 0.3);

    if (useClahe == 1) {
        Mat lab;
        cvtColor(image, lab, COLOR_BGR2Lab);

        vector<Mat> lab_planes;
        split(lab, lab_planes);

        Ptr<CLAHE> clahe = createCLAHE(25, Size(subFrameSize, subFrameSize));

        clahe->apply(lab_planes[0], lab_planes[0]);

        merge(lab_planes, lab);
        cvtColor(lab, image, COLOR_Lab2BGR);
    }

    for (int i = 0; i < image.cols; i += subFrameSize) {
        for (int j = 0; j < image.rows; j += subFrameSize) {
            width = (i + subFrameSize > image.cols) ? image.cols - i : subFrameSize;
            height = (j + subFrameSize > image.rows) ? image.rows - j : subFrameSize;

            Mat subFrame = image(Rect(i, j, width, height));

            vector<Mat> canales;
            split(subFrame, canales);

            double promedioAzul = mean(canales[0])[0];
            double promedioVerde = mean(canales[1])[0];
            double promedioRojo = mean(canales[2])[0];

            rectangle(image, Rect(i, j, width, height), Scalar(promedioAzul, promedioVerde, promedioRojo), FILLED);

            double totalColor = promedioAzul + promedioVerde + promedioRojo;
            double blueRatio = promedioAzul / totalColor;
            double greenRatio = promedioVerde / totalColor;
            double redRatio = promedioRojo / totalColor;

            double promedio = mean(subFrame)[0];
            int intensityIndex = static_cast<int>(promedio);
            intensityIndex = std::clamp(intensityIndex, 0, static_cast<int>(refImages->size()) - 1);

            Mat& selectedImage = (*refImages)[intensityIndex];
            Mat resizedImage;
            resize(selectedImage, resizedImage, Size(width, height));

            Mat blueChannel, greenChannel, redChannel;
            resizedImage.convertTo(blueChannel, CV_8UC1, blueRatio);
            resizedImage.convertTo(greenChannel, CV_8UC1, greenRatio);
            resizedImage.convertTo(redChannel, CV_8UC1, redRatio);

            vector<Mat> resultChannels = {blueChannel, greenChannel, redChannel};
            Mat resultImage;
            merge(resultChannels, resultImage);
            resize(resultImage, resultImage, Size(width, height));
            
            for (int x = 0; x < width; x++) {
                for (int y = 0; y < height; y++) {
                    int globalX = i + x;
                    int globalY = j + y;

                    if (globalX < image.cols && globalY < image.rows) {
                        Vec3b pixel = resultImage.at<Vec3b>(y, x);
                        image.at<Vec3b>(globalY, globalX) = pixel;
                    }
                }
            }
        }
    }

    return image;
}
