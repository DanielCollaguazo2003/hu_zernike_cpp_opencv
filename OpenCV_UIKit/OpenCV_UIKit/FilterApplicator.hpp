#include <opencv2/opencv.hpp>

using namespace cv;
using namespace std;

class FilterApplicator {
public:
    bool loadAndResizeImages(const std::vector<std::string> &imagePaths,
                             std::vector<cv::Mat> *resizedImages,
                             cv::Size targetSize);
    
    Mat apply_filter(Mat image);
    
    Mat apply_filter(Mat image, int useClahe, void* referenceMatPtr);
};
