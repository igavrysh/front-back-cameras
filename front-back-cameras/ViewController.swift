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

    @IBOutlet weak var captureFrontImageView: UIImageView!
    @IBOutlet weak var captureBackImageView: UIImageView!
    
    var internals: [[String: AnyObject?]] = []
    
    var capturedImage: UIImage?
    
    var captureSession: AVCaptureSession?
    
    var input: AVCaptureDeviceInput?
    var output: AVCaptureVideoDataOutput?
    
    enum SessionInput {
        case front
        case back
    }
    
    var state: SessionInput = .front
    
    func reloadState() {
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        
        for device in devices {
            if (device.position == .back && self.state == .back) ||
                (device.position == .front && self.state == .front)
            {
                
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
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        reloadState()
        
        self.setupTimer()
        
    }
    
    func setupTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
            
            DispatchQueue.main.async {
                switch self.state {
                case .back:
                    self.captureBackImageView.image = self.capturedImage
                case .front:
                    self.captureFrontImageView.image = self.capturedImage
                }
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            switch self.state {
            case .back:
                self.state = .front
            case .front:
                self.state = .back
            }
            
            self.reloadState()
        }
    }

    func setupCamera(for device: AVCaptureDevice, withFrame frame: CGRect)
        -> [String: AnyObject?]
    {
        self.internals = []
        
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        self.input = try? AVCaptureDeviceInput.init(device: device)
    
        if let input = self.input
        {
            let captureSessionInt: AVCaptureSession!
            if self.captureSession == nil {
                captureSessionInt = AVCaptureSession.init()
                self.captureSession = captureSessionInt
                if captureSessionInt.canSetSessionPreset(AVCaptureSession.Preset.photo) {
                    captureSessionInt.sessionPreset = AVCaptureSession.Preset.photo
                }
            } else {
                captureSessionInt = self.captureSession!
                for i : AVCaptureDeviceInput in (captureSessionInt.inputs as! [AVCaptureDeviceInput]){
                    self.captureSession?.removeInput(i)
                }
                
                self.input = nil
                
                for i : AVCaptureOutput in (captureSessionInt.outputs as! [AVCaptureOutput]){
                    self.captureSession?.removeOutput(i)
                }
                
                self.output = nil
            }
            
            if captureSessionInt.canAddInput(input) {
                captureSessionInt.addInput(input)
            }
            
            var outputInt = AVCaptureVideoDataOutput.init()
            outputInt.alwaysDiscardsLateVideoFrames = true
            
            self.output = outputInt
            
            if let output = self.output {
                output.setSampleBufferDelegate(
                    self,
                    queue: DispatchQueue.init(label: "cameraQueue")
                )
                
                var videoSettings
                    = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
                output.videoSettings = videoSettings
                
                if captureSessionInt.canAddOutput(output) {
                    captureSessionInt.addOutput(output)
                }
            }
            
        }
        
        if let captureSession = captureSession {
            var previewLayerInt: AVCaptureVideoPreviewLayer!
            if let previewLayer = self.previewLayer {
                previewLayerInt = previewLayer
                previewLayerInt.session = captureSession
            } else {
                previewLayerInt = AVCaptureVideoPreviewLayer.init(session: captureSession)
                self.previewLayer = previewLayerInt
            }
    
            previewLayerInt.videoGravity = AVLayerVideoGravity.resizeAspectFill
            previewLayerInt.frame = frame
            previewLayerInt.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            
            self.view.layer.addSublayer(previewLayerInt)
            
            previewLayer = previewLayerInt
        }
        
        DispatchQueue.main.async {
            self.captureSession?.startRunning()
        }
        
        return [
            "device": device,
            "captureSession": captureSession,
            "previewLayer": previewLayer
        ]
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)  {
        let myPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let myCIimage = CIImage(cvPixelBuffer: myPixelBuffer!)
        let videoImage = UIImage(ciImage: myCIimage)
        self.capturedImage = videoImage
    }
    
    @IBAction func onSwitchTouched(_ sender: Any) {
        switch self.state {
        case .back:
            self.state = .front
        case .front:
            self.state = .back
        }
        
        self.reloadState()
    }
    
    
}

