import UIKit
import SwiftData

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


    func updateUI() {
        minutesLabel.text = "\(minutes)"
        
        
        minusButton.isEnabled = minutes > 10
        plusButton.isEnabled = minutes < 30
        
        minusButton.alpha = minutes > 10 ? 1.0 : 0.3
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
        if minutes > 10 {
            minutes -= 2
            
            if minutes < 10 { minutes = 10 }
            
            animateLabel()
            updateUI()
            haptic()
        }
    }

    @IBAction func changeGoalTapped(_ sender: UIButton) {
        let user = SwiftDataManager.shared.getCurrentUser()
            
            let seconds = minutes * 60
            user.dailyExerciseGoal = seconds
            
            do {
                try SwiftDataManager.shared.context.save()
            } catch {
                print("❌ Failed to save goal:", error)
            }
            
            showAlert()
    }

    func loadSavedGoal() {
        let user = SwiftDataManager.shared.getCurrentUser()
           
           let savedMinutes = user.dailyExerciseGoal / 60
           
           if savedMinutes >= 10 && savedMinutes <= 30 {
               minutes = savedMinutes
           } else {
               minutes = 10
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
