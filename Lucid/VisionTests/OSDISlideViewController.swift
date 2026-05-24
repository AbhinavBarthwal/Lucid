import UIKit

class OSDIViewController: UIViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var responseSlider: UISlider!
    @IBOutlet weak var nextButton: UIButton!

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialState()
    }

    private func setupInitialState() {
        [instructionLabel, questionLabel, valueLabel, responseSlider, nextButton, pageControl, categoryLabel].forEach {
            $0?.alpha = 0
        }
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
        [instructionLabel, questionLabel, valueLabel, responseSlider, nextButton, pageControl].forEach { $0?.alpha = 0 }
        
        categoryLabel.text = questionnaire[currentIndex].cat
        categoryLabel.font = .systemFont(ofSize: 34, weight: .bold)
        categoryLabel.center = view.center
        
        UIView.animate(withDuration: 0.5, animations: {
            self.categoryLabel.alpha = 1.0
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UIView.animate(withDuration: 0.4, animations: {
                    self.categoryLabel.alpha = 0
                }) { _ in
                    self.moveToHeaderAndReveal()
                }
            }
        }
    }

    private func moveToHeaderAndReveal() {
        categoryLabel.font = .systemFont(ofSize: 32, weight: .semibold)
        categoryLabel.center = originalCenter
        
        updateContent()
        
        UIView.animate(withDuration: 0.5) {
            self.categoryLabel.alpha = 1.0
            [self.instructionLabel, self.questionLabel, self.valueLabel, self.responseSlider, self.nextButton, self.pageControl].forEach { $0?.alpha = 1.0 }
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
        
        // New logic: Branch based on whether we should show the UI
        if shouldShowResultUI {
            showResultScreen(score: finalOSDI, severity: severity)
        } else {
            nextButton?.isEnabled = false
            responseSlider?.isEnabled = false
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

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let roundedValue = Int(round(sender.value))
        sender.value = Float(roundedValue)
        valueLabel.text = options[roundedValue]
        scores[currentIndex] = roundedValue
    }

    @IBAction func nextTapped(_ sender: UIButton) {
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
        responseSlider.value = 0
        valueLabel.text = options[0]
    }
}
