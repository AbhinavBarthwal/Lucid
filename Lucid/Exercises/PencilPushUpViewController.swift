import UIKit
import ARKit

class PencilPushUpViewController: UIViewController, ARSessionDelegate {

    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var centerMessageLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!


    private let arSession = ARSession()
    private let hapticGenerator = UINotificationFeedbackGenerator()
    private let successHapticGenerator = UINotificationFeedbackGenerator()
    
    private enum ExercisePhase {
        case none, bringingCloser, movingBack
    }
    private var currentPhase: ExercisePhase = .none
    
    private var currentFaceDistance: Float = 0.0
    private var sessionStartTime: Date?
    
    private var gazeTimer: Timer?
    private var countdownRemaining = 5
    
    private var currentRep = 1
    private let maxReps = 3

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        
        hapticGenerator.prepare()
        successHapticGenerator.prepare()
        
        startInitialCountdown()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
        
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let config = ARFaceTrackingConfiguration()
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
        arSession.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arSession.pause()
        gazeTimer?.invalidate()
        circleView.layer.removeAllAnimations()
    }
    

    private func setupInitialUI() {
        circleView.layer.cornerRadius = circleView.bounds.width / 2
        circleView.backgroundColor = .systemOrange
        
        distanceLabel.alpha = 0
        instructionLabel.alpha = 0
        circleView.alpha = 0
        
        centerMessageLabel.alpha = 1
        centerMessageLabel.isHidden = false
    }


    private func startInitialCountdown() {
        currentPhase = .none
        countdownRemaining = 5
        centerMessageLabel.text = "\(countdownRemaining)"
        
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.countdownRemaining -= 1
            
            if self.countdownRemaining > 0 {
                self.centerMessageLabel.text = "\(self.countdownRemaining)"
            } else {
                timer.invalidate()
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    self.startPreparationSequence()
                }
            }
        }
    }
    
    private func startPreparationSequence() {
        showMessage("Keep your phone at\narm's length", duration: 3.0) {
            self.showMessage("Focus on the dot. Bring the phone\ncloser till it's in focus.", duration: 4.0) {
                self.sessionStartTime = Date() // Start the workout clock
                self.startBringingCloserPhase()
            }
        }
    }

  
    private func startBringingCloserPhase() {
        currentPhase = .bringingCloser
        instructionLabel.text = "Bring phone closer"
        
        // Reset dot size for the "far" starting position
        UIView.animate(withDuration: 0.3) {
            self.circleView.transform = .identity
        }
        
        fadeTransition(showCenterMessage: false, showExerciseUI: true)
    }
    
    private func handleHalfRepCompletion() {
        successHapticGenerator.notificationOccurred(.success)
        currentPhase = .none
        

        showMessage("Now move it back", duration: 1.5) {
            self.startMovingBackPhase()
        }
    }
    
    private func startMovingBackPhase() {
        currentPhase = .movingBack
        instructionLabel.text = "Move phone back"
        
        UIView.animate(withDuration: 0.3) {
            self.circleView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }
        
        fadeTransition(showCenterMessage: false, showExerciseUI: true)
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }
        
        let transform = faceAnchor.transform
        let distance = sqrt(pow(transform.columns.3.x, 2) + pow(transform.columns.3.y, 2) + pow(transform.columns.3.z, 2))
        self.currentFaceDistance = distance
        
        DispatchQueue.main.async {
            if self.currentPhase != .none {
                let distanceInCM = Int(self.currentFaceDistance * 100)
                self.distanceLabel.text = "\(distanceInCM) cm"
                self.checkDistanceGoal()
            }
        }
    }
    
    private func checkDistanceGoal() {
        if currentPhase == .bringingCloser {

            if currentFaceDistance > 0 && currentFaceDistance <= 0.18 {
                handleHalfRepCompletion()
            }
        } else if currentPhase == .movingBack {

            if currentFaceDistance >= 0.50 {
                handleFullRepCompletion()
            }
        }
    }
    
    private func handleFullRepCompletion() {
        successHapticGenerator.notificationOccurred(.success)
        currentPhase = .none
        
        if currentRep < maxReps {
            currentRep += 1
            showMessage("Rep \(currentRep - 1) complete!", duration: 1.5) {
                self.startBringingCloserPhase()
            }
        } else {
            finishExercise()
        }
    }

    private func finishExercise() {
        if let startTime = sessionStartTime {
            let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
            ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds, type: "PencilPushup")
        }
        
        showMessage("Exercise Complete!", duration: 2.0) {
            if let nav = self.navigationController {
                nav.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
    }


    private func showMessage(_ text: String, duration: TimeInterval, completion: @escaping () -> Void) {
        centerMessageLabel.text = text
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                completion()
            }
        }
    }

    private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
            self.instructionLabel.alpha = showExerciseUI ? 1 : 0
            self.circleView.alpha = showExerciseUI ? 1 : 0
            self.distanceLabel.alpha = showExerciseUI ? 1 : 0
        }) { _ in
            completion?()
        }
    }
}
