import UIKit

class SetGoalViewController: UIViewController {


    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!

    var minutes: Int = 10   // default value


    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadSavedGoal()
        updateUI()
    }


    func setupUI() {
        minutesLabel.font = UIFont.systemFont(ofSize: 50, weight: .bold)
        
        plusButton.layer.cornerRadius = plusButton.frame.height / 2
        minusButton.layer.cornerRadius = minusButton.frame.height / 2
        
        plusButton.clipsToBounds = true
        minusButton.clipsToBounds = true
    }


    private var minMinutes: Int {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let recommendedSeconds = user.calculateDailyGoalFromRecommendations()
        let recommendedMinutes = Int(floor(Double(recommendedSeconds) / 60.0))
        return max(1, recommendedMinutes)
    }

    func updateUI() {
        minutesLabel.text = "\(minutes)"
        
        let limitMin = minMinutes
        minusButton.isEnabled = minutes > limitMin
        plusButton.isEnabled = minutes < 30
        
        minusButton.alpha = minutes > limitMin ? 1.0 : 0.3
        plusButton.alpha = minutes < 30 ? 1.0 : 0.3
    }

    @IBAction func increaseTapped(_ sender: UIButton) {
        if minutes < 30 {
            minutes += 2
            
            if minutes > 30 { minutes = 30 }
            
            animateLabel()
            updateUI()
            haptic()
        }
    }

    @IBAction func decreaseTapped(_ sender: UIButton) {
        let limitMin = minMinutes
        if minutes > limitMin {
            minutes -= 2
            
            if minutes < limitMin { minutes = limitMin }
            
            animateLabel()
            updateUI()
            haptic()
        }
    }

    @IBAction func changeGoalTapped(_ sender: UIButton) {

        UserDefaults.standard.set(minutes, forKey: "exerciseGoal")

        ExerciseDataManager.shared.updateDailyGoal(newGoalInSeconds: minutes*60)
        
        showAlert()
    }

    func loadSavedGoal() {
        let saved = UserDefaults.standard.integer(forKey: "exerciseGoal")
        let limitMin = minMinutes
        
        if saved >= limitMin && saved <= 30 {
            minutes = saved
        } else {
            minutes = limitMin
        }
    }

    func animateLabel() {
        UIView.animate(withDuration: 0.1, animations: {
            self.minutesLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.minutesLabel.transform = .identity
            }
        }
    }

    func haptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    func showAlert() {
        let alert = UIAlertController(
            title: "Goal Updated.",
            message: "Your daily exercise goal is now \(minutes) minutes/day",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
