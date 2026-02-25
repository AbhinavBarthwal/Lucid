
import UIKit

class OSDIViewController: UIViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var responseSlider: UISlider!
    @IBOutlet weak var nextButton: UIButton!


    private var currentIndex = 0
    private var scores: [Int] = Array(repeating: 0, count: 12)
    private var originalCenter: CGPoint = .zero
    private var FirstLoad = true
    
    private let options = ["None of the time", "Some of the time", "Half of the time", "Most of the time", "All of the time"]
    
    private let questionnaire: [(cat: String, q: String)] = [
        ("Symptoms", "Eyes that are \n sensitive to light?"),
        ("Symptoms", "Eyes that feel gritty?"),
        ("Symptoms", "Painful or sore eyes?"),
        ("Symptoms", "Blurred vision?"),
        ("Vision Functionality", "Problems reading?"),
        ("Vision Functionality", "Driving at night?"),
        ("Vision Functionality", "Working with a computer?"),
        ("Vision Functionality", "Watching TV?"),
        ("Environmental Triggers", "In windy conditions?"),
        ("Environmental Triggers", "In places with low humidity?"),
        ("Environmental Triggers", "In air conditioned areas?"),
        ("Environmental Triggers", "Do you notice redness or stinging \n when you are near traffic,\n dust, or smoke?")
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
        showResultScreen(score: finalOSDI)
    }

    private func showResultScreen(score: Double) {
        var severity = ""
        var color: UIColor = .white
        
        if score <= 12 { severity = "Normal"; color = .systemGreen }
        else if score <= 22 { severity = "Mild"; color = .systemYellow }
        else if score <= 32 { severity = "Moderate"; color = .systemOrange }
        else { severity = "Severe"; color = .systemRed }

        


        let resultView = UIView(frame: self.view.bounds)
        resultView.backgroundColor = UIColor.black.withAlphaComponent(0.95)
        resultView.alpha = 0
        
        let scoreLabel = UILabel()
        scoreLabel.text = "Your OSDI Score: \(Int(score))"
        scoreLabel.textColor = .white
        scoreLabel.font = .systemFont(ofSize: 24, weight: .bold)
        scoreLabel.textAlignment = .center
        
        let severityLabel = UILabel()
        severityLabel.text = severity
        severityLabel.textColor = color
        severityLabel.font = .systemFont(ofSize: 40, weight: .black)
        severityLabel.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [scoreLabel, severityLabel])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        resultView.addSubview(stack)
        self.view.addSubview(resultView)
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: resultView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: resultView.centerYAnchor)
        ])
        
        UIView.animate(withDuration: 0.6) {
            resultView.alpha = 1.0
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
