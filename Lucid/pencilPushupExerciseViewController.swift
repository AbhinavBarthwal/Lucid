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


import UIKit
import ARKit

class pencilPushupExerciseViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var targetDot: UIView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var leftEyeLabel: UILabel!
    @IBOutlet weak var rightEyeLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!

    private var squintBuffer: [Float] = []
    private let bufferLimit = 20
    private var isExerciseRunning = true

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        setupUI()
    }

    private func setupUI() {
        targetDot?.layer.cornerRadius = 10
        view.bringSubviewToFront(targetDot)
        view.bringSubviewToFront(instructionLabel)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 1. Check if face tracking is supported (requires iPhone X or newer)
        guard ARFaceTrackingConfiguration.isSupported else {
            instructionLabel.text = "Face tracking not supported on this device"
            return
        }

        // 2. Create a face tracking configuration
        let configuration = ARFaceTrackingConfiguration()
        
        // 3. Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session when the screen goes away
        sceneView.session.pause()
    }
    // MARK: - Core Logic: Pupil Asynchrony
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor, isExerciseRunning else { return }

        // 1. Get the LookAt point (Where the eyes are focused in 3D space)
        let lookAt = faceAnchor.lookAtPoint
        
        // 2. Calculate the deviation of the pupils
        // We compare the Left Eye Transform to the Right Eye Transform
        let leftEye = faceAnchor.leftEyeTransform
        let rightEye = faceAnchor.rightEyeTransform
        
        // Physics: Cross-product of gaze vectors to find the 'Parallel Error'
        // This is more accurate than 'rotation' because it accounts for head tilt.
        let leftGazeX = leftEye.columns.2.x
        let rightGazeX = rightEye.columns.2.x
        
        // In a perfect world, for a center target, leftGazeX + rightGazeX ≈ 0
        let pupilAsynchrony = abs(leftGazeX + rightGazeX)

        // 3. Smooth the data to remove "jitter" false positives
        squintBuffer.append(pupilAsynchrony)
        if squintBuffer.count > bufferLimit { squintBuffer.removeFirst() }
        let averageError = squintBuffer.reduce(0, +) / Float(squintBuffer.count)

        // 4. Distance from phone
        let distance = abs(faceAnchor.transform.columns.3.z) * 100

        DispatchQueue.main.async { [weak self] in
            self?.updatePrecisionUI(error: averageError, dist: Float(distance))
        }
    }

    private func updatePrecisionUI(error: Float, dist: Float) {
        // Threshold Tuning:
        // 0.05 - 0.15: Extremely sensitive (May catch natural blinks)
        // 0.20 - 0.28: The "Sweet Spot" for detecting real asynchronous movement.
        let threshold: Float = 0.24

        if error > threshold {
            targetDot.backgroundColor = .blue
            instructionLabel.text = "ASYNC PUPIL DETECTED\nAlign your focus"
        } else if dist < 12 {
            targetDot.backgroundColor = .green
            instructionLabel.text = "PERFECT ALIGNMENT"
            doneButton.isHidden = false
        } else {
            targetDot.backgroundColor = .orange
            instructionLabel.text = "Distance: \(Int(dist))cm"
        }

        // Scale the dot based on distance
        let scale = 15.0 - ((max(10, min(40, CGFloat(dist))) - 10) / 30.0 * 14.0)
        targetDot.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
}
