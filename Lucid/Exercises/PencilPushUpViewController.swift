import UIKit
import ARKit
import SwiftData

class PencilPushUpViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var instructionLabel: UILabel!     // shows warnings or guidance
    @IBOutlet weak var centerMessageLabel: UILabel!   // countdown + instruction messages
    @IBOutlet weak var circleView: UIView!            // focus dot user looks at
    @IBOutlet weak var distanceLabel: UILabel!        // displays face distance in cm
    
    private let arSession = ARSession() // face tracking session
    
    private let errorHapticGenerator = UINotificationFeedbackGenerator()   // error feedback
    private let successHapticGenerator = UINotificationFeedbackGenerator() // success feedback
    private let heavyHapticGenerator = UIImpactFeedbackGenerator(style: .heavy) // strong feedback
        
    private enum ExercisePhase {
        case none, bringingCloser, waitingForReset
    }
    
    private var currentPhase: ExercisePhase = .none
        
    private var isLookingAtScreen = false       // whether user is focusing on dot
    private var currentFaceDistance: Float = 0.0 // distance between face & device
    
    private var sessionStartTime: Date?         // start time for duration tracking
    private var gazeTimer: Timer?               // periodically checks gaze
        
    private var currentRep = 1
    private let maxReps = 5
    
    private var totalFramesChecked = 0          // total gaze checks
    private var totalErrors = 0                 // times user looked away
    
    private let exerciseInstructions: [InstructionStep] = [
        InstructionStep(message: "3", duration: 0.6),
        InstructionStep(message: "2", duration: 0.6),
        InstructionStep(message: "1", duration: 0.6),
        InstructionStep(message: "Keep your phone at arm's length", duration: 3.0),
        InstructionStep(message: "Focus on the dot", duration: 2.5),
        InstructionStep(message: "Bring the phone closer slowly", duration: 3.0)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupInitialUI()
        
        arSession.delegate = self // receive AR face updates
        
        // prepare haptics to reduce delay
        errorHapticGenerator.prepare()
        successHapticGenerator.prepare()
        heavyHapticGenerator.prepare()
        
        centerMessageLabel.alpha = 0
        
        // start instruction sequence
        runInstructionSequence(index: 0)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // hide tab bar for immersive experience
        self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        // ensure device supports face tracking
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let config = ARFaceTrackingConfiguration()
        
        // start AR tracking
        arSession.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // restore tab bar
        self.tabBarController?.tabBar.isHidden = false
        
        // stop AR + timers
        arSession.pause()
        gazeTimer?.invalidate()
        circleView.layer.removeAllAnimations()
    }
    // shows instructions one-by-one using fade animation
    private func runInstructionSequence(index: Int) {
        
        if index < exerciseInstructions.count {
            let step = exerciseInstructions[index]
            
            UIView.animate(withDuration: 0.4, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                
                self.centerMessageLabel.text = step.message
                
                UIView.animate(withDuration: 0.4, animations: {
                    self.centerMessageLabel.alpha = 1
                }) { _ in
                    
                    // Move to next instruction after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) {
                        self.runInstructionSequence(index: index + 1)
                    }
                }
            }
        } else {
            // Instructions complete → start exercise
            UIView.animate(withDuration: 0.5, animations: {
                self.centerMessageLabel.alpha = 0
            }) { _ in
                self.sessionStartTime = Date()
                self.startBringingCloserPhase()
            }
        }
    }
    
    private func startBringingCloserPhase() {
        
        currentPhase = .bringingCloser
        
        // setup UI
        self.instructionLabel.textColor = .lightGray
        self.instructionLabel.text = "Bring phone closer"
        self.circleView.transform = .identity
        
        // hide messages first
        UIView.animate(withDuration: 0.3, animations: {
            self.centerMessageLabel.alpha = 0
        }) { _ in
            
            // show exercise UI
            self.fadeTransition(showCenterMessage: false, showExerciseUI: true) {
                self.startGazeMonitor()
            }
        }
    }
    
    private func handleFullRepCompletion() {
        
        //success feedback
        successHapticGenerator.notificationOccurred(.success)
        successHapticGenerator.prepare()
        
        gazeTimer?.invalidate()
        
        if currentRep < maxReps {
            
            currentRep += 1
            currentPhase = .waitingForReset
            
            //ask user to move phone back
            fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                self.centerMessageLabel.text = "Get back to the initial position"
                
                UIView.animate(withDuration: 0.5) {
                    self.centerMessageLabel.alpha = 1
                }
            }
            
        } else {
            //all reps completed
            currentPhase = .none
            finishExercise()
        }
    }
    
    private func finishExercise() {
        
        gazeTimer?.invalidate()
        currentPhase = .none
        
        // save total time
        if let startTime = sessionStartTime {
            let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
            ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds)
        }
        
        heavyHapticGenerator.impactOccurred()
        
        // reset UI and show completion
        fadeTransition(showCenterMessage: false, showExerciseUI: false) {
            
            self.centerMessageLabel.text = "Exercise Complete!"
            
            UIView.animate(withDuration: 0.5, animations: {
                self.centerMessageLabel.alpha = 1
            }) { _ in
                
                // exit after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if let nav = self.navigationController {
                        nav.popViewController(animated: true)
                    } else {
                        self.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    // checks whether user reached correct distance for rep completion
    private func checkDistanceGoal() {
        
        if currentPhase == .bringingCloser {
            
            // condition:
            // 1.distance <= 21 cm (object close enough)
            // 2.user is still focusing on dot
            if currentFaceDistance > 0 &&
               currentFaceDistance <= 0.21 &&
               isLookingAtScreen {
                
                handleFullRepCompletion()
            }
            
        } else if currentPhase == .waitingForReset {
            
            // user must move back to >= 40 cm before next rep
            if currentFaceDistance >= 0.40 {
                heavyHapticGenerator.impactOccurred()
                heavyHapticGenerator.prepare()
                startBringingCloserPhase()
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            isLookingAtScreen = false
            return
        }
        
        //eye tracking
        let lookAt = faceAnchor.lookAtPoint
        
        //check if gaze is centered
        isLookingAtScreen = abs(lookAt.x) < 0.2 && abs(lookAt.y) < 0.2
        
        //calculate distance using 3D transform
        let transform = faceAnchor.transform
        
        let distance = sqrt(
            pow(transform.columns.3.x, 2) +
            pow(transform.columns.3.y, 2) +
            pow(transform.columns.3.z, 2)
        )
        
        self.currentFaceDistance = distance
        
        DispatchQueue.main.async {
            if self.currentPhase != .none {
                
                // convert to cm for UI
                let distanceInCM = Int(self.currentFaceDistance * 100)
                self.distanceLabel.text = "\(distanceInCM) cm"
                
                self.checkDistanceGoal()
            }
        }
    }
    
    private func setupInitialUI() {
        circleView.layer.cornerRadius = circleView.bounds.width / 2
        circleView.backgroundColor = .systemOrange
        
        distanceLabel.alpha = 0
        instructionLabel.alpha = 0
        circleView.alpha = 0
        centerMessageLabel.alpha = 0
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
    
    private func startGazeMonitor() {
        
        gazeTimer?.invalidate()
        
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            
            guard let self = self,
                  self.currentPhase == .bringingCloser else { return }
            
            self.totalFramesChecked += 1
            
            if self.isLookingAtScreen {
                
                //hide warning if correct
                if self.instructionLabel.text != "Bring phone closer" {
                    UIView.animate(withDuration: 0.3) {
                        self.instructionLabel.alpha = 0
                    }
                }
                
            } else {
                
                //user lost focus
                self.totalErrors += 1
                
                self.errorHapticGenerator.notificationOccurred(.error)
                
                self.instructionLabel.textColor = .systemRed
                self.instructionLabel.text = "⚠️ Please look at the dot!"
                self.instructionLabel.alpha = 1
            }
        }
    }
}
