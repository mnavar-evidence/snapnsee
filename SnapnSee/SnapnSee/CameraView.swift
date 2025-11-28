import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        picker.showsCameraControls = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.capturedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Custom Camera View with live preview and capture button
struct CustomCameraView: View {
    @Binding var capturedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var camera = CameraModel()

    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .ignoresSafeArea()

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    // Capture button
                    Button(action: {
                        camera.capturePhoto { image in
                            capturedImage = image
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 60, height: 60)
                            )
                    }

                    Spacer()
                }
                .padding(.bottom, 40)
            }

            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()

                    Spacer()
                }

                Spacer()
            }
        }
        .onAppear {
            camera.checkPermissions()
        }
    }
}

// Camera Preview using AVFoundation
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)

        // Start session on background thread to avoid UI hang
        DispatchQueue.global(qos: .userInitiated).async {
            camera.session.startRunning()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        // Stop session on background thread when view is removed
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer,
           let session = layer.session {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }
}

// Camera Model for managing AVFoundation
class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var alert = false
    var preview: AVCaptureVideoPreviewLayer!
    var output = AVCapturePhotoOutput()
    var photoCompletion: ((UIImage?) -> Void)?

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.setUp()
                    }
                }
            }
        default:
            alert = true
        }
    }

    func setUp() {
        do {
            session.beginConfiguration()

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                return
            }

            let input = try AVCaptureDeviceInput(device: device)

            if session.canAddInput(input) {
                session.addInput(input)
            }

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            session.commitConfiguration()
        } catch {
            print(error.localizedDescription)
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCompletion = completion
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            photoCompletion?(nil)
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoCompletion?(nil)
            return
        }

        photoCompletion?(image)
    }
}
