//
//  OpticalFlow.cpp
//  OpenCVTest
//
//  Created by Hardik Devrangadi on 5/3/23.
//

#include "OpticalFlow.hpp"
#include <iostream>
#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include <opencv2/imgproc.hpp>
#include <opencv2/videoio.hpp>
#include <opencv2/video.hpp>
//#include <opencv2/optflow.hpp>
#include <opencv2/opencv.hpp>
#include <fstream>

//
//  LaneDetector.cpp
//  SimpleLaneDetection
//
//  Created by Anurag Ajwani on 28/04/2019.
//  Copyright © 2019 Anurag Ajwani. All rights reserved.
//

using namespace cv;
using namespace std;

double getAverage(vector<double> vector, int nElements) {
    
    double sum = 0;
    int initialIndex = 0;
    int last30Lines = int(vector.size()) - nElements;
    if (last30Lines > 0) {
        initialIndex = last30Lines;
    }
    
    for (int i=(int)initialIndex; i<vector.size(); i++) {
        sum += vector[i];
    }
    
    int size;
    if (vector.size() < nElements) {
        size = (int)vector.size();
    } else {
        size = nElements;
    }
    return (double)sum/size;
}

Mat LaneDetector::detect_lane(Mat image) {
    
    // Convert image to grayscale
    cv::Mat gray;
    cv::cvtColor(image, gray, cv::COLOR_BGR2GRAY);

    // Apply bilateral filter to smooth the image while preserving edges
    cv::Mat smooth;
    cv::bilateralFilter(gray, smooth, 2, 75, 75);

    // Detect edges using Canny edge detection
    cv::Mat edges;
    cv::Canny(smooth, edges, 80, 50, 3, false);
    
//       cv::adaptiveThreshold(edges, edges, 255, cv::ADAPTIVE_THRESH_MEAN_C, cv::THRESH_BINARY_INV, 3,7);

    cv::Mat inverted;
    cv::bitwise_not(edges, inverted);

    return inverted;
}

//Mat LaneDetector::filter_only_yellow_white(Mat image) {
//
//    Mat hlsColorspacedImage;
//    cvtColor(image, hlsColorspacedImage, CV_RGB2HLS);
//
//    Mat yellowMask;
//    Scalar yellowLower = Scalar(10, 0, 90);
//    Scalar yellowUpper = Scalar(50, 255, 255);
//    inRange(hlsColorspacedImage, yellowLower, yellowUpper, yellowMask);
//
//    Mat whiteMask;
//    Scalar whiteLower = Scalar(0, 190, 0);
//    Scalar whiteUpper = Scalar(255, 255, 255);
//    inRange(hlsColorspacedImage, whiteLower, whiteUpper, whiteMask);
//
//    Mat mask;
//    bitwise_or(yellowMask, whiteMask, mask);
//
//    Mat maskedImage;
//    bitwise_and(image, image, maskedImage, mask);
//
//    return maskedImage;
//}
//
//Mat LaneDetector::crop_region_of_interest(Mat image) {
//
//    /*
//     The code below draws the region of interest into a new image of the same dimensions as the original image.
//     The region of interest is filled with the color we want to filter for in the image.
//     Lastly it combines the two images.
//     The result is only the color within the region of interest.
//     */
//
//    int maxX = image.rows;
//    int maxY = image.cols;
//
//    Point shape[1][5];
//    shape[0][0] = Point(0, maxX);
//    shape[0][1] = Point(maxY, maxX);
//    shape[0][2] = Point((int)(0.55 * maxY), (int)(0.6 * maxX));
//    shape[0][3] = Point((int)(0.45 * maxY), (int)(0.6 * maxX));
//    shape[0][4] = Point(0, maxX);
//
//    Scalar color_to_filter(255, 255, 255);
//
//    Mat filledPolygon = Mat::zeros(image.rows, image.cols, CV_8UC3); // empty image with same dimensions as original
//    const Point* polygonPoints[1] = { shape[0] };
//    int numberOfPoints[] = { 5 };
//    int numberOfPolygons = 1;
//    fillPoly(filledPolygon, polygonPoints, numberOfPoints, numberOfPolygons, color_to_filter);
//
//    // Cobine images into one
//    Mat maskedImage;
//    bitwise_and(image, filledPolygon, maskedImage);
//
//    return maskedImage;
//}
//
//Mat LaneDetector::draw_lines(Mat image, vector<Vec4i> lines) {
//
//    vector<double> rightSlope, leftSlope, rightIntercept, leftIntercept;
//
//    for (int i=0; i<lines.size(); i++) {
//        Vec4i line = lines[i];
//        double x1 = line[0];
//        double y1 = line[1];
//        double x2 = line[2];
//        double y2 = line[3];
//
//        double yDiff = y1-y2;
//        double xDiff = x1-x2;
//        double slope = yDiff/xDiff;
//        double yIntecept = y2 - (slope*x2);
//
//        if ((slope > 0.3) && (x1 > 500)) {
//            rightSlope.push_back(slope);
//            rightIntercept.push_back(yIntecept);
//        } else if ((slope < -0.3) && (x1 < 600)) {
//            leftSlope.push_back(slope);
//            leftIntercept.push_back(yIntecept);
//        }
//    }
//
//    double leftAvgSlope = getAverage(leftSlope, 30);
//    double leftAvgIntercept = getAverage(leftIntercept, 30);
//    double rightAvgSlope = getAverage(rightSlope, 30);
//    double rightAvgIntercept = getAverage(rightIntercept, 30);
//
//    int leftLineX1 = int(((0.65*image.rows) - leftAvgIntercept)/leftAvgSlope);
//    int leftLineX2 = int((image.rows - leftAvgIntercept)/leftAvgSlope);
//    int rightLineX1 = int(((0.65*image.rows) - rightAvgIntercept)/rightAvgSlope);
//    int rightLineX2 = int((image.rows - rightAvgIntercept)/rightAvgSlope);
//
//    Point shape[1][4];
//    shape[0][0] = Point(leftLineX1, int(0.65*image.rows));
//    shape[0][1] = Point(leftLineX2, int(image.rows));
//    shape[0][2] = Point(rightLineX2, int(image.rows));
//    shape[0][3] = Point(rightLineX1, int(0.65*image.rows));
//
//    const Point* polygonPoints[1] = { shape[0] };
//    int numberOfPoints[] = { 4 };
//    int numberOfPolygons = 1;
//    Scalar fillColor(0, 0, 255);
//    fillPoly(image, polygonPoints, numberOfPoints, numberOfPolygons, fillColor);
//
//    Scalar rightColor(0,255,0);
//    Scalar leftColor(255,0,0);
//    line(image, shape[0][0], shape[0][1], leftColor, 10);
//    line(image, shape[0][3], shape[0][2], rightColor, 10);
//
//    return image;
//}
//
//Mat LaneDetector::detect_edges(Mat image) {
//
//    Mat greyScaledImage;
//    cvtColor(image, greyScaledImage, CV_RGB2GRAY);
//
//    Mat edgedOnlyImage;
//    Canny(greyScaledImage, edgedOnlyImage, 50, 120);
//
//    return edgedOnlyImage;
//}
