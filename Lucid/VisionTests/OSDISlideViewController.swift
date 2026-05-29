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
        ("Symptoms", "Do bright lights or sunlight bother your eyes?"),
        ("Symptoms", "Eyes feeling like they  have dust or in them?"),
        ("Symptoms", "Eyes feeling sore, stinging, or burning?"),
        ("Symptoms", "Vision getting hazy or out of focus?"),
        
        ("Vision Functionality", "Hard to read books  or long phone messages?"),
        ("Vision Functionality", "Difficulty driving at night due to headlight glare?"),
        ("Vision Functionality", "Trouble using your smartphone, laptop, or an ATM?"),
        ("Vision Functionality", "Eyes getting tired while watching a movie or a match?"),
        
        ("Environmental Triggers", "Discomfort when it's windy or while riding a bike?"),
        ("Environmental Triggers", "Eyes feeling 'too dry' during peak summer?"),
        ("Environmental Triggers", "Dryness in AC rooms  or in front of a cooler or fan?"),
        ("Environmental Triggers", "Redness or stinging when near heavy traffic, dust, or smoke?")
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
        [instructionLabel, questionLabel, pageControl, categoryLabel, neverLabel, mostlyLabel, circleStackView, prevNavButton, nextNavButton, introContainerView].forEach {
            $0?.alpha = 0
        }
        responseSlider?.isHidden = true
        valueLabel?.isHidden = true
        nextButton?.isHidden = true
    }

    private func setupCustomUI() {
        // Retrieve circular buttons configured in storyboard
        circleButtons = circleStackView.arrangedSubviews.compactMap { $0 as? UIButton }
        
        for i in 0..<circleButtons.count {
            let btn = circleButtons[i]
            btn.tag = i
            btn.layer.cornerRadius = 22 // Diameter 44x44
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.lightGray.cgColor
            btn.backgroundColor = .clear
            btn.setTitle("", for: .normal)
            
            // Set up target action
            btn.addTarget(self, action: #selector(circleTapped(_:)), for: .touchUpInside)
        }
        
        neverLabel.text = "never"
        neverLabel.textColor = .lightGray
        neverLabel.font = .systemFont(ofSize: 14, weight: .medium)
        
        mostlyLabel.text = "mostly"
        mostlyLabel.textColor = .lightGray
        mostlyLabel.font = .systemFont(ofSize: 14, weight: .medium)
        
        // Setup Navigation Actions
        prevNavButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextNavButton.addTarget(self, action: #selector(customNextTapped), for: .touchUpInside)
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
        [questionLabel, pageControl, neverLabel, mostlyLabel, circleStackView, prevNavButton, nextNavButton, categoryLabel, instructionLabel].forEach { $0?.alpha = 0 }
        
        introCategoryLabel.text = questionnaire[currentIndex].cat
        
        let sectionInstruction: String
        switch questionnaire[currentIndex].cat {
        case "Symptoms":
            sectionInstruction = "Have you experienced any of the following during the last week?"
        case "Vision Functionality":
            sectionInstruction = "Have you experienced problems with your eyes during the last week when performing the following activities?"
        case "Environmental Triggers":
            sectionInstruction = "Have your eyes felt uncomfortable in the following situations during the last week?"
        default:
            sectionInstruction = "Have you experienced this problem during the last week?"
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
            self.categoryLabel.alpha = 1.0
            self.instructionLabel.alpha = 0 // Hide section instructions from the top during questions
            [self.questionLabel, self.neverLabel, self.mostlyLabel, self.circleStackView, self.prevNavButton, self.nextNavButton, self.pageControl].forEach { $0?.alpha = 1.0 }
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

    @objc private func circleTapped(_ sender: UIButton) {
        let selectedValue = sender.tag
        scores[currentIndex] = selectedValue
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        // Update highlight states
        updateCircleHighlightStates()
        
        // Enable Next button
        nextNavButton.isEnabled = true
        nextNavButton.alpha = 1.0
    }
    
    private func updateCircleHighlightStates() {
        let selectedValue = scores[currentIndex]
        for i in 0..<5 {
            let btn = circleButtons[i]
            if i == selectedValue {
                btn.backgroundColor = UIColor(red: 1.0, green: 0.5, blue: 0.15, alpha: 1.0) // Accent orange
                btn.layer.borderColor = UIColor(red: 1.0, green: 0.5, blue: 0.15, alpha: 1.0).cgColor
            } else {
                btn.backgroundColor = .clear
                btn.layer.borderColor = UIColor.lightGray.cgColor
            }
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
        
        updateCircleHighlightStates()
        
        let selectedValue = scores[currentIndex]
        if selectedValue == -1 {
            nextNavButton.isEnabled = false
            nextNavButton.alpha = 0.3
        } else {
            nextNavButton.isEnabled = true
            nextNavButton.alpha = 1.0
        }
        
        prevNavButton.isHidden = (currentIndex == 0)
    }
}
