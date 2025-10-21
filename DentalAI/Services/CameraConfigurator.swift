import AVFoundation
import Foundation

final class CameraConfigurator {
    let session = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?

    func configureRearPhoto() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // Use the safest device: built-in wide-angle back camera
        let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        guard let device else { throw NSError(domain: "Camera", code: 1) }

        // Avoid "Portrait mode" requests; use standard photo preset
        if session.canSetSessionPreset(.photo) { session.sessionPreset = .photo }

        // Clean inputs
        for input in session.inputs { session.removeInput(input) }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw NSError(domain: "Camera", code: 2) }
        session.addInput(input)

        // Photo output
        let photoOutput = AVCapturePhotoOutput()
        // Don't enable portrait effects matte or depth unless supported
        photoOutput.isHighResolutionCaptureEnabled = true
        if #available(iOS 17, *) {
            // Leave portrait effects off unless you detect support
            // photoOutput.isPortraitEffectsMatteDeliveryEnabled = false
        }

        for output in session.outputs { session.removeOutput(output) }
        guard session.canAddOutput(photoOutput) else { throw NSError(domain: "Camera", code: 3) }
        session.addOutput(photoOutput)

        videoDevice = device
    }
}
