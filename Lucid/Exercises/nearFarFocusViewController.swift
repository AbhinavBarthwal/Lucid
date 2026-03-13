import UIKit
import ARKit
class nearFarFocusViewController: UIViewController,ARSessionDelegate{
    
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var centerMessageLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    
    
    // This AR session runs head tracking.
    private let arSession = ARSession()
    
    private var isLookingAtScreen = false
    
    // Haptic generator used to alert the user if they look away when they shouldn't.
    private let errorHapticGenerator = UINotificationFeedbackGenerator()
    
    // This enum categorizes the three main states of our visual focus exercise.
    private enum ExercisePhase {
        case none, near, far
    }
    private var currentPhase: ExercisePhase = .none
    
    // This timer manages the countdown for the active phase.
    private var phaseTimer: Timer?
    private var secondsRemaining = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialUI()
        arSession.delegate = self
 
        errorHapticGenerator.prepare()
                startInitialCountdown()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard ARFaceTrackingConfiguration.isSupported else { return }
        
        //tracking the face
        let config = ARFaceTrackingConfiguration()
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Clean up
        arSession.pause()
        phaseTimer?.invalidate()
    }
    
    
    // session that figures out where the user is looking
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            isLookingAtScreen = false
            return
        }
        
        let lookAt = faceAnchor.lookAtPoint
        
        // If the X and Y coordinates of the gaze are within 0.2 units they are looking at the screen. // may change for accuracy
        isLookingAtScreen = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
    }
    
    
    // Configures the starting opacities so only the central countdown message is visible initially.
    private func setupInitialUI() {
        circleView.layer.cornerRadius = circleView.bounds.width / 2
        timerLabel.alpha = 0
        instructionLabel.alpha = 0
        circleView.alpha = 0
        
        timerLabel.isHidden = false
        instructionLabel.isHidden = false
        circleView.isHidden = false
        
        centerMessageLabel.alpha = 1
        centerMessageLabel.isHidden = false
    }
    
    // crossfades between the instructional center text and the exercise.
    private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, animations: {
            self.centerMessageLabel.alpha = showCenterMessage ? 1 : 0
            self.timerLabel.alpha = showExerciseUI ? 1 : 0
            self.instructionLabel.alpha = showExerciseUI ? 1 : 0
            self.circleView.alpha = showExerciseUI ? 1 : 0
        }) { _ in
            completion?()
        }
    }
    

    
    // Runs a simple 5-1 countdown in the center of the screen before the real exercise begins.
    private func startInitialCountdown() {
        currentPhase = .none
        secondsRemaining = 5
        centerMessageLabel.text = "\(secondsRemaining)"
        
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.secondsRemaining -= 1
            
            if self.secondsRemaining > 0 {
                self.centerMessageLabel.text = "\(self.secondsRemaining)"
            } else {
                timer.invalidate()
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    self.showPreparationMessage("Focus on the dot, keep your screen\nwithin the range of 25-40cms") {
                        self.startNearFocusPhase()
                    }
                }
            }
        }
    }
    
    // Displays instructions for 5 seconds to let the user prepare .
    private func showPreparationMessage(_ message: String, completion: @escaping () -> Void) {
        currentPhase = .none
        circleView.layer.removeAllAnimations()
        centerMessageLabel.text = message
        
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                completion()
            }
        }
    }
    
    //  the 10 second phase where the user must focus on the screen (Near Focus).
    private func startNearFocusPhase() {
        currentPhase = .near
        secondsRemaining = 10
        timerLabel.text = "\(secondsRemaining)"
        instructionLabel.textColor = .lightGray
        instructionLabel.text = "Focus on the dot, keep your screen\nwithin the range of 25-40cms"
        
        circleView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        
        // Slowly shrinks the circle over 10 seconds to help the eyes focus inwards.
        fadeTransition(showCenterMessage: false, showExerciseUI: true) {
            UIView.animate(withDuration: 10.0, delay: 0, options: [.curveLinear]) {
                self.circleView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            }
            self.startPhaseTimer { self.startTransitionPhase(nextPhase: self.prepareFarFocus) }
        }
    }
    
    // Prepares the user for the second half of the exercise where they must look away.
    private func prepareFarFocus() {
        showPreparationMessage("Focus at a distant object\nor look outside the window") {
            self.startFarFocusPhase()
        }
    }
    
    //  the 10 second phase where the user must look away from the screen (Far Focus).
    private func startFarFocusPhase() {
        currentPhase = .far
        secondsRemaining = 10
        timerLabel.text = "\(secondsRemaining)"
        instructionLabel.textColor = .lightGray
        instructionLabel.text = "Focus at a distant object\nor look outside the window"
        
        circleView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        
        // Slowly expands the circle over 10 seconds to give a sense of outward expansion.
        fadeTransition(showCenterMessage: false, showExerciseUI: true) {
            UIView.animate(withDuration: 10.0, delay: 0, options: [.curveLinear]) {
                self.circleView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
            self.startPhaseTimer { self.finishExercise() }
        }
    }
    
    // Shows a message between phases or at the end.
    private func startTransitionPhase(nextPhase: @escaping () -> Void) {
        currentPhase = .none
        circleView.layer.removeAllAnimations()
        centerMessageLabel.text = "Nicely Done!"
        
        fadeTransition(showCenterMessage: true, showExerciseUI: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                nextPhase()
            }
        }
    }
    
    //   timer . It runs every second checking if the user is looking at the correct target.
    private func startPhaseTimer(completion: @escaping () -> Void) {
        phaseTimer?.invalidate()
        
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            var isValid = true
            
            // Validate the user's gaze based on whether we are in a Near or Far phase.
            if self.currentPhase == .near {
                isValid = self.isLookingAtScreen
                self.instructionLabel.textColor = isValid ? .lightGray : .systemRed
                self.instructionLabel.text = isValid ? "Focus on the dot, keep your screen\nwithin the range of 25-40cms" : "⚠️ Please look AT the screen!"
            } else if self.currentPhase == .far {
                isValid = !self.isLookingAtScreen
                self.instructionLabel.textColor = isValid ? .lightGray : .systemRed
                self.instructionLabel.text = isValid ? "Focus at a distant object\nor look outside the window" : "⚠️ Please look AWAY from the screen!"
            }
            
            // Only decrement the timer if the user is successfully doing the exercise.
            if isValid {
                self.secondsRemaining -= 1
                self.timerLabel.text = "\(self.secondsRemaining)"
            } else {
                // Fire a haptic alert if they break the rule.
                self.errorHapticGenerator.notificationOccurred(.error)
            }
            
            // Once the timer hits zero, stop tracking and move to the completion block.
            if self.secondsRemaining <= 0 {
                timer.invalidate()
                self.instructionLabel.textColor = .lightGray
                completion()
            }
        }
    }
    
    // Finish
    private func finishExercise() {
        startTransitionPhase {
            print("Exercise Completed - Transitioning to summary")
        }
    }
}
