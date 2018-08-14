//
//  ViewController.swift
//  front-back-cameras
//
//  Created by Ievgen Gavrysh on 8/13/18.
//  Copyright © 2018 Ievgen Gavrysh. All rights reserved.
//

import UIKit

import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet var cameraImageView: UIImageView!

    
    var internals: [[String: AnyObject?]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        
        for device in devices {
            switch device.position {
            case .back:
                self.internals.append(
                    setupCamera(
                        for: device,
                        withFrame: CGRect.init(
                            x: 0,
                            y: 0,
                            width: 100,
                            height: 100
                        )
                    )
                )
                
            case .front:
                self.internals.append(
                    setupCamera(
                        for: device,
                        withFrame: CGRect.init(
                            x: 100,
                            y: 0,
                            width: 100,
                            height: 100
                        )
                    )
                )
                
            default: break
            }
        }
        
    }

    func setupCamera(for device: AVCaptureDevice, withFrame frame: CGRect)
        -> [String: AnyObject?]
    {
        var input: AVCaptureDeviceInput?
        var output: AVCaptureVideoDataOutput?
        var captureSession: AVCaptureSession?
        var previewLayer: AVCaptureVideoPreviewLayer?
        
      
        input = try? AVCaptureDeviceInput.init(device: device)
        var outputInt = AVCaptureVideoDataOutput.init()
        outputInt.alwaysDiscardsLateVideoFrames = true
        
        output = outputInt
        
        
        if let output = output {
            output.setSampleBufferDelegate(
                self,
                queue: DispatchQueue.init(label: "cameraQueue")
            )
            
            var videoSettings
                = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
            output.videoSettings = videoSettings
        }
        
        if let input = input,
            let output = output
        {
            let captureSessionInt = AVCaptureSession.init()
            captureSessionInt.addInput(input)
            captureSessionInt.addOutput(output)
            captureSessionInt.canSetSessionPreset(AVCaptureSession.Preset.photo)
            captureSession = captureSessionInt
        }
        
        if let captureSession = captureSession {
            var previewLayerInt =  AVCaptureVideoPreviewLayer.init(session: captureSession)
            previewLayerInt.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayerInt.frame = frame
            previewLayerInt.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            
            self.view.layer.insertSublayer(previewLayerInt, at: 0)
            
            previewLayer = previewLayerInt
        }
        
        captureSession?.startRunning()
        
        return [
            "device": device,
            "captureSession": captureSession,
            "previewLayer": previewLayer
        ]
    }
}

