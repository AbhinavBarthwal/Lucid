import UIKit

class OSDIViewController: UIViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var onboardingInstructionLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel?
    @IBOutlet weak var responseSlider: UISlider?
    @IBOutlet weak var nextButton: UIButton?

    // MARK: - New Onboarding Properties
    var onTestCompleted: ((Double, String) -> Void)?
    var shouldShowResultUI: Bool = true

    // MARK: - Instructions Phase Properties
    private var isInstructionPhase = true
    private var currentInstructionIndex = 0
    private var instructionNextButton: UIButton?
    private var instructionPrevButton: UIButton?
    
    private let osdiInstructions: [InstructionStep] = [
        InstructionStep(message: "This test asks simple questions about dry, tired, or sore eyes.", duration: 4.5),
        InstructionStep(message: "Take the test based on how your eyes felt in the last week.", duration: 4.5),
        InstructionStep(message: "Use the slider: Never means it did not happen. Mostly means it happened a lot.", duration: 5.5),
        InstructionStep(message: "If a daily activity does not apply to you, tap Skip. ", duration: 3.5)
    ]

    private var currentIndex = 0
    private var scores: [Int] = Array(repeating: 0, count: 12)
    private var originalCenter: CGPoint = .zero
    private var FirstLoad = true
    private var didComplete = false
    
    private let options = ["None of the time", "Some of the time", "Half of the time", "Most of the time", "All of the time"]
    
    private let questionnaire: [(cat: String, q: String)] = [
        // Section 1: How your eyes feel (non-skippable)
        ("How your eyes feel", "Does bright light or sunlight hurt your eyes?"),
        ("How your eyes feel", "Do your eyes feel like something is stuck or itchy inside them?"),
        ("How your eyes feel", "Do your eyes feel sore, sting, or burn?"),
        ("How your eyes feel", "Does your vision go blurry or out of focus sometimes?"),
        
        // Section 2: Your surroundings (non-skippable)
        ("Your surroundings", "Do your eyes feel uncomfortable when it is windy or you're on a bike?"),
        ("Your surroundings", "Do your eyes feel very dry in the summer heat?"),
        ("Your surroundings", "Do your eyes feel dry in AC rooms or in front of a fan?"),
        ("Your surroundings", "Do your eyes get red or sting near dust, smoke, or heavy traffic?"),
        
        // Section 3: Daily activities (skippable, questions 8-11 = index 8-11)
        ("Daily activities", "Is it hard to read books or long messages on your phone?"),
        ("Daily activities", "Do your eyes struggle when driving at night because of headlights?"),
        ("Daily activities", "Do you have trouble seeing clearly on your phone, laptop, or ATM screen?"),
        ("Daily activities", "Do your eyes feel tired when you watch a movie or a cricket match?")
    ]

    // Custom UI Elements for Rating Circles (linked to Storyboard)
    @IBOutlet weak var neverLabel: UILabel!
    @IBOutlet weak var mostlyLabel: UILabel!
    @IBOutlet weak var circleStackView: UIStackView!
    @IBOutlet weak var prevNavButton: UIButton!
    @IBOutlet weak var nextNavButton: UIButton!
    
    private var circleButtons: [UIButton] = []

    // Custom Intro Transition Elements
    private let introContainerView = UIView()
    private let introCategoryLabel = UILabel()
    private let introInstructionLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialState()
        setupCustomUI()
        setupIntroUI()
        setupInstructionButtons()
    }

    private func setupInitialState() {
        categoryLabel?.isHidden = true
        [instructionLabel, questionLabel, pageControl, categoryLabel, neverLabel, mostlyLabel, prevNavButton, nextNavButton, introContainerView, onboardingInstructionLabel].forEach {
            $0?.alpha = 0
        }
        
        categoryLabel?.numberOfLines = 0
        instructionLabel?.numberOfLines = 0
        questionLabel?.numberOfLines = 0
        neverLabel?.numberOfLines = 0
        mostlyLabel?.numberOfLines = 0
        onboardingInstructionLabel?.numberOfLines = 0
        valueLabel?.numberOfLines = 0

        onboardingInstructionLabel?.font = .systemFont(ofSize: 32, weight: .bold)
        onboardingInstructionLabel?.textColor = .white
        onboardingInstructionLabel?.textAlignment = .center

        instructionLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        instructionLabel?.textColor = .lightGray
        instructionLabel?.textAlignment = .center
        
        // Hide valueLabel as requested by the user
        valueLabel?.isHidden = true
        valueLabel?.alpha = 0
        
        responseSlider?.alpha = 0
        
        nextButton?.isHidden = true
    }

    private func setupCustomUI() {
        // Hide circular buttons
        circleStackView.isHidden = true
        circleStackView.alpha = 0
        
        // Programmatic UISlider configuration
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.maximumValue = 4
        slider.minimumTrackTintColor = UIColor(named: "AccentColor") ?? .systemOrange
        slider.maximumTrackTintColor = .darkGray
        slider.thumbTintColor = UIColor(named: "AccentColor") ?? .systemOrange
        slider.alpha = 0 // Keep hidden during transitions
        slider.isHidden = true
        
        view.addSubview(slider)
        self.responseSlider = slider
        
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sliderTapped(_:)))
        slider.addGestureRecognizer(tapGesture)
        
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: circleStackView.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: circleStackView.trailingAnchor),
            slider.centerYAnchor.constraint(equalTo: circleStackView.centerYAnchor),
            slider.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        setupSliderTicks(slider: slider)
        
        // Setup valueLabel programmatically if not present in storyboard
        if self.valueLabel == nil {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .systemFont(ofSize: 22, weight: .bold)
            label.textColor = .lightGray
            label.textAlignment = .center
            label.numberOfLines = 0
            view.addSubview(label)
            self.valueLabel = label
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.bottomAnchor.constraint(equalTo: slider.topAnchor, constant: -20),
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
            ])
        }
        valueLabel?.isHidden = true // Hide value label completely
        valueLabel?.alpha = 0
        
        // Setup Skip Button programmatically
        let skipBtn = UIButton(type: .system)
        skipBtn.translatesAutoresizingMaskIntoConstraints = false
        skipBtn.setTitle("Skip", for: .normal)
        skipBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        let orangeColor = UIColor(named: "AccentColor") ?? .systemOrange
        skipBtn.setTitleColor(orangeColor, for: .normal)
        view.addSubview(skipBtn)
        self.skipButton = skipBtn
        skipBtn.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            skipBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipBtn.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 20),
            skipBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
        skipBtn.isHidden = true
        
        // Capitalize labels and increase font size to 22 bold
        neverLabel.text = "Never"
        neverLabel.textColor = .lightGray
        neverLabel.font = .systemFont(ofSize: 22, weight: .bold)
        
        mostlyLabel.text = "Mostly"
        mostlyLabel.textColor = .lightGray
        mostlyLabel.font = .systemFont(ofSize: 22, weight: .bold)
        // Apply titleTextAttributesTransformer to preserve size 24 bold/medium on dynamic title updates
        if #available(iOS 15.0, *) {
            nextNavButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 24, weight: .bold)
                return outgoing
            }
            prevNavButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 24, weight: .medium)
                return outgoing
            }
        } else {
            nextNavButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
            prevNavButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .medium)
        }
        
        // Setup Navigation Actions
        prevNavButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextNavButton.addTarget(self, action: #selector(customNextTapped), for: .touchUpInside)
        
        // Shift slider and labels up by increasing the distance between the buttons and the slider container
        for constraint in view.constraints {
            if (constraint.firstItem === prevNavButton || constraint.firstItem === nextNavButton) &&
               constraint.secondItem === circleStackView &&
               constraint.firstAttribute == .top {
                constraint.constant = 110
            }
        }
    }

    private func setupIntroUI() {
        introContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(introContainerView)
        
        introCategoryLabel.translatesAutoresizingMaskIntoConstraints = false
        introCategoryLabel.font = .systemFont(ofSize: 34, weight: .bold)
        introCategoryLabel.textColor = .white
        introCategoryLabel.textAlignment = .center
        introCategoryLabel.numberOfLines = 0
        
        introInstructionLabel.translatesAutoresizingMaskIntoConstraints = false
        introInstructionLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        introInstructionLabel.textColor = .lightGray
        introInstructionLabel.textAlignment = .center
        introInstructionLabel.numberOfLines = 0
        
        introContainerView.addSubview(introCategoryLabel)
        introContainerView.addSubview(introInstructionLabel)
        
        NSLayoutConstraint.activate([
            introContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            introContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            introContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            introContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            introCategoryLabel.topAnchor.constraint(equalTo: introContainerView.topAnchor),
            introCategoryLabel.leadingAnchor.constraint(equalTo: introContainerView.leadingAnchor),
            introCategoryLabel.trailingAnchor.constraint(equalTo: introContainerView.trailingAnchor),
            
            introInstructionLabel.topAnchor.constraint(equalTo: introCategoryLabel.bottomAnchor, constant: 18),
            introInstructionLabel.leadingAnchor.constraint(equalTo: introContainerView.leadingAnchor),
            introInstructionLabel.trailingAnchor.constraint(equalTo: introContainerView.trailingAnchor),
            introInstructionLabel.bottomAnchor.constraint(equalTo: introContainerView.bottomAnchor)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if FirstLoad {
            originalCenter = categoryLabel.center
            if isInstructionPhase {
                runInstructionSequence(index: 0)
            } else {
                handleCategoryTransition()
            }
            FirstLoad = false
        }
    }

    // MARK: - Countdown & Instructions

    private func runInstructionSequence(index: Int) {
        guard isInstructionPhase else { return }
        currentInstructionIndex = index
        let isFirstRun = InstructionTracker.isFirstRun(for: "OSDI")
        
        if index < osdiInstructions.count {
            let step = osdiInstructions[index]
            
            if isFirstRun {
                instructionNextButton?.isHidden = false
                let canGoBack = index > 0
                instructionPrevButton?.isHidden = !canGoBack
                
                let isLastStep = (index == osdiInstructions.count - 1)
                instructionNextButton?.setTitle(isLastStep ? "Start Test" : "Next", for: .normal)
            } else {
                instructionNextButton?.isHidden = false
                instructionPrevButton?.isHidden = true
                instructionNextButton?.setTitle("Skip", for: .normal)
            }
            
            UIView.animate(withDuration: 0.4, animations: {
                self.onboardingInstructionLabel.alpha = 0
                self.instructionNextButton?.alpha = 0
                self.instructionPrevButton?.alpha = 0
            }) { _ in
                self.onboardingInstructionLabel.text = step.message
                UIView.animate(withDuration: 0.4, animations: {
                    self.onboardingInstructionLabel.alpha = 1
                    self.instructionNextButton?.alpha = 1
                    self.instructionPrevButton?.alpha = isFirstRun && (index > 0) ? 1.0 : 0.0
                }) { _ in
                    if !isFirstRun {
                        DispatchQueue.main.asyncAfter(deadline: .now() + step.duration) { [weak self] in
                            guard let self = self, self.isInstructionPhase, self.currentInstructionIndex == index else { return }
                            self.runInstructionSequence(index: index + 1)
                        }
                    }
                }
            }
        } else {
            finishInstructionsAndStartOSDI()
        }
    }

    private func setupInstructionButtons() {
        let isFirstRun = InstructionTracker.isFirstRun(for: "OSDI")
        
        let nextBtn = UIButton(type: .system)
        nextBtn.translatesAutoresizingMaskIntoConstraints = false
        nextBtn.layer.cornerRadius = 14
        nextBtn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        nextBtn.setTitleColor(.white, for: .normal)
        nextBtn.backgroundColor = UIColor(named: "AccentColor") ?? .systemOrange
        nextBtn.alpha = 0
        view.addSubview(nextBtn)
        self.instructionNextButton = nextBtn
        nextBtn.addTarget(self, action: #selector(instructionNextTapped), for: .touchUpInside)
        
        if isFirstRun {
            nextBtn.setTitle("Next", for: .normal)
            
            let prevBtn = UIButton(type: .system)
            prevBtn.translatesAutoresizingMaskIntoConstraints = false
            prevBtn.layer.cornerRadius = 14
            prevBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            prevBtn.setTitleColor(.white, for: .normal)
            prevBtn.backgroundColor = .clear
            prevBtn.layer.borderWidth = 1
            prevBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            prevBtn.setTitle("Previous", for: .normal)
            prevBtn.alpha = 0
            view.addSubview(prevBtn)
            self.instructionPrevButton = prevBtn
            prevBtn.addTarget(self, action: #selector(instructionPrevTapped), for: .touchUpInside)
            
            NSLayoutConstraint.activate([
                nextBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
                nextBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
                nextBtn.bottomAnchor.constraint(equalTo: prevBtn.topAnchor, constant: -12),
                nextBtn.heightAnchor.constraint(equalToConstant: 50),
                
                prevBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
                prevBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
                prevBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                prevBtn.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            prevBtn.isHidden = true // Hidden initially for step 0
        } else {
            nextBtn.setTitle("Skip", for: .normal)
            
            NSLayoutConstraint.activate([
                nextBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
                nextBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
                nextBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                nextBtn.heightAnchor.constraint(equalToConstant: 50)
            ])
        }
    }
    
    @objc private func instructionNextTapped() {
        if InstructionTracker.isFirstRun(for: "OSDI") {
            runInstructionSequence(index: currentInstructionIndex + 1)
        } else {
            finishInstructionsAndStartOSDI()
        }
    }
    
    @objc private func instructionPrevTapped() {
        if InstructionTracker.isFirstRun(for: "OSDI") && currentInstructionIndex > 0 {
            runInstructionSequence(index: currentInstructionIndex - 1)
        }
    }
    
    private func finishInstructionsAndStartOSDI() {
        InstructionTracker.markAsCompleted(for: "OSDI")
        currentInstructionIndex = 999
        isInstructionPhase = false
        
        UIView.animate(withDuration: 0.3, animations: {
            self.instructionNextButton?.alpha = 0
            self.instructionPrevButton?.alpha = 0
            self.onboardingInstructionLabel?.alpha = 0
        }) { _ in
            self.instructionNextButton?.removeFromSuperview()
            self.instructionPrevButton?.removeFromSuperview()
            self.onboardingInstructionLabel?.removeFromSuperview()
        }
        
        // Start OSDI
        handleCategoryTransition()
    }

    private func handleCategoryTransition() {
        // Fade out all main UI elements during category/section transition
        [questionLabel, pageControl, neverLabel, mostlyLabel, prevNavButton, nextNavButton, categoryLabel, instructionLabel, skipButton].forEach { $0?.alpha = 0 }
        responseSlider?.alpha = 0
        responseSlider?.isHidden = true
        tickContainerView?.alpha = 0
        tickContainerView?.isHidden = true
        valueLabel?.alpha = 0
        
        introCategoryLabel.text = questionnaire[currentIndex].cat
        
        let sectionInstruction: String
        switch questionnaire[currentIndex].cat {
        case "How your eyes feel":
            sectionInstruction = "Think about the last week. How often did this happen?"
        case "Your surroundings":
            sectionInstruction = "Think about these places. How often did your eyes feel bad there?"
        case "Daily activities":
            sectionInstruction = "Did your eyes make these tasks harder? Tap Skip if the task does not apply."
        default:
            sectionInstruction = "Think about the last week. How often did this happen?"
        }
        introInstructionLabel.text = sectionInstruction
        
        // Fade intro category & instruction in the middle of the screen
        UIView.animate(withDuration: 0.5, animations: {
            self.introContainerView.alpha = 1.0
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) { [weak self] in
                guard let self = self else { return }
                UIView.animate(withDuration: 0.4, animations: {
                    self.introContainerView.alpha = 0
                }) { _ in
                    self.moveToHeaderAndReveal()
                }
            }
        }
    }

    private func moveToHeaderAndReveal() {
        categoryLabel.text = questionnaire[currentIndex].cat
        categoryLabel.font = .systemFont(ofSize: 32, weight: .bold)
        
        updateContent()
        
        UIView.animate(withDuration: 0.5) {
            self.categoryLabel.alpha = 0.0
            self.categoryLabel.isHidden = true
            self.instructionLabel.alpha = 0 // Hide section instructions from the top during questions
            [self.questionLabel, self.neverLabel, self.mostlyLabel, self.prevNavButton, self.nextNavButton, self.pageControl].forEach { $0?.alpha = 1.0 }
            self.responseSlider?.isHidden = false
            self.responseSlider?.alpha = 1.0
            self.tickContainerView?.isHidden = false
            self.tickContainerView?.alpha = 1.0
            self.valueLabel?.alpha = 0.0
            
            let isDailyActivity = (self.currentIndex >= 8 && self.currentIndex <= 11)
            self.skipButton?.alpha = isDailyActivity ? 1.0 : 0.0
        }
    }

    private func calculateScore() {
        let answeredScores = scores.filter { $0 >= 0 }
        let totalAnsweredCount = answeredScores.count
        
        let finalOSDI: Double
        if totalAnsweredCount > 0 {
            let sum = answeredScores.reduce(0, +)
            finalOSDI = (Double(sum) * 25.0) / Double(totalAnsweredCount)
        } else {
            finalOSDI = 0.0
        }
        
        // Determine severity
        var severity = ""
        if finalOSDI <= 12 { severity = "Normal" }
        else if finalOSDI <= 22 { severity = "Mild" }
        else if finalOSDI <= 32 { severity = "Moderate" }
        else { severity = "Severe" }
        
        // Save to Data Manager
        OSDIDataManager.shared.saveOSDIScore(score: finalOSDI, severity: severity)
        
        guard !didComplete else { return }
        didComplete = true
        
        // Branch based on whether we should show the UI
        if shouldShowResultUI {
            showResultScreen(score: finalOSDI, severity: severity)
        } else {
            nextNavButton.isEnabled = false
            circleButtons.forEach { $0.isEnabled = false }
            onTestCompleted?(finalOSDI, severity)
        }
    }

    private func showResultScreen(score: Double, severity: String) {
        let vc = OSDIResultPageCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
        vc.osdiScore = score
        vc.severity = severity

        let resultNavigationController = UINavigationController(rootViewController: vc)
        resultNavigationController.modalPresentationStyle = .fullScreen
        resultNavigationController.navigationBar.prefersLargeTitles = false

        if let navigationController {
            navigationController.popViewController(animated: false)
            navigationController.present(resultNavigationController, animated: true)
        } else {
            present(resultNavigationController, animated: true)
        }
    }

    private var skipButton: UIButton?

    @objc private func sliderTapped(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let slider = responseSlider else { return }
        let point = gestureRecognizer.location(in: slider)
        let percentage = point.x / slider.bounds.width
        let delta = Float(percentage) * (slider.maximumValue - slider.minimumValue)
        let value = slider.minimumValue + delta
        
        slider.value = value
        sliderValueChanged(slider)
    }

    @objc private func skipTapped() {
        scores[currentIndex] = -2
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        customNextTapped()
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        let roundedValue = round(sender.value)
        sender.setValue(roundedValue, animated: true)
        
        let selectedValue = Int(roundedValue)
        scores[currentIndex] = selectedValue
        
        // Update value label
        valueLabel?.text = options[selectedValue]
        valueLabel?.textColor = UIColor(named: "AccentColor") ?? .systemOrange
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        // Update navigation buttons enablement
        updateNavigationButtonsState()
    }
    
    private var tickContainerView: UIView?
    
    private func setupSliderTicks(slider: UISlider) {
        let tickContainer = UIView()
        tickContainer.translatesAutoresizingMaskIntoConstraints = false
        tickContainer.isUserInteractionEnabled = false
        tickContainer.alpha = 0
        tickContainer.isHidden = true
        view.insertSubview(tickContainer, aboveSubview: slider)
        self.tickContainerView = tickContainer
        
        NSLayoutConstraint.activate([
            tickContainer.leadingAnchor.constraint(equalTo: slider.leadingAnchor, constant: 10),
            tickContainer.trailingAnchor.constraint(equalTo: slider.trailingAnchor, constant: -10),
            tickContainer.centerYAnchor.constraint(equalTo: slider.centerYAnchor),
            tickContainer.heightAnchor.constraint(equalToConstant: 10)
        ])
        
        for i in 0..<5 {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = .white.withAlphaComponent(0.8)
            dot.layer.cornerRadius = 4
            tickContainer.addSubview(dot)
            
            let fraction = CGFloat(i) / 4.0
            
            if i == 0 {
                dot.leadingAnchor.constraint(equalTo: tickContainer.leadingAnchor).isActive = true
            } else if i == 4 {
                dot.trailingAnchor.constraint(equalTo: tickContainer.trailingAnchor).isActive = true
            } else {
                let constraint = NSLayoutConstraint(
                    item: dot,
                    attribute: .centerX,
                    relatedBy: .equal,
                    toItem: tickContainer,
                    attribute: .trailing,
                    multiplier: fraction,
                    constant: 0
                )
                tickContainer.addConstraint(constraint)
            }
            
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 8),
                dot.heightAnchor.constraint(equalToConstant: 8),
                dot.centerYAnchor.constraint(equalTo: tickContainer.centerYAnchor)
            ])
        }
    }
    
    private func updateNavigationButtonsState() {
        let isAnswered = scores[currentIndex] != -1
        
        prevNavButton.isHidden = (currentIndex == 0)
        
        let isLastQuestion = (currentIndex == questionnaire.count - 1)
        let title = isLastQuestion ? "Submit" : "Next"
        
        if #available(iOS 15.0, *), var config = nextNavButton.configuration {
            config.title = title
            nextNavButton.configuration = config
        } else {
            nextNavButton.setTitle(title, for: .normal)
        }
        
        nextNavButton.isEnabled = isAnswered
        nextNavButton.alpha = isAnswered ? 1.0 : 0.3
    }

    @objc private func prevTapped() {
        if currentIndex > 0 {
            currentIndex -= 1
            animateSlideLeft()
            updateContent()
        }
    }

    @objc private func customNextTapped() {
        if currentIndex < questionnaire.count - 1 {
            let oldCat = questionnaire[currentIndex].cat
            currentIndex += 1
            if oldCat != questionnaire[currentIndex].cat {
                handleCategoryTransition()
            } else {
                animateSlide()
                updateContent()
            }
        } else {
            calculateScore()
        }
    }

    private func animateSlideLeft() {
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = .push
        transition.subtype = .fromLeft
        view.layer.add(transition, forKey: nil)
    }

    private func animateSlide() {
        let transition = CATransition()
        transition.duration = 0.3
        transition.type = .push
        transition.subtype = .fromRight
        view.layer.add(transition, forKey: nil)
    }

    private func updateContent() {
        categoryLabel.text = questionnaire[currentIndex].cat
        questionLabel.text = questionnaire[currentIndex].q
        pageControl.currentPage = currentIndex
        
        let selectedValue = scores[currentIndex]
        if selectedValue == -1 {
            responseSlider?.value = 0
            valueLabel?.text = "Slide to answer"
            valueLabel?.textColor = .placeholderText
        } else if selectedValue == -2 {
            responseSlider?.value = 0
            valueLabel?.text = "Skipped"
            valueLabel?.textColor = .systemGray
        } else {
            responseSlider?.value = Float(selectedValue)
            valueLabel?.text = options[selectedValue]
            valueLabel?.textColor = UIColor(named: "AccentColor") ?? .systemOrange
        }
        
        let isDailyActivity = (currentIndex >= 8 && currentIndex <= 11)
        skipButton?.isHidden = !isDailyActivity
        skipButton?.alpha = isDailyActivity ? 1.0 : 0.0
        
        updateNavigationButtonsState()
    }
}
