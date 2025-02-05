all:
	g++ zernike_prediction.cpp zernike.cpp -std=c++17 \
    -I/home/daniel/aplicaciones/Librerias/opencv/opencvi/include/opencv4/ \
    -L/home/daniel/aplicaciones/Librerias/opencv/opencvi/lib \
    -o zernike.bin \
    -lopencv_core -lopencv_imgproc -lopencv_highgui -lopencv_imgcodecs -ltbb

run:
	./zernike.bin