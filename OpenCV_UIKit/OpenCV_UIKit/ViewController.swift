import UIKit
import AVFoundation
import MobileVLCKit

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, VLCMediaPlayerDelegate {
    @IBOutlet weak var switchClahe: UISwitch!
    @IBOutlet weak var btnSubmit: UIButton!
    @IBOutlet weak var processedImageView: UIImageView!
    @IBOutlet weak var segment: UISegmentedControl!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    
    private var captureSession: AVCaptureSession = AVCaptureSession() // Cámara local
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private var mediaPlayer: VLCMediaPlayer? // RTSP
    private var isRTSPActive = false // Controlar si estamos en modo RTSP o cámara local
    private var frameCaptureTimer: Timer? // Timer para capturar frames del RTSP
    private var bridge: FilterApplicatorBridge = FilterApplicatorBridge()
    var referenceMatPointer: UnsafeMutableRawPointer?
    var useClaheFromSwitch: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textField.text = "http://172.20.10.3:81/stream" // URL por defecto
        
        self.switchClahe.addTarget(self, action: #selector(onSwitchValueChanged(_:)), for: .valueChanged)
        
        var imagePaths: [String] = []
        for i in 0...255 {
            if let imagePath = Bundle.main.path(forResource: "img_\(i)", ofType: "jpg") {
                imagePaths.append(imagePath)
            } else {
                print("Imagen img_\(i).jpg no encontrada en el bundle.")
            }
        }

        if let resizedImagesPointer = bridge.loadAndResizeImages(imagePaths, subFrameSize: CGSize(width: 12, height: 12)) {
            referenceMatPointer = resizedImagesPointer
            print("Imágenes redimensionadas y cargadas correctamente.")
        } else {
            print("Error al cargar o redimensionar las imágenes.")
        }
        
        // Configuración inicial de la cámara local
        self.addCameraInput()
        self.getFrames()
        self.captureSession.startRunning()
    }
    
    // MARK: - Configuración de Cámara Local
    private func addCameraInput() {
        guard let device = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
            mediaType: .video,
            position: .back).devices.first else {
                fatalError("No se encontró una cámara trasera, asegúrate de ejecutar este código en un dispositivo físico.")
        }
        
        let cameraInput = try! AVCaptureDeviceInput(device: device)
        self.captureSession.addInput(cameraInput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isRTSPActive else { return } // Ignorar frames si el RTSP está activo
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
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
        
        if let pointer = referenceMatPointer {
            let imageWithFilterApplied = bridge.apply_filter(image, useClahe: useClaheFromSwitch ? 1 : 0, withReferenceMat: pointer)
            
            DispatchQueue.main.async {
                self.imageView.image = imageWithFilterApplied
                self.processedImageView.image = imageWithFilterApplied
            }
        } else {
            print("Error al obtener el puntero de imagenes.")
            
            let imageWithFilterApplied = bridge.apply_filter(image)
            
            DispatchQueue.main.async {
                self.imageView.image = imageWithFilterApplied
                self.processedImageView.image = imageWithFilterApplied
            }
        }
    }
    
    private func getFrames() {
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_32BGRA)] as [String: Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing.queue"))
        
        self.captureSession.addOutput(videoDataOutput)
        guard let connection = self.videoDataOutput.connection(with: AVMediaType.video),
              connection.isVideoOrientationSupported else { return }
        
        connection.videoOrientation = .portrait
    }
    
    // MARK: - Configuración de RTSP
    private func setupRTSPStream() {
        guard let urlString = textField.text, !urlString.isEmpty, let url = URL(string: urlString) else {
            print("URL inválida")
            return
        }

        // Detener la sesión de la cámara si está activa
        if captureSession.isRunning {
            captureSession.stopRunning()
        }

        // Configurar VLCMediaPlayer
        mediaPlayer = VLCMediaPlayer()
        mediaPlayer?.delegate = self
        mediaPlayer?.drawable = imageView // Asignar el video RTSP al `rawImageView`
        mediaPlayer?.media = VLCMedia(url: url)

        // Iniciar captura de frames para procesarlos
        startFrameProcessing()

        mediaPlayer?.play()
        isRTSPActive = true
    }
    
    private func startFrameProcessing() {
        // Detener cualquier procesamiento previo
        stopFrameCapture()

        // Configurar un temporizador para capturar el contenido del `rawImageView`
        frameCaptureTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Capturar el frame actual desde `rawImageView`
            UIGraphicsBeginImageContextWithOptions(self.imageView.bounds.size, false, 0.0)
            self.imageView.drawHierarchy(in: self.imageView.bounds, afterScreenUpdates: false)
            let capturedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            // Procesar el frame capturado
            if let capturedImage = capturedImage {
                self.processCapturedFrame(capturedImage)
            }
        }
    }

    private func processCapturedFrame(_ image: UIImage) {
        // Verificar que las dimensiones del frame sean válidas
        guard let cgImage = image.cgImage else {
            print("Frame inválido: no se pudo obtener cgImage")
            return
        }

        let width = cgImage.width
        let height = cgImage.height

        // Establecer un tamaño mínimo válido
        guard width > 10, height > 10 else {
            print("Frame ignorado: dimensiones inválidas (\(width)x\(height))")
            return
        }
        
        if let pointer = referenceMatPointer {
            guard let imageWithFilterApplied = bridge.apply_filter(image, useClahe: useClaheFromSwitch ? 1 : 0, withReferenceMat: pointer) else {
                print("Error al procesar la imagen con OpenCV")
                return
            }

            // Mostrar el frame procesado en `processedImageView`
            DispatchQueue.main.async {
                self.processedImageView.image = imageWithFilterApplied
            }
        } else {
            print("Error al obtener el puntero de imagenes.")
            
            guard let imageWithFilterApplied = bridge.apply_filter(image) else {
                print("Error al procesar la imagen con OpenCV")
                return
            }

            // Mostrar el frame procesado en `processedImageView`
            DispatchQueue.main.async {
                self.processedImageView.image = imageWithFilterApplied
            }
        }
    }
    
    private func createCGImageFromBuffer(frame: UnsafeMutableRawPointer, width: Int, height: Int) -> CGImage? {
        // Configurar el contexto de datos
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        let dataProvider = CGDataProvider(dataInfo: nil, data: frame, size: width * height * 4, releaseData: { _, _, _ in })!
        
        return CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo,
            provider: dataProvider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
    
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        guard let mediaPlayer = mediaPlayer else { return }
        
        switch mediaPlayer.state {
        case .playing:
            print("RTSP en reproducción")
        case .error:
            print("Error al reproducir la transmisión RTSP")
        default:
            break
        }
    }
    
    private func startFrameCapture() {
        // Detener cualquier temporizador previo
        stopFrameCapture()

        // Configurar un temporizador para capturar el contenido del UIImageView asociado al video
        frameCaptureTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Capturar el contenido actual del UIImageView
            UIGraphicsBeginImageContextWithOptions(self.imageView.bounds.size, false, 0.0)
            self.imageView.drawHierarchy(in: self.imageView.bounds, afterScreenUpdates: false)
            let capturedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            // Procesar el frame capturado
            if let capturedImage = capturedImage {
                self.processCapturedFrame(capturedImage)
            }
        }
    }

    
    private func stopFrameCapture() {
        frameCaptureTimer?.invalidate()
        frameCaptureTimer = nil
    }
    
    private func stopRTSPIfNeeded() {
        if isRTSPActive, let mediaPlayer = mediaPlayer {
            mediaPlayer.stop()
            stopFrameCapture() // Detiene la captura de frames
            isRTSPActive = false
        }
    }
    
    // MARK: - Acciones de Usuario
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        textField.resignFirstResponder()
        
        guard let text = textField.text else { return }
        updateSegmentSelection(with: text)
        
        if segment.selectedSegmentIndex == 1 { // RTSP
            setupRTSPStream()
        } else { // Cámara local
            stopRTSPIfNeeded()
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }
    
    @IBAction func segmentValueChanged(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        
        switch selectedIndex {
        case 0: // Cámara local
            stopRTSPIfNeeded()
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
            print("Cámara local activada")
        case 1: // RTSP
            setupRTSPStream()
            print("Transmisión RTSP activada")
        default:
            print("Opción desconocida")
        }
    }
    
    private func updateSegmentSelection(with text: String) {
        if text.lowercased() == "none" {
            segment.selectedSegmentIndex = 0
        } else {
            segment.selectedSegmentIndex = 1
        }
    }
    
    @objc private func onSwitchValueChanged(_ switch: UISwitch) {
        if (switchClahe.isOn) {
            useClaheFromSwitch = true
        } else {
            useClaheFromSwitch = false
        }
    }
}
