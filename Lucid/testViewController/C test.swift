
import UIKit
import ARKit

class PencilPushupExerciseViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var targetDot: UIView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var leftEyeLabel: UILabel!
    @IBOutlet weak var rightEyeLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!


    private var squintBuffer: [Float] = []
    private let bufferLimit = 8
    private var isExerciseRunning = true

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking])
    }

    private func setupUI() {
        targetDot.layer.cornerRadius = targetDot.frame.width / 2
        doneButton.isHidden = true
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor, isExerciseRunning else { return }

        let leftGazeX = faceAnchor.leftEyeTransform.columns.2.x
        let rightGazeX = faceAnchor.rightEyeTransform.columns.2.x
        
        let leftDeg = Float(leftGazeX * 90.0)
        let rightDeg = Float(rightGazeX * 90.0)
        
    
        let currentError = abs(leftGazeX + rightGazeX)

        squintBuffer.append(currentError)
        if squintBuffer.count > bufferLimit { squintBuffer.removeFirst() }
        let averageError = squintBuffer.reduce(0, +) / Float(squintBuffer.count)

        let distance = abs(faceAnchor.transform.columns.3.z) * 100

        DispatchQueue.main.async { [weak self] in
            self?.processEyeState(error: averageError, leftDeg: leftDeg, rightDeg: rightDeg, dist: Float(distance))
        }
    }

    private func processEyeState(error: Float, leftDeg: Float, rightDeg: Float, dist: Float) {

        leftEyeLabel.text = String(format: "L: %.1f°", abs(leftDeg))
        rightEyeLabel.text = String(format: "R: %.1f°", abs(rightDeg))
        
        let lDir = leftDeg > 0 ? "Inward" : "Outward"
        let rDir = rightDeg < 0 ? "Inward" : "Outward"
        print("L: \(abs(leftDeg))° \(lDir) | R: \(abs(rightDeg))° \(rDir) | Err: \(error)")

        let threshold: Float = 0.26

        if error > threshold {
            targetDot.backgroundColor = .systemBlue
            instructionLabel.text = "SQUINT DETECTED \n Keep eyes focused"
            doneButton.isHidden = true
        }

        else if dist <= 15 {
            targetDot.backgroundColor = .systemGreen
            instructionLabel.text = "CORRECT ALIGNMENT"
            doneButton.isHidden = false
        }

        else {
            targetDot.backgroundColor = .accent
            instructionLabel.text = "Move closer: \(Int(dist))cm"
            doneButton.isHidden = true
        }


        let scaleFactor = 1.0 + (max(0, 40.0 - CGFloat(dist)) / 12.0)
        UIView.animate(withDuration: 0.1) {
            self.targetDot.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        }
    }

    @IBAction func doneTapped(_ sender: UIButton) {
        isExerciseRunning = false
        self.dismiss(animated: true)
    }
}
