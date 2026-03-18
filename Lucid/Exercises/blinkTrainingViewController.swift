import UIKit
import ARKit
import SceneKit
import AVFoundation
import SwiftUI
import SwiftData
//number of times for  blink
var doubleBlink = 1
var LeftRighEyeBlink = 1
// tracking the actual exercise duration
private var sessionStartTime: Date?
enum TypeOfBlink {
    case doubleBlink(remaining: Int)
    case singleBlink(eye: String, remaining: Int)
    case completed
    
    
    //remaining number of blinks for any type of blink to display
    var remaining: Int {
        switch self {
        case .doubleBlink(let r): return r
        case .singleBlink(_, let r): return r
        case .completed: return 0
        } 
        
    }
    
    //decreases the number of blinks every time a user blinks
    mutating func decrement() {
        switch self {
        case .doubleBlink(let r): self = .doubleBlink(remaining: r - 1)
        case .singleBlink(let e, let r): self = .singleBlink(eye: e, remaining: r - 1)
        case .completed: break
        }
    }
}
class blinkTrainingViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var instructionLabel: UILabel!
    //sceneView is used to attach ARkit
    @IBOutlet var sceneView: ARSCNView!
    
    //Total number of blinks left Counter
    @IBOutlet var largeCountLabel: UILabel!
    
    @IBOutlet var centerMessageLAbel: UILabel!
    
  
        
        // MARK: - Properties & State
        private var sessionStartTime: Date?
        
        // background video
        private var player: AVQueuePlayer?
        private var playerLayer: AVPlayerLayer?
        private var playerLooper: AVPlayerLooper?
        
        // variable for when exercise is running
        private var currentPhase: TypeOfBlink = .completed
        private var isAcceptingInput = false
        private var isLeftEyeClosed = false
        private var isRightEyeClosed = false
        private let blinkThreshold: Float = 0.7
        
        // error counts while blinking
        private var totalErrors = 0
        private var failedAttemptsForCurrentBlink = 0
        private var consecutiveErrors = 0
        private var errorsPerPhase: [Int] = [0, 0, 0] // [Double, Left, Right]
        
        // variables needed for timers & results
        private var responseTimer: Timer?
        private var phaseTimer: Timer?
        private var secondsRemaining = 0
        
        private var leftMaxBlinks: [Float] = []
        private var rightMaxBlinks: [Float] = []
        private var currentBlinkMaxLeft: Float = 0.0
        private var currentBlinkMaxRight: Float = 0.0
        
        // Haptics
        private let impactMed = UIImpactFeedbackGenerator(style: .rigid)
        private let impactHeavy = UIImpactFeedbackGenerator(style: .rigid)
        private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
        private let notificationGen = UINotificationFeedbackGenerator()
        
        // SwiftData Context (To be passed in from whoever presents this VC)
        var modelContext: ModelContext?

        // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            setupBackgroundVideo()
            setupInitialUI()
            
            // Starts the 5-4-3-2-1 countdown before triggering the first phase
            startInitialCountdown()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            
            // attaches face tracking with the sceneview
            let config = ARFaceTrackingConfiguration()
            sceneView.session.run(config)
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            sceneView.session.pause()
            phaseTimer?.invalidate()
            responseTimer?.invalidate()
        }
        
        override var prefersHomeIndicatorAutoHidden: Bool { return true }
            
        // MARK: - UI Setup
        private func setupInitialUI() {
            instructionLabel.alpha = 0
            largeCountLabel.alpha = 0
            playerLayer?.opacity = 0
            
            instructionLabel.isHidden = false
            largeCountLabel.isHidden = false
            centerMessageLAbel.isHidden = false
            
            centerMessageLAbel.alpha = 1
            sceneView.delegate = self
            sceneView.alpha = 0.01 // keep AR view hidden
        }
        
        private func fadeTransition(showCenterMessage: Bool, showExerciseUI: Bool, completion: (() -> Void)? = nil) {
            UIView.animate(withDuration: 0.5, animations: {
                self.centerMessageLAbel.alpha = showCenterMessage ? 1 : 0
                self.instructionLabel.alpha = showExerciseUI ? 1 : 0
                self.largeCountLabel.alpha = showExerciseUI ? 1 : 0
                self.playerLayer?.opacity = showExerciseUI ? 1 : 0
            }) { _ in
                completion?()
            }
        }
        
        // MARK: - Phase Management
        private func startInitialCountdown() {
            isAcceptingInput = false
            secondsRemaining = 5
            centerMessageLAbel.text = "\(secondsRemaining)"
            
            phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                self.secondsRemaining -= 1
                
                if self.secondsRemaining > 0 {
                    self.centerMessageLAbel.text = "\(self.secondsRemaining)"
                } else {
                    timer.invalidate()
                    self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                        
                        // START THE CLOCK HERE
                        self.sessionStartTime = Date()
                        
                        self.currentPhase = .doubleBlink(remaining: doubleBlink)
                        self.showPreparationMessage("Blink both eyes after the vibration") {
                            self.startActiveBlinkPhase()
                        }
                    }
                }
            }
        }
        
        private func showPreparationMessage(_ message: String, completion: @escaping () -> Void) {
            isAcceptingInput = false
            centerMessageLAbel.text = message
            fadeTransition(showCenterMessage: true, showExerciseUI: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    completion()
                }
            }
        }
        
        private func startTransitionPhase(nextPhase: @escaping () -> Void) {
            isAcceptingInput = false
            responseTimer?.invalidate()
            phaseTimer?.invalidate()
            
            centerMessageLAbel.text = "Nicely Done!"
            fadeTransition(showCenterMessage: true, showExerciseUI: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.fadeTransition(showCenterMessage: false, showExerciseUI: false) {
                    nextPhase()
                }
            }
        }
        
        private func startActiveBlinkPhase() {
            // Sets a 20 second time limit to complete the required blinks
            secondsRemaining = 20
            largeCountLabel.text = "\(currentPhase.remaining)"
            instructionLabel.text = "" // clear any residual nudge text
            
            fadeTransition(showCenterMessage: false, showExerciseUI: true) {
                self.triggerNextCue()
                self.startPhaseTimer()
            }
        }
        
        private func startPhaseTimer() {
            phaseTimer?.invalidate()
            phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else { return }
                self.secondsRemaining -= 1
                
                // If the user runs out of time before finishing their blinks
                if self.secondsRemaining <= 0 {
                    timer.invalidate()
                    self.centerMessageLAbel.text = "Time's Up!"
                    self.startTransitionPhase {
                        self.advancePhase()
                    }
                }
            }
        }
            
        private func triggerNextCue() {
            isAcceptingInput = false
            hideNudge()
            currentBlinkMaxLeft = 0.0
            currentBlinkMaxRight = 0.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.impactMed.impactOccurred()
                self.impactMed.impactOccurred()
                self.isAcceptingInput = true
                self.startResponseTimer()
            }
        }
        
        // waits for user to respond and notifies if no response
        private func startResponseTimer() {
            responseTimer?.invalidate()
            responseTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
                self?.showContextualNudge()
                self?.impactMed.impactOccurred()
                self?.impactMed.impactOccurred()
            }
        }
        
        // alerts user about what they have to do in that specific phase
        private func showContextualNudge() {
            DispatchQueue.main.async {
                let nudgeText: String
                switch self.currentPhase {
                case .doubleBlink: nudgeText = "Please, try a double blink"
                case .singleBlink(let eye, _): nudgeText = "Please, blink your \(eye) eye"
                default: return
                }
                
                self.instructionLabel.text = nudgeText
                UIView.animate(withDuration: 0.5) { self.instructionLabel.alpha = 1.0 }
            }
        }
        
        private func hideNudge() {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.3) { self.instructionLabel.alpha = 0 }
            }
        }
        
        // MARK: - ARKit Face Tracking Delegate
        // function that handles eye blink only if the eye is open
        func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let faceAnchor = anchor as? ARFaceAnchor, isAcceptingInput else { return }
            
            let realLeftValue = faceAnchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0
            let realRightValue = faceAnchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0
            
            if realLeftValue > currentBlinkMaxLeft { currentBlinkMaxLeft = realLeftValue }
            if realRightValue > currentBlinkMaxRight { currentBlinkMaxRight = realRightValue }
            
            let leftClosedNow = realLeftValue > blinkThreshold
            let rightClosedNow = realRightValue > blinkThreshold
            
            let leftOpened = isLeftEyeClosed && !leftClosedNow
            let rightOpened = isRightEyeClosed && !rightClosedNow
            
            if leftOpened || rightOpened {
                handleBlinkAttempt(left: leftOpened, right: rightOpened)
            }
            
            isLeftEyeClosed = leftClosedNow
            isRightEyeClosed = rightClosedNow
        }
        
        // function handling an attempt to blink and verifies it
        private func handleBlinkAttempt(left: Bool, right: Bool) {
            let isCorrect: Bool
            switch currentPhase {
            case .doubleBlink: isCorrect = left && right
            case .singleBlink(let eye, _): isCorrect = (eye == "left") ? (left && !right) : (right && !left)
            default: return
            }
            
            if isCorrect {
                leftMaxBlinks.append(currentBlinkMaxLeft)
                rightMaxBlinks.append(currentBlinkMaxRight)
                consecutiveErrors = 0
                failedAttemptsForCurrentBlink = 0
                processSuccess()
            } else {
                handleError()
            }
        }
        
        // if blink was unsucessfull it alerts user and handles errors
        private func handleError() {
            totalErrors += 1
            consecutiveErrors += 1
            failedAttemptsForCurrentBlink += 1
            
            switch currentPhase {
            case .doubleBlink: errorsPerPhase[0] += 1
            case .singleBlink(let eye, _): errorsPerPhase[eye == "left" ? 1 : 2] += 1
            default: break
            }
            
            self.notificationGen.notificationOccurred(.error)
            self.notificationGen.notificationOccurred(.error)
            self.impactHeavy.impactOccurred()
            self.impactHeavy.impactOccurred()
            
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.2, animations: {
                    self.largeCountLabel.textColor = .systemRed
                }) { _ in
                    UIView.animate(withDuration: 0.2) { self.largeCountLabel.textColor = .white }
                }
                
                if self.consecutiveErrors >= 3 { self.showContextualNudge() }
                
                if self.failedAttemptsForCurrentBlink >= 10 {
                    self.failedAttemptsForCurrentBlink = 0
                    self.processSuccess()
                }
            }
        }
        
        private func processSuccess() {
            responseTimer?.invalidate()
            isAcceptingInput = false
            hideNudge()
            
            DispatchQueue.main.async {
                self.currentPhase.decrement()
                self.largeCountLabel.text = "\(self.currentPhase.remaining)"
                self.impactRigid.impactOccurred()
                self.impactRigid.impactOccurred()
                
                if self.currentPhase.remaining <= 0 {
                    self.notificationGen.notificationOccurred(.success)
                    self.notificationGen.notificationOccurred(.success)
                    self.phaseTimer?.invalidate() // Stop phase countdown
                    self.advancePhase()
                } else {
                    self.triggerNextCue()
                }
            }
        }
        
        // switches the blink phases one by one
        private func advancePhase() {
            consecutiveErrors = 0
            switch currentPhase {
            case .doubleBlink:
                self.currentPhase = .singleBlink(eye: "left", remaining: LeftRighEyeBlink)
                startTransitionPhase {
                    self.showPreparationMessage("Blink LEFT eye only\nafter the vibration") {
                        self.startActiveBlinkPhase()
                    }
                }
            case .singleBlink(let eye, _):
                if eye == "left" {
                    self.currentPhase = .singleBlink(eye: "right", remaining: LeftRighEyeBlink)
                    startTransitionPhase {
                        self.showPreparationMessage("Blink RIGHT eye only\nafter the vibration") {
                            self.startActiveBlinkPhase()
                        }
                    }
                } else {
                    startTransitionPhase {
                        self.finishSession()
                    }
                }
            default: break
            }
        }
        
        private func finishSession() {
            currentPhase = .completed
            phaseTimer?.invalidate()
            
            // STOP THE CLOCK AND CALCULATE
            let startTime = sessionStartTime ?? Date()
            let endTime = Date()
            let elapsedSeconds = Int(endTime.timeIntervalSince(startTime))
            
            // Calculate Average Intensity
            let allPeaks = leftMaxBlinks + rightMaxBlinks
            let avgIntensity = allPeaks.isEmpty ? 0 : allPeaks.reduce(0, +) / Float(allPeaks.count)
            
            // Calculate Responsiveness Score (Percent Success vs Total Attempts)
            let totalSuccessful = Float(leftMaxBlinks.count + rightMaxBlinks.count)
            let totalAttempts = totalSuccessful + Float(totalErrors)
            let responseScore = totalAttempts > 0 ? Double((totalSuccessful / totalAttempts) * 100) : 0
            
            // 1. Create the SwiftData Session Object
            let newSession = ExerciseSession(
                type: "Blink",
                duration: elapsedSeconds,
                intensity: avgIntensity,
                errors: totalErrors
            )
            
            newSession.startingTime = startTime
            newSession.endingTime = endTime
            newSession.leftEyeBlinks = leftMaxBlinks.count
            newSession.rightEyeBlinks = rightMaxBlinks.count
            newSession.errorsPerSession = errorsPerPhase
            newSession.responsivenessScore = responseScore
            
            // 👉 2. USE THE SINGLETON DATABASE MANAGER
            let context = SwiftDataManager.shared.context
            
            // 👉 3. FETCH OR CREATE THE USER TO LINK THE DATA
            let fetchDescriptor = FetchDescriptor<User>()
            let users = (try? context.fetch(fetchDescriptor)) ?? []
            
            let activeUser: User
            if let firstUser = users.first {
                activeUser = firstUser
            } else {
                // If no user exists yet, make a default one so relationships don't break
                activeUser = User(name: "Guest Player", age: 0)
                context.insert(activeUser)
            }
            
            // 👉 4. LINK THE SESSION TO THE USER
            newSession.user = activeUser
            activeUser.exerciseSessions.append(newSession)
            
            // 👉 5. SAVE TO DATABASE
            context.insert(newSession)
            
            do {
                try context.save()
                print("\n✅ BLINK DATA SAVED & LINKED TO: \(activeUser.name) ✅\n")
            } catch {
                print("\n❌ SWIFTDATA SAVE FAILED: \(error) ❌\n")
            }
            
            // 6. Transition to your SwiftUI Summary Screen
            showSummaryScreen(score: responseScore)
        }
    private func showSummaryScreen(score: Double) {
            DispatchQueue.main.async {
                // 1. Get the Window's Root (The ultimate anchor)
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else { return }
                
                // 2. Setup the Report Modal
                let storyboard = UIStoryboard(name: "Report", bundle: nil)
                guard let reportVC = storyboard.instantiateViewController(withIdentifier: "ReportViewController") as? ReportViewController else {
                    print("❌ ERROR: Could not find ReportViewController in Report.storyboard")
                    return
                }
                
                // Pass the calculated parameters
                reportVC.overallScore = Int(score)
                reportVC.totalErrors = self.totalErrors
                
                // NOTE: Adjust this depending on what type 'chartData' is in your ReportViewController
                // Here, I am passing the peaks as a dictionary.
                reportVC.chartData = [
                    "Left": self.leftMaxBlinks,
                    "Right": self.rightMaxBlinks
                ]
                
                let navWrapper = UINavigationController(rootViewController: reportVC)
                navWrapper.modalPresentationStyle = .pageSheet
                
                // 3. Handle the Background Navigation
                // If it's a push/show: it pops. If it's a showDetail: it handles the transition.
                if let nav = self.navigationController {
                    nav.popViewController(animated: false)
                } else {
                    // If navigationController is nil, we dismiss the current detail
                    self.dismiss(animated: false)
                }
                
                // 4. Present from the Root
                // This ensures the modal stays alive even if 'self' is killed
                rootVC.present(navWrapper, animated: true)
            }
        }
    
    
        private func setupBackgroundVideo() {
            guard let path = Bundle.main.path(forResource: "eyeBlinkBackground", ofType: "mp4") else { return }
            let url = URL(fileURLWithPath: path)
            let playerItem = AVPlayerItem(url: url)
            player = AVQueuePlayer(playerItem: playerItem)
            playerLooper = AVPlayerLooper(player: player!, templateItem: playerItem)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = view.bounds
            playerLayer?.videoGravity = .resizeAspectFill
            view.layer.insertSublayer(playerLayer!, at: 0)
            player?.play()
        }
    }
