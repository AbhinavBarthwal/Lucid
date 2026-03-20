import UIKit
import ARKit
import SwiftData

class SaccadicJumps: UIViewController, ARSessionDelegate {
    

    @IBOutlet weak var dotTarget: UIView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var countdownLabel: UILabel!
    
    @IBOutlet weak var centerXConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerYConstraint: NSLayoutConstraint!
    

    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
    

    enum Position: CaseIterable {
        case center, topLeft, topRight, bottomLeft, bottomRight
    }
    
    private var lastPosition: Position = .center
    private var dotCount = 0
    private var successfulFollows = 0
    private var hasLookedAtCurrentDot = false
    private let faceTrackingSession = ARSession()
    private var currentGazePoint = CGPoint.zero
    
    private var exerciseTimer: Timer?
    private var sessionTimer: Timer?
    private var countdownTimer: Timer?
    private var countdownTime = 5
    
    private var sessionStartTime: Date?

    override var prefersStatusBarHidden: Bool {
        return true
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        prepareInitialState()
        setupEyeTracking()
        notificationGenerator.prepare()
        impactGenerator.prepare()
        
        startCountdownPhase()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        self.tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        faceTrackingSession.pause()
        exerciseTimer?.invalidate()
        sessionTimer?.invalidate()
        countdownTimer?.invalidate()
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func prepareInitialState() {
        dotTarget.layer.cornerRadius = dotTarget.frame.size.width / 2
        dotTarget.clipsToBounds = true
        [dotTarget, countdownLabel, instructionLabel, scoreLabel].forEach { $0?.alpha = 0 }
    }

    private func setupEyeTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        faceTrackingSession.delegate = self
        let configuration = ARFaceTrackingConfiguration()
        faceTrackingSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first as? ARFaceAnchor else { return }
        let rawLookAt = faceAnchor.lookAtPoint
        
        DispatchQueue.main.async {
            self.currentGazePoint = self.calculateHighSensitivityPoint(rawLookAt)
            if !self.hasLookedAtCurrentDot && self.dotTarget.alpha == 1 {
                self.detectMagneticFocus()
            }
        }
    }
    
    private func calculateHighSensitivityPoint(_ lookAt: simd_float3) -> CGPoint {
        guard let windowScene = view.window?.windowScene else { return .zero }
        let screen = windowScene.screen.bounds
        let sensitivity: CGFloat = 8.0
        let x = (screen.width / 2) + (CGFloat(lookAt.x) * screen.width * sensitivity)
        let yOffset = screen.height * 0.08
        let y = (screen.height / 2) - (CGFloat(lookAt.y) * screen.height * sensitivity) + yOffset
        return CGPoint(x: x, y: y)
    }

    private func detectMagneticFocus() {
        let targetCenter = dotTarget.center
        let distance = sqrt(pow(targetCenter.x - currentGazePoint.x, 2) + pow(targetCenter.y - currentGazePoint.y, 2))
        
        if distance < 180 {
            hasLookedAtCurrentDot = true
            successfulFollows += 1
            
            impactGenerator.impactOccurred()
            
            
            UIView.animate(withDuration: 0.1) {
                self.dotTarget.backgroundColor = .systemGreen
                self.dotTarget.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }
        }
    }

    private func performSaccadicJump() {
        if !hasLookedAtCurrentDot && dotCount > 0 {
            notificationGenerator.notificationOccurred(.error)
        }
        
        hasLookedAtCurrentDot = false
        dotTarget.backgroundColor = .systemOrange
        dotTarget.transform = .identity
        
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        let horizontalPadding: CGFloat = 60
        let verticalPadding: CGFloat = 120
        
        let maxX = (screenWidth / 2) - horizontalPadding
        let maxY = (screenHeight / 2) - verticalPadding
        
        let available = Position.allCases.filter { $0 != lastPosition }
        if let next = available.randomElement() {
            switch next {
            case .center:
                centerXConstraint.constant = 0
                centerYConstraint.constant = 0
            case .topLeft:
                centerXConstraint.constant = -maxX
                centerYConstraint.constant = -maxY
            case .topRight:
                centerXConstraint.constant = maxX
                centerYConstraint.constant = -maxY
            case .bottomLeft:
                centerXConstraint.constant = -maxX
                centerYConstraint.constant = maxY
            case .bottomRight:
                centerXConstraint.constant = maxX
                centerYConstraint.constant = maxY
            }
            lastPosition = next
            dotCount += 1
        }
        
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }


    private func startInstructionPhase() {
        instructionLabel.text = "Keep the center dot between your eyes\nand hold the phone straight."
        
        UIView.animate(withDuration: 1.0) {
            self.instructionLabel.alpha = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            UIView.animate(withDuration: 1.0) {
                self.instructionLabel.alpha = 0
            } completion: { _ in
                self.transitionToExercise()
            }
        }
    }

    private func startCountdownPhase() {
        countdownLabel.alpha = 1
        countdownTime = 5
        countdownLabel.text = "\(countdownTime)"
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            self.countdownTime -= 1
            if self.countdownTime > 0 {
                self.countdownLabel.text = "\(self.countdownTime)"
            } else {
                timer.invalidate()
                
                self.startInstructionPhase()
            }
        }
    }
    
    private func transitionToExercise() {
        setNeedsStatusBarAppearanceUpdate()
        UIView.animate(withDuration: 0.5) {
            self.dotTarget.alpha = 1
            self.scoreLabel.alpha = 1
            self.countdownLabel.alpha = 0
        }
        startExercise()
    }

    private func startExercise() {
        self.sessionStartTime = Date()
        notificationGenerator.notificationOccurred(.success)
        
        exerciseTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.performSaccadicJump()
        }
        
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.endExercise()
        }
    }
    
    private func endExercise() {
        exerciseTimer?.invalidate()
        sessionTimer?.invalidate()
        faceTrackingSession.pause()
        

        if let startTime = sessionStartTime {
            let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
            ExerciseDataManager.shared.addExerciseTime(seconds: elapsedSeconds, type: "SaccadicJumps")
        }
        
        notificationGenerator.notificationOccurred(.success)
        
        UIView.animate(withDuration: 1.0) {
            self.dotTarget.alpha = 0
            self.scoreLabel.text = "Final Score: \(self.successfulFollows)"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if let nav = self.navigationController {
                nav.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
    }
}
