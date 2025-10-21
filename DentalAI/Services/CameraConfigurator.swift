import AVFoundation

final class CameraConfigurator {
    let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()

    func configureRearPhoto() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        // Device: safest default (no dual/portrait)
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw NSError(domain: "Camera", code: 1, userInfo: [NSLocalizedDescriptionKey: "Back camera unavailable"])
        }

        // Preset: .photo (don't force "portrait" anything)
        if session.canSetSessionPreset(.photo) { session.sessionPreset = .photo }

        // Reset inputs/outputs
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        // Input
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw NSError(domain: "Camera", code: 2) }
        session.addInput(input)

        // Output
        #if swift(>=5.7)
        // iOS 16+: DO NOT use isHighResolutionCaptureEnabled (deprecated).
        // We simply add the output; .photo preset yields full-res where possible.
        #else
        photoOutput.isHighResolutionCaptureEnabled = true
        #endif

        // Explicitly disable portrait effects & depth unless verified supported
        if photoOutput.isPortraitEffectsMatteDeliveryEnabled {
            photoOutput.isPortraitEffectsMatteDeliveryEnabled = false
        }
        if photoOutput.isDepthDataDeliveryEnabled {
            photoOutput.isDepthDataDeliveryEnabled = false
        }

        guard session.canAddOutput(photoOutput) else { throw NSError(domain: "Camera", code: 3) }
        session.addOutput(photoOutput)
    }
}
