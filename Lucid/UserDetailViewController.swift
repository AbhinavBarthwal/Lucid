import UIKit

class UserDetailViewController: UITableViewController {

    // MARK: - Profile Image
    @IBOutlet weak var profileImageView: UIImageView!
    
    // MARK: - Eye Fields
    @IBOutlet weak var leftEyeField: UITextField!
    @IBOutlet weak var rightEyeField: UITextField!
    
    // MARK: - Steppers
    @IBOutlet weak var leftStepper: UIStepper!
    @IBOutlet weak var rightStepper: UIStepper!
    
    // MARK: - Conditions Container
    @IBOutlet weak var conditionsStackView: UIStackView!
    
    // MARK: - Variables
    var selectedConditions: [String] = []
    
    
    // MARK: - View Load
    override func viewDidLoad() {
        super.viewDidLoad()

        setupProfileImage()
        setupSteppers()
    }
    
    
    // MARK: - Circular Profile Image
    func setupProfileImage() {
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        profileImageView.clipsToBounds = true
        
        profileImageView.layer.borderWidth = 2
        profileImageView.layer.borderColor = UIColor.systemGray5.cgColor
    }
    
    
    // MARK: - Setup Steppers
    func setupSteppers() {
        
        // Left Eye Stepper
        leftStepper.minimumValue = -10
        leftStepper.maximumValue = 10
        leftStepper.stepValue = 0.25
        leftStepper.value = 0
        
        // Right Eye Stepper
        rightStepper.minimumValue = -10
        rightStepper.maximumValue = 10
        rightStepper.stepValue = 0.25
        rightStepper.value = 0
        
        // Initial Text
        leftEyeField.text = "0.00"
        rightEyeField.text = "0.00"
    }
    
    
    // MARK: - Left Eye Stepper
    @IBAction func leftStepperChanged(_ sender: UIStepper) {
        
        let value = sender.value
        leftEyeField.text = String(format: "%.2f", value)
    }
    
    
    // MARK: - Right Eye Stepper
    @IBAction func rightStepperChanged(_ sender: UIStepper) {
        
        let value = sender.value
        print(value)
        rightEyeField.text = String(format: "%.2f", value)
    }
    
    
    // MARK: - Update Previous Conditions
    func updateConditions(_ conditions: [String]) {
        
        selectedConditions = conditions
        
        // Remove old tags
        conditionsStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        
        // Add new condition tags
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
    
    
    // MARK: - Fix Circle Layout
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

extension UserDetailViewController: PreviousConditionsDelegate {
    
    func didSelectConditions(_ conditions: [String]) {
        updateConditions(conditions)
    }
}
