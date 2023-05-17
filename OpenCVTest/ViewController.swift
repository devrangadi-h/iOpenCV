//
//  ViewController.swift
//  OpenCVTest
//
//  Created by Hardik Devrangadi on 5/3/23.
//

import UIKit
import AVFoundation

extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    private var cameraSwitchButton: UIButton!
//    private var saveButton: UIButton!
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var captureSession: AVCaptureSession = AVCaptureSession()
    private func getFrames() {
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing.queue"))
        self.captureSession.addOutput(videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
              connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }
    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .back).devices.first else {
            fatalError("No back camera device found, please make sure to run SimpleLaneDetection in an iOS device and not a simulator")
        }
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
            guard let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)
            let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
            bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
            let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
            guard let quartzImage = context?.makeImage() else { return }
            CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags.readOnly)
            let image = UIImage(cgImage: quartzImage)
            let imageWithLaneOverlay = LaneDetectorBridge().detectLane(in: image)
            DispatchQueue.main.async {
                self.imageView.image = imageWithLaneOverlay
            }
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.addCameraInput()
        self.getFrames()
        self.captureSession.startRunning()
        
        // Set imageView to fill the screen
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        //        cameraSwitchButton = UIButton(type: .system)
        //        cameraSwitchButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        //        cameraSwitchButton.addTarget(self, action: #selector(switchCameraButtonTapped), for: .touchUpInside)
        //        cameraSwitchButton.translatesAutoresizingMaskIntoConstraints = false
        //        view.addSubview(cameraSwitchButton)
        //
        //        NSLayoutConstraint.activate([
        //            cameraSwitchButton.widthAnchor.constraint(equalToConstant: 100),
        //            cameraSwitchButton.heightAnchor.constraint(equalToConstant: 100),
        //            cameraSwitchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
        //            cameraSwitchButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
        //        ])
        
        cameraSwitchButton = UIButton(type: .system)
        let imageSize = CGSize(width: 57.6, height: 45.6)
        let buttonImage = UIImage(systemName: "camera.rotate")?.resize(to: imageSize)
        cameraSwitchButton.setImage(buttonImage, for: .normal)
        cameraSwitchButton.addTarget(self, action: #selector(switchCameraButtonTapped), for: .touchUpInside)
        cameraSwitchButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraSwitchButton)
        
        // Set the size of the button
        cameraSwitchButton.widthAnchor.constraint(equalToConstant: imageSize.width).isActive = true
        cameraSwitchButton.heightAnchor.constraint(equalToConstant: imageSize.height).isActive = true
        cameraSwitchButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        cameraSwitchButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20).isActive = true
        
        let captureButton = UIButton(type: .system)
        let imageSizeCapture = CGSize(width: 57.6, height: 57.6)
        captureButton.setImage(UIImage(systemName: "camera.circle.fill")?.resize(to: imageSizeCapture), for: .normal)
            captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
            captureButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(captureButton)

            // Position the capture button in the bottom middle of the screen
//            NSLayoutConstraint.activate([
//                captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//                captureButton.widthAnchor.constraint(equalToConstant: 64),
//                captureButton.heightAnchor.constraint(equalToConstant: 64),
//                captureButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
//            ])
        captureButton.widthAnchor.constraint(equalToConstant: imageSizeCapture.width).isActive = true
        captureButton.heightAnchor.constraint(equalToConstant: imageSizeCapture.height).isActive = true
        captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        captureButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true

        
    }
    
    
    
    @objc private func switchCameraButtonTapped() {
        // Find the current active camera position
        guard let currentCameraInput = captureSession.inputs.first as? AVCaptureDeviceInput else {
            return
        }
        
        // Determine the desired camera position to switch to
        let currentPosition = currentCameraInput.device.position
        
        // Determine the desired camera position to switch to
        let desiredPosition: AVCaptureDevice.Position = (currentPosition == .front) ? .back : .front
        
        // Find the desired camera device based on the position
        guard let desiredCamera = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: desiredPosition
        ).devices.first else {
            return
        }
        
        // Create a new camera input using the desired camera device
        do {
            let newCameraInput = try AVCaptureDeviceInput(device: desiredCamera)
            
            // Remove the existing camera input from the capture session
            captureSession.removeInput(currentCameraInput)
            
            // Add the new camera input to the capture session
            captureSession.addInput(newCameraInput)
            
            // Update the video orientation based on the new camera position
            guard let connection = videoDataOutput.connection(with: .video) else {
                return
            }
            
            //            if connection.isVideoOrientationSupported {
            //                connection.videoOrientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue) ?? .portrait
            //            }
            
            if connection.isVideoOrientationSupported {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    let interfaceOrientation = windowScene.interfaceOrientation
                    connection.videoOrientation = AVCaptureVideoOrientation(rawValue: interfaceOrientation.rawValue) ?? .portrait
                }
            }
            
            // Start the capture session
            captureSession.startRunning()
            
        } catch {
            print("Failed to create AVCaptureDeviceInput: \(error)")
        }
    }
//    @objc private func captureButtonTapped() {
//        guard let currentImage = imageView.image else {
//            return
//        }
//
//        UIImageWriteToSavedPhotosAlbum(currentImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
//    }
    
    @objc private func captureButtonTapped() {
        guard let currentImage = imageView.image else {
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(currentImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        // Display the message label
        let messageLabel = UILabel()
        messageLabel.text = "Image Saved to Gallery"
        messageLabel.textColor = .white
        messageLabel.backgroundColor = UIColor(white: 0, alpha: 0.7)
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 18)
        messageLabel.layer.cornerRadius = 8
        messageLabel.clipsToBounds = true
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageLabel.widthAnchor.constraint(equalToConstant: 200),
            messageLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Delayed dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
               UIView.animate(withDuration: 0.5, animations: {
                   messageLabel.alpha = 0
               }, completion: { _ in
                   messageLabel.removeFromSuperview()
               })
        }
    }


    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving image: \(error)")
        } else {
            print("Image saved successfully.")
        }
    }


    
}
