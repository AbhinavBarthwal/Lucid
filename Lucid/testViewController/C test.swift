//import UIKit
//import ARKit
//
//class pencilPushupExerciseViewController: UIViewController, ARSCNViewDelegate {
//
//    // MARK: - Outlets
//    @IBOutlet weak var sceneView: ARSCNView!
//    @IBOutlet weak var targetDot: UIView!
//    @IBOutlet weak var instructionLabel: UILabel!
//    @IBOutlet weak var leftEyeLabel: UILabel!
//    @IBOutlet weak var rightEyeLabel: UILabel!
//    @IBOutlet weak var doneButton: UIButton!
//
//    // MARK: - Properties
//    private enum ExerciseState { case active, finished }
//    private var currentState: ExerciseState = .active
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        // Safety check for AR support
//        guard ARFaceTrackingConfiguration.isSupported else {
//            instructionLabel?.text = "Face Tracking Not Supported on this device."
//            return
//        }
//        
//        sceneView.delegate = self
//        sceneView.scene.background.contents = UIColor.black
//        setupUI()
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        resetARSession()
//    }
//
//    private func setupUI() {
//        // Ensure UI elements exist before styling
//        targetDot?.layer.cornerRadius = 10
//        targetDot?.backgroundColor = .orange
//        doneButton?.isHidden = true
//        
//        [instructionLabel, leftEyeLabel, rightEyeLabel].forEach {
//            $0?.numberOfLines = 0
//            $0?.textAlignment = .center
//        }
//    }
//
//    private func resetARSession() {
//        let configuration = ARFaceTrackingConfiguration()
//        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
//    }
//
//    // MARK: - ARSCNViewDelegate
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let faceAnchor = anchor as? ARFaceAnchor, currentState == .active else { return }
//        
//        // 1. Precise Squint Math (Physics Vectors)
//        let lIn = faceAnchor.blendShapes[.eyeLookInLeft]?.floatValue ?? 0
//        let lOut = faceAnchor.blendShapes[.eyeLookOutLeft]?.floatValue ?? 0
//        let rIn = faceAnchor.blendShapes[.eyeLookInRight]?.floatValue ?? 0
//        let rOut = faceAnchor.blendShapes[.eyeLookOutRight]?.floatValue ?? 0
//        
//        // Index = |(L_In - L_Out) - (R_In - R_Out)|
//        let asymmetry = abs((lIn - lOut) - (rIn - rOut))
//        let distanceCm = abs(faceAnchor.transform.columns.3.z) * 100
//        
//        // 2. Project 3D Eye Position to 2D Screen Coordinates
//        let leftProj = projectEye(faceAnchor: faceAnchor, isLeft: true)
//        let rightProj = projectEye(faceAnchor: faceAnchor, isLeft: false)
//
//        DispatchQueue.main.async { [weak self] in
//            self?.updateExerciseUI(asymmetry: asymmetry, dist: Float(distanceCm), leftXY: leftProj, rightXY: rightProj)
//        }
//    }
//
//    private func updateExerciseUI(asymmetry: Float, dist: Float, leftXY: String, rightXY: String) {
//        // Update labels only if they are connected
//        leftEyeLabel?.text = "Left Eye\n\(leftXY)"
//        rightEyeLabel?.text = "Right Eye\n\(rightXY)"
//        
//        // 1. SCALING LOGIC
//        let clampedDist = max(10, min(40, CGFloat(dist)))
//        let percentage = (clampedDist - 10) / 30
//        let scaleValue = 15.0 - (percentage * 14.0)
//        
//        targetDot?.transform = CGAffineTransform(scaleX: scaleValue, y: scaleValue)
//
//        // 2. SQUINT & COLOR LOGIC
//        if asymmetry > 0.25 {
//            targetDot?.backgroundColor = .blue
//            instructionLabel?.text = "SQUINT DETECTED\nError Index: \(String(format: "%.2f", asymmetry))"
//            doneButton?.isHidden = false
//        } else if dist < 12 {
//            targetDot?.backgroundColor = .green
//            instructionLabel?.text = "TARGET REACHED!\nExcellent Alignment"
//            doneButton?.isHidden = false
//        } else {
//            targetDot?.backgroundColor = .orange
//            instructionLabel?.text = "Move phone closer\nDistance: \(Int(dist))cm"
//        }
//    }
//
//    private func projectEye(faceAnchor: ARFaceAnchor, isLeft: Bool) -> String {
//        let eyeTransform = isLeft ? faceAnchor.leftEyeTransform : faceAnchor.rightEyeTransform
//        let position = eyeTransform.columns.3
//        let projected = sceneView.projectPoint(SCNVector3(position.x, position.y, position.z))
//        return "X: \(Int(projected.x)), Y: \(Int(projected.y))"
//    }
//
//    // MARK: - Actions
//    @IBAction func doneButtonTapped(_ sender: UIButton) {
//        currentState = .finished
//        targetDot?.transform = .identity
//        instructionLabel?.text = "Exercise Finished."
//    }
//}
//
//
//
//import UIKit
//import ARKit
//
//class PencilPushupExerciseViewController: UIViewController, ARSCNViewDelegate {
//
//    // MARK: - Outlets
//    @IBOutlet weak var sceneView: ARSCNView!
//    @IBOutlet weak var targetDot: UIView!
//    @IBOutlet weak var instructionLabel: UILabel!
//    @IBOutlet weak var leftEyeLabel: UILabel!
//    @IBOutlet weak var rightEyeLabel: UILabel!
//    @IBOutlet weak var doneButton: UIButton!
//
//    // MARK: - Properties
//    private var squintBuffer: [Float] = []
//    private let bufferLimit = 15
//    private var isExerciseRunning = true
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        sceneView.delegate = self
//        setupUI()
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        // 1. Initialize Face Tracking
//        guard ARFaceTrackingConfiguration.isSupported else {
//            instructionLabel.text = "TrueDepth Camera Required"
//            return
//        }
//        
//        let configuration = ARFaceTrackingConfiguration()
//        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        sceneView.session.pause()
//    }
//
//    private func setupUI() {
//        targetDot.layer.cornerRadius = targetDot.frame.width / 2
//        targetDot.backgroundColor = .systemOrange
//        
//        // Ensure UI elements are visible over AR feed
//        view.bringSubviewToFront(targetDot)
//        view.bringSubviewToFront(instructionLabel)
//        view.bringSubviewToFront(leftEyeLabel)
//        view.bringSubviewToFront(rightEyeLabel)
//        
//        doneButton.isHidden = true
//    }
//
//    // MARK: - ARSCNViewDelegate
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let faceAnchor = anchor as? ARFaceAnchor, isExerciseRunning else { return }
//
//        // 1. Extract Horizontal Gaze Vectors
//        let leftGazeX = faceAnchor.leftEyeTransform.columns.2.x
//        let rightGazeX = faceAnchor.rightEyeTransform.columns.2.x
//        
//        // 2. Convert Vectors to Degrees (1.0 ≈ 90°)
//        let leftDeg = Float(leftGazeX * 90.0)
//        let rightDeg = Float(rightGazeX * 90.0)
//        
//        // 3. Coordination Calculation
//        // Healthy convergence: Left Eye looks Right (+), Right Eye looks Left (-)
//        // Their sum should be near zero.
//        let convergenceSum = leftGazeX + rightGazeX
//        let currentError = abs(convergenceSum)
//
//        // 4. Smooth Data
//        squintBuffer.append(currentError)
//        if squintBuffer.count > bufferLimit { squintBuffer.removeFirst() }
//        let averageError = squintBuffer.reduce(0, +) / Float(squintBuffer.count)
//
//        // 5. Distance Calculation (cm)
//        let distance = abs(faceAnchor.transform.columns.3.z) * 100
//
//        DispatchQueue.main.async { [weak self] in
//            self?.updateExerciseState(error: averageError,
//                                     leftDeg: leftDeg,
//                                     rightDeg: rightDeg,
//                                     dist: Float(distance))
//        }
//    }
//
//    private func updateExerciseState(error: Float, leftDeg: Float, rightDeg: Float, dist: Float) {
//        // A. Update Labels
//        leftEyeLabel.text = String(format: "Left: %.1f°", abs(leftDeg))
//        rightEyeLabel.text = String(format: "Right: %.1f°", abs(rightDeg))
//
//        // B. Terminal Logging with Direction
//        let lDir = leftDeg > 0 ? "Inward" : "Outward"
//        let rDir = rightDeg < 0 ? "Inward" : "Outward"
//        print("LOG -> L: \(abs(leftDeg))° \(lDir) | R: \(abs(rightDeg))° \(rDir) | Err: \(String(format: "%.3f", error))")
//
//        // C. Fixed Dot Scaling
//        // Scales from 1.0x at 40cm down to 3.5x at 10cm
//        let scaleFactor = 1.0 + (max(0, 40.0 - CGFloat(dist)) / 10.0)
//        targetDot.transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
//
//        // D. Threshold & Feedback
//        // Increased threshold to 0.32 to reduce false positives for non-squint users
//        let threshold: Float = 0.32
//
//        if error > threshold {
//            targetDot.backgroundColor = .systemBlue
//            instructionLabel.text = "SQUINT DETECTED\nRefocus both eyes"
//        } else if dist < 12 {
//            targetDot.backgroundColor = .systemGreen
//            instructionLabel.text = "PERFECT ALIGNMENT"
//            doneButton.isHidden = false
//        } else {
//            targetDot.backgroundColor = .systemOrange
//            instructionLabel.text = "Slowly bring closer: \(Int(dist))cm"
//        }
//    }
//
//    @IBAction func doneTapped(_ sender: UIButton) {
//        isExerciseRunning = false
//        self.dismiss(animated: true)
//    }
//}



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
            targetDot.backgroundColor = .systemOrange
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
