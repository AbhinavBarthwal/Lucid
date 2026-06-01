import UIKit

class OSDIViewController: UIViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel?
    @IBOutlet weak var responseSlider: UISlider?
    @IBOutlet weak var nextButton: UIButton?

    // MARK: - New Onboarding Properties
    var onTestCompleted: ((Double, String) -> Void)?
    var shouldShowResultUI: Bool = true

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
    }

    private func setupInitialState() {
        categoryLabel?.isHidden = true
        [instructionLabel, questionLabel, pageControl, categoryLabel, neverLabel, mostlyLabel, prevNavButton, nextNavButton, introContainerView].forEach {
            $0?.alpha = 0
        }
        
        // Hide valueLabel as requested by the user
        valueLabel?.isHidden = true
        valueLabel?.alpha = 0
        
        responseSlider?.alpha = 0
        submitButton?.isHidden = false
        submitButton?.alpha = 1
        
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
        
        // Setup navigation button styles - plain text buttons (no background) on a single line
        if #available(iOS 15.0, *) {
            var prevConfig = UIButton.Configuration.plain()
            prevConfig.baseForegroundColor = .lightGray
            
            var prevContainer = AttributeContainer()
            prevContainer.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            prevConfig.attributedTitle = AttributedString("Previous", attributes: prevContainer)
            prevNavButton.configuration = prevConfig
            
            var nextConfig = UIButton.Configuration.plain()
            nextConfig.baseForegroundColor = UIColor(named: "AccentColor") ?? .systemOrange
            
            var nextContainer = AttributeContainer()
            nextContainer.font = UIFont.systemFont(ofSize: 18, weight: .bold)
            nextConfig.attributedTitle = AttributedString("Next", attributes: nextContainer)
            nextNavButton.configuration = nextConfig
        } else {
            prevNavButton.backgroundColor = .clear
            prevNavButton.setTitleColor(.lightGray, for: .normal)
            prevNavButton.setTitle("Previous", for: .normal)
            prevNavButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
            
            nextNavButton.backgroundColor = .clear
            nextNavButton.setTitleColor(UIColor(named: "AccentColor") ?? .systemOrange, for: .normal)
            nextNavButton.setTitle("Next", for: .normal)
            nextNavButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        }
        
        // Deactivate width constraints programmatically so titles don't wrap and display on a single line
        for button in [prevNavButton, nextNavButton] {
            button?.constraints.forEach { constraint in
                if constraint.firstAttribute == .width {
                    constraint.isActive = false
                }
            }
            button?.superview?.constraints.forEach { constraint in
                if (constraint.firstItem === button || constraint.secondItem === button) && constraint.firstAttribute == .width {
                    constraint.isActive = false
                }
            }
        }
        
        // Setup Navigation Actions
        prevNavButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextNavButton.addTarget(self, action: #selector(customNextTapped), for: .touchUpInside)
        
        // Setup Submit button
        setupSubmitButton()
        
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
            handleCategoryTransition()
            FirstLoad = false
        }
    }

    private func handleCategoryTransition() {
        // Fade out all main UI elements during category/section transition
        [questionLabel, pageControl, neverLabel, mostlyLabel, prevNavButton, nextNavButton, categoryLabel, instructionLabel, skipButton].forEach { $0?.alpha = 0 }
        responseSlider?.alpha = 0
        responseSlider?.isHidden = true
        tickContainerView?.alpha = 0
        tickContainerView?.isHidden = true
        valueLabel?.alpha = 0
        submitButton?.alpha = 0
        
        introCategoryLabel.text = questionnaire[currentIndex].cat
        
        let sectionInstruction: String
        switch questionnaire[currentIndex].cat {
        case "How your eyes feel":
            sectionInstruction = "Have your eyes felt any of this in the past week?"
        case "Your surroundings":
            sectionInstruction = "Have your eyes felt uncomfortable in these places recently?"
        case "Daily activities":
            sectionInstruction = "Have these everyday things been harder because of your eyes? (You can skip these if they don't apply to you)"
        default:
            sectionInstruction = "Have your eyes felt this way over the past week?"
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
            
            if self.currentIndex == self.questionnaire.count - 1 {
                self.submitButton?.alpha = 1.0
            }
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
    
    private var submitButton: UIButton?

    private func setupSubmitButton() {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        
        let orangeColor = UIColor(named: "AccentColor") ?? .systemOrange
        btn.setTitle("Submit", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        btn.setTitleColor(.white, for: .normal)
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.title = "Submit"
            config.baseBackgroundColor = orangeColor
            config.baseForegroundColor = .white
            config.cornerStyle = .capsule
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 24, weight: .bold)
                return outgoing
            }
            btn.configuration = config
        } else {
            btn.backgroundColor = orangeColor
            btn.setTitleColor(.white, for: .normal)
            btn.layer.cornerRadius = 14
        }
        
        view.addSubview(btn)
        self.submitButton = btn
        btn.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            btn.trailingAnchor.constraint(equalTo: nextNavButton!.trailingAnchor),
            btn.bottomAnchor.constraint(equalTo: nextNavButton!.bottomAnchor),
            btn.topAnchor.constraint(equalTo: nextNavButton!.topAnchor),
            btn.leadingAnchor.constraint(equalTo: nextNavButton!.leadingAnchor)
        ])
        
        btn.isHidden = true
    }
    
    @objc private func submitTapped() {
        calculateScore()
    }
    
    private func updateNavigationButtonsState() {
        let isAnswered = scores[currentIndex] != -1
        
        prevNavButton.isHidden = (currentIndex == 0)
        
        if currentIndex == questionnaire.count - 1 {
            nextNavButton?.isHidden = true
            submitButton?.isHidden = false
            
            submitButton?.isEnabled = isAnswered
            submitButton?.alpha = isAnswered ? 1.0 : 0.3
        } else {
            nextNavButton?.isHidden = false
            submitButton?.isHidden = true
            
            nextNavButton?.isEnabled = true
            nextNavButton?.alpha = 1.0
        }
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
