import UIKit

class MedicalProfileViewController: UITableViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var leftEyeField: UITextField!
    @IBOutlet weak var rightEyeField: UITextField!
    @IBOutlet weak var leftStepper: UIStepper!
    @IBOutlet weak var rightStepper: UIStepper!
    @IBOutlet weak var conditionsStackView: UIStackView!
    
    @IBOutlet weak var genderButton: UIButton!
    
    var selectedConditions: [String] = []
    var selectedGender: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupProfileImage()
        setupSteppers()
        setupGenderMenu()
        loadSavedGender()
    }
    
    func setupProfileImage() {
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = profileImageView.frame.height / 2
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.systemGray5.cgColor
        profileImageView.contentMode = .scaleAspectFill
    }
    
    func setupSteppers() {
        
        leftStepper.minimumValue = -10
        leftStepper.maximumValue = 10
        leftStepper.stepValue = 0.25
        leftStepper.value = 0
        
        rightStepper.minimumValue = -10
        rightStepper.maximumValue = 10
        rightStepper.stepValue = 0.25
        rightStepper.value = 0
        
        leftEyeField.text = "0.00"
        rightEyeField.text = "0.00"
    }

    
    @IBAction func leftStepperChanged(_ sender: UIStepper) {
        leftEyeField.text = String(format: "%.2f", sender.value)
    }

    @IBAction func rightStepperChanged(_ sender: UIStepper) {
        rightEyeField.text = String(format: "%.2f", sender.value)
    }
    
    func setupGenderMenu() {
        
        let current = UserDefaults.standard.string(forKey: "userGender")

        let male = UIAction(
            title: "Female",
            state: current == "Female" ? .on : .off
        ) { _ in
            self.selectGender("Female")
        }

        let female = UIAction(
            title: "Male",
            state: current == "Male" ? .on : .off
        ) { _ in
            self.selectGender("Male")
        }

        let preferNot = UIAction(
            title: "Prefer not to say",
            state: current == "Prefer not to say" ? .on : .off
        ) { _ in
            self.selectGender("Prefer not to say")
        }

        let menu = UIMenu(title: "Select Gender", children: [male, female, preferNot])

        genderButton.menu = menu
        genderButton.showsMenuAsPrimaryAction = true
    }
    
        func selectGender(_ gender: String) {
            selectedGender = gender
            
            // Simple text update (no animation)
            genderButton.setTitle(gender, for: .normal)
            
            // Save only (no UI reload here)
            UserDefaults.standard.set(gender, forKey: "userGender")
        }
    
    func loadSavedGender() {
        if let saved = UserDefaults.standard.string(forKey: "userGender") {
            selectedGender = saved
            genderButton.setTitle(saved, for: .normal)
        } else {
            genderButton.setTitle("Select", for: .normal)
        }
    }
    
    func updateConditions(_ conditions: [String]) {
        
        selectedConditions = conditions
        
        conditionsStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        
        for condition in selectedConditions {
            
            let label = UILabel()
            label.text = " \(condition) "
            label.font = UIFont.systemFont(ofSize: 14)
            label.backgroundColor = UIColor.systemGray5
            label.textColor = .label
            label.layer.cornerRadius = 10
            label.clipsToBounds = true
            
            conditionsStackView.addArrangedSubview(label)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupProfileImage()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PreviousConditionsViewController {
            vc.delegate = self
        }
    }
}

extension MedicalProfileViewController: PreviousConditionsDelegate {
    func didSelectConditions(_ conditions: [String]) {
        updateConditions(conditions)
    }
}
