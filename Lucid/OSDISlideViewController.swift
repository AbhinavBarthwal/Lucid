//import UIKit
//
//class OSDIViewController: UIViewController {
//
//    // MARK: - Outlets
//    @IBOutlet weak var pageControl: UIPageControl!
//    @IBOutlet weak var categoryLabel: UILabel!
//    @IBOutlet weak var instructionLabel: UILabel!
//    @IBOutlet weak var questionLabel: UILabel!
//    @IBOutlet weak var valueLabel: UILabel!
//    @IBOutlet weak var responseSlider: UISlider!
//    @IBOutlet weak var nextButton: UIButton!
//
//    // MARK: - Properties
//    private var currentIndex = 0
//    private var scores: [Int] = Array(repeating: 0, count: 12)
//    private var originalCategoryCenter: CGPoint = .zero
//    private var isFirstLoad = true // PREVENTS REFRESH ANIMATION
//    
//    private let options = ["None of the time", "Some of the time", "Half of the time", "Most of the time", "All of the time"]
//    
//    private let questionnaire: [(cat: String, q: String)] = [
//        ("Symptoms", "Eyes that are\nsensitive to light?"), ("Symptoms", "Eyes that feel gritty?"),
//        ("Symptoms", "Painful or sore eyes?"), ("Symptoms", "Blurred vision?"), ("Symptoms", "Poor vision?"),
//        ("Vision Functionality", "Problems reading?"), ("Vision Functionality", "Driving at night?"),
//        ("Vision Functionality", "Working with a computer?"), ("Vision Functionality", "Watching TV?"),
//        ("Environmental Triggers", "In windy conditions?"), ("Environmental Triggers", "In places with low humidity?"),
//        ("Environmental Triggers", "In air conditioned areas?")
//    ]
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        // Capture the top position only once
//        if isFirstLoad {
//            originalCategoryCenter = categoryLabel.center
//            handleCategoryTransition()
//            isFirstLoad = false // Mark as finished so it doesn't refresh on scroll
//        }
//    }
//
//    private func setupUI() {
//        view.backgroundColor = UIColor(white: 0.07, alpha: 1.0)
//        nextButton.layer.cornerRadius = 25
//        
//        // Initial state: Everything hidden
//        [pageControl, instructionLabel, questionLabel, valueLabel, responseSlider, nextButton].forEach {
//            $0?.alpha = 0
//        }
//        categoryLabel.alpha = 0
//    }
//
//    private func handleCategoryTransition() {
//        // 1. Hide UI elements
//        UIView.animate(withDuration: 0.3) {
//            [self.instructionLabel, self.questionLabel, self.valueLabel, self.responseSlider, self.nextButton, self.pageControl].forEach { $0?.alpha = 0 }
//            self.categoryLabel.alpha = 0
//        }
//        
//        // 2. Setup Center Splash
//        let currentCat = questionnaire[currentIndex].cat
//        categoryLabel.text = currentCat
//        categoryLabel.font = .systemFont(ofSize: 32, weight: .bold)
//        categoryLabel.center = view.center
//        
//        
//        
//        // 3. Play Splash
//        UIView.animate(withDuration: 1.0, animations: {
//            self.categoryLabel.alpha = 1.0
//        }) { _ in
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
//                UIView.animate(withDuration: 0.8, animations: {
//                    self.categoryLabel.alpha = 0
//                }) { _ in
//                    self.moveToHeaderAndReveal()
//                }
//            }
//        }
//    }
//
//    private func moveToHeaderAndReveal() {
//        // Reset to Header position
//        self.categoryLabel.font = .systemFont(ofSize: 18, weight: .semibold)
//        self.categoryLabel.center = self.originalCategoryCenter
//        self.updateContent()
//        
//        UIView.animate(withDuration: 0.6) {
//            self.categoryLabel.alpha = 1.0
//            [self.pageControl, self.instructionLabel, self.questionLabel, self.valueLabel,
//             self.responseSlider, self.nextButton].forEach { $0?.alpha = 1.0 }
//        }
//    }
//
//    @IBAction func sliderValueChanged(_ sender: UISlider) {
//        let roundedValue = Int(round(sender.value))
//        let safeIndex = max(0, min(roundedValue, options.count - 1))
//        sender.value = Float(safeIndex)
//        valueLabel.text = options[safeIndex]
//        scores[currentIndex] = safeIndex
//    }
//
//    @IBAction func nextTapped(_ sender: UIButton) {
//        if currentIndex < questionnaire.count - 1 {
//            let oldCategory = questionnaire[currentIndex].cat
//            currentIndex += 1
//            let newCategory = questionnaire[currentIndex].cat
//            
//            if oldCategory != newCategory {
//                handleCategoryTransition() // Only animate if category changed
//            } else {
//                animateSlide()
//                updateContent()
//            }
//        } else {
//            calculateFinalScore()
//        }
//    }
//
//    private func updateContent() {
//        let data = questionnaire[currentIndex]
//        categoryLabel.text = data.cat
//        questionLabel.text = data.q
//        pageControl.currentPage = currentIndex
//        responseSlider.value = 0
//        valueLabel.text = options[0]
//    }
//
//    private func animateSlide() {
//        let transition = CATransition()
//        transition.duration = 0.4
//        transition.type = .push
//        transition.subtype = .fromRight
//        view.layer.add(transition, forKey: nil)
//    }
//
//    private func calculateFinalScore() {
//        let sum = scores.reduce(0, +)
//        let score = (Double(sum) * 25.0) / 12.0
//        print("Final OSDI Score: \(score)")
//    }
//}
import UIKit

class OSDIViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel! // ADDED BACK
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var responseSlider: UISlider!
    @IBOutlet weak var nextButton: UIButton!

    // MARK: - Data
    private var currentIndex = 0
    private var scores: [Int] = Array(repeating: 0, count: 12)
    private var originalCategoryCenter: CGPoint = .zero
    private var isFirstLoad = true
    
    private let options = ["None of the time", "Some of the time", "Half of the time", "Most of the time", "All of the time"]
    
    private let questionnaire: [(cat: String, q: String)] = [
        ("Symptoms", "Eyes that are\nsensitive to light?"), ("Symptoms", "Eyes that feel gritty?"),
        ("Symptoms", "Painful or sore eyes?"), ("Symptoms", "Blurred vision?"), ("Symptoms", "Poor vision?"),
        ("Vision Functionality", "Problems reading?"), ("Vision Functionality", "Driving at night?"),
        ("Vision Functionality", "Working with a computer?"), ("Vision Functionality", "Watching TV?"),
        ("Environmental Triggers", "In windy conditions?"), ("Environmental Triggers", "In places with low humidity?"),
        ("Environmental Triggers", "In air conditioned areas?")
    ]

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstLoad {
            originalCategoryCenter = categoryLabel.center
            handleCategoryTransition()
            isFirstLoad = false
        }
    }

    private func handleCategoryTransition() {
        // Hide all question UI elements including the instruction label
        [instructionLabel, questionLabel, valueLabel, responseSlider, nextButton, pageControl].forEach { $0?.alpha = 0 }
        
        categoryLabel.text = questionnaire[currentIndex].cat
        
        
        UIView.animate(withDuration: 1.0, animations: {
            self.categoryLabel.alpha = 1.0
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                UIView.animate(withDuration: 0.8, animations: {
                    self.categoryLabel.alpha = 0
                }) { _ in
                    self.moveToHeaderAndReveal()
                }
            }
        }
    }

    private func moveToHeaderAndReveal() {
        
        updateContent()
        
        UIView.animate(withDuration: 0.6) {
            self.categoryLabel.alpha = 1.0
            // Reveal everything back
            [self.instructionLabel, self.questionLabel, self.valueLabel, self.responseSlider, self.nextButton, self.pageControl].forEach { $0?.alpha = 1.0 }
        }
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let roundedValue = Int(round(sender.value))
        let safeIndex = max(0, min(roundedValue, options.count - 1))
        sender.value = Float(safeIndex)
        valueLabel.text = options[safeIndex]
        scores[currentIndex] = safeIndex
    }

    @IBAction func nextTapped(_ sender: UIButton) {
        if currentIndex < questionnaire.count - 1 {
            let oldCat = questionnaire[currentIndex].cat
            currentIndex += 1
            if oldCat != questionnaire[currentIndex].cat {
                handleCategoryTransition()
            } else {
                let transition = CATransition()
                transition.duration = 0.3
                transition.type = .push
                transition.subtype = .fromRight
                view.layer.add(transition, forKey: nil)
                updateContent()
            }
        } else {
            calculateScore()
        }
    }

    private func updateContent() {
        categoryLabel.text = questionnaire[currentIndex].cat
        questionLabel.text = questionnaire[currentIndex].q
        pageControl.currentPage = currentIndex
        responseSlider.value = 0
        valueLabel.text = options[0]
    }

    private func calculateScore() {
        let sum = scores.reduce(0, +)
        let finalOSDI = (Double(sum) * 25.0) / 12.0
        print("Final OSDI Score: \(finalOSDI)")
    }
}
