import UIKit

class ViewController: UIViewController {

    private var canvasView: DrawingCanvasView!
    private let captureButton = UIButton(type: .system)
    private var capturedImage: UIImage?
    private let momentsSelector = UISegmentedControl(items: ["Momentos de HU", "Momentos de Zernike"])
    private let clearCanvasButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        canvasView = DrawingCanvasView()
        canvasView.backgroundColor = .white
        canvasView.layer.borderWidth = 1.0
        canvasView.layer.borderColor = UIColor.lightGray.cgColor
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)

        captureButton.setTitle("Capturar", for: .normal)
        captureButton.addTarget(self, action: #selector(captureDrawing), for: .touchUpInside)
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(captureButton)

        momentsSelector.selectedSegmentIndex = 0
        momentsSelector.translatesAutoresizingMaskIntoConstraints = false
        momentsSelector.backgroundColor = .white
        momentsSelector.layer.borderWidth = 1
        momentsSelector.layer.borderColor = UIColor.lightGray.cgColor
        view.addSubview(momentsSelector)

        clearCanvasButton.setTitle("Limpiar Lienzo", for: .normal)
        clearCanvasButton.addTarget(self, action: #selector(clearCanvas), for: .touchUpInside)
        clearCanvasButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(clearCanvasButton)

        // Layout
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            canvasView.heightAnchor.constraint(equalTo: canvasView.widthAnchor),

            captureButton.topAnchor.constraint(equalTo: canvasView.bottomAnchor, constant: 20),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            momentsSelector.topAnchor.constraint(equalTo: captureButton.bottomAnchor, constant: 20),
            momentsSelector.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            momentsSelector.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            momentsSelector.heightAnchor.constraint(equalToConstant: 40),

            clearCanvasButton.topAnchor.constraint(equalTo: momentsSelector.bottomAnchor, constant: 20),
            clearCanvasButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func predictHug() {
        capturedImage = canvasView.getCanvasImage()
        
        let csvPath = Bundle.main.path(forResource: "momentos", ofType: "csv")!

        let categoria = ImageProcessor.classifyImage(capturedImage, withCSV: csvPath)
        
        let alert = UIAlertController(title: "Clasificación", message: "La imagen es un \(categoria)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func predictZernike() {
        let csvPath = Bundle.main.path(forResource: "momentos_zernike", ofType: "csv")!
        
        let bridge = ZernikeBridge()
        let prediction = bridge.predict(with: capturedImage!, csvPath: csvPath)

        let alert = UIAlertController(title: "Predicción", message: "La imagen pertenece a la categoría: \(prediction)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true)
    }

    @objc private func captureDrawing() {
        if (momentsSelector.selectedSegmentIndex == 0) {
            predictHug()
        } else {
            predictZernike()
        }
    }

    @objc private func clearCanvas() {
        canvasView.clearCanvas()
    }
}

class DrawingCanvasView: UIView {

    private var lines: [Line] = []
    private var currentLine: Line?

    struct Line {
        var points: [CGPoint]
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        currentLine = Line(points: [touch.location(in: self)])
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, var line = currentLine else { return }
        line.points.append(touch.location(in: self))
        currentLine = line
        lines.append(line)
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(5.0)
        context.setLineCap(.round)

        for line in lines {
            guard let firstPoint = line.points.first else { continue }
            context.beginPath()
            context.move(to: firstPoint)

            for point in line.points.dropFirst() {
                context.addLine(to: point)
            }
            context.strokePath()
        }
    }

    func getCanvasImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    func clearCanvas() {
        lines.removeAll()
        setNeedsDisplay()
    }
}
