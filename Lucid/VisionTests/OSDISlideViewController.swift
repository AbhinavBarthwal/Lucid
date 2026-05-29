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
    private var scores: [Int] = Array(repeating: -1, count: 12)
    private var originalCenter: CGPoint = .zero
    private var FirstLoad = true
    private var didComplete = false
    
    private let options = ["None of the time", "Some of the time", "Half of the time", "Most of the time", "All of the time"]
    
    private let questionnaire: [(cat: String, q: String)] = [
        ("How your eyes feel", "Do bright lights or sunlight bother your eyes?"),
        ("How your eyes feel", "Eyes feeling like they  have dust in them?"),
        ("How your eyes feel", "Eyes feeling sore, stinging, or burning?"),
        ("How your eyes feel", "Vision getting hazy or out of focus?"),
        
        ("Daily activities", "Hard to read books  or long phone messages?"),
        ("Daily activities", "Difficulty driving at night due to headlight glare?"),
        ("Daily activities", "Trouble using your smartphone, laptop, or an ATM?"),
        ("Daily activities", "Eyes getting tired while watching a movie or a match?"),
        
        ("Your surroundings", "Discomfort when it's windy or while riding a bike?"),
        ("Your surroundings", "Eyes feeling 'too dry' during peak summer?"),
        ("Your surroundings", "Dryness in AC rooms  or in front of a cooler or fan?"),
        ("Your surroundings", "Redness or stinging when near heavy traffic, dust, or smoke?")
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
        
        // Make sure valueLabel is unhidden, but its alpha is 0
        valueLabel?.isHidden = false
        valueLabel?.alpha = 0
        
        responseSlider?.alpha = 0
        submitButton?.isHidden = true
        submitButton?.alpha = 0
        
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
        
        view.addSubview(slider)
        self.responseSlider = slider
        
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        
        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: circleStackView.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: circleStackView.trailingAnchor),
            slider.centerYAnchor.constraint(equalTo: circleStackView.centerYAnchor),
            slider.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        setupSliderTicks(slider: slider)
        
        // Capitalize labels and increase font size to 22 bold
        neverLabel.text = "Never"
        neverLabel.textColor = .lightGray
        neverLabel.font = .systemFont(ofSize: 22, weight: .bold)
        
        mostlyLabel.text = "Mostly"
        mostlyLabel.textColor = .lightGray
        mostlyLabel.font = .systemFont(ofSize: 22, weight: .bold)
        
        // Setup Orange navigation button colors
        let orangeColor = UIColor(named: "AccentColor") ?? .systemOrange
        prevNavButton.setTitleColor(orangeColor, for: .normal)
        nextNavButton.setTitleColor(orangeColor, for: .normal)
        if #available(iOS 15.0, *) {
            prevNavButton.configuration?.baseForegroundColor = orangeColor
            nextNavButton.configuration?.baseForegroundColor = orangeColor
        }
        
        // Setup Navigation Actions
        prevNavButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextNavButton.addTarget(self, action: #selector(customNextTapped), for: .touchUpInside)
        
        // Setup Submit button
        setupSubmitButton()
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
        [questionLabel, pageControl, neverLabel, mostlyLabel, prevNavButton, nextNavButton, categoryLabel, instructionLabel].forEach { $0?.alpha = 0 }
        responseSlider?.alpha = 0
        tickContainerView?.alpha = 0
        valueLabel?.alpha = 0
        submitButton?.alpha = 0
        
        introCategoryLabel.text = questionnaire[currentIndex].cat
        
        let sectionInstruction: String
        switch questionnaire[currentIndex].cat {
        case "How your eyes feel":
            sectionInstruction = "Have your eyes felt any of these in the past week?"
        case "Daily activities":
            sectionInstruction = "Have your eyes found it tricky to do these things lately?"
        case "Your surroundings":
            sectionInstruction = "Have your eyes felt a bit uncomfortable in these spaces?"
        default:
            sectionInstruction = "Have your eyes felt this way over the past week?"
        }
        introInstructionLabel.text = sectionInstruction
        
        // Fade intro category & instruction in the middle of the screen
        UIView.animate(withDuration: 0.5, animations: {
            self.introContainerView.alpha = 1.0
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
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
            self.responseSlider?.alpha = 1.0
            self.tickContainerView?.alpha = 1.0
            self.valueLabel?.alpha = 1.0
            if self.currentIndex == self.questionnaire.count - 1 {
                self.submitButton?.alpha = 1.0
            }
        }
    }

    private func calculateScore() {
        let sum = scores.reduce(0, +)
        let finalOSDI = (Double(sum) * 25.0) / 12.0
        
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
        view.insertSubview(tickContainer, belowSubview: slider)
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
            dot.backgroundColor = .lightGray.withAlphaComponent(0.6)
            dot.layer.cornerRadius = 3
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
                dot.widthAnchor.constraint(equalToConstant: 6),
                dot.heightAnchor.constraint(equalToConstant: 6),
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
        btn.setTitleColor(orangeColor, for: .normal)
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.title = "Submit"
            config.baseForegroundColor = orangeColor
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 24, weight: .bold)
                return outgoing
            }
            btn.configuration = config
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
            
            nextNavButton?.isEnabled = isAnswered
            nextNavButton?.alpha = isAnswered ? 1.0 : 0.3
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
        } else {
            responseSlider?.value = Float(selectedValue)
            valueLabel?.text = options[selectedValue]
            valueLabel?.textColor = UIColor(named: "AccentColor") ?? .systemOrange
        }
        
        updateNavigationButtonsState()
    }
}
