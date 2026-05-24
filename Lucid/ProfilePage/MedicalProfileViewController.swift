import UIKit
import SwiftUI
internal import Combine

class MedicalProfileDataModel: ObservableObject {
    @Published var name: String = ""
    @Published var dateOfBirth: Date = Date()
    @Published var gender: String = "Prefer not to say"
    @Published var leftPower: Double = 0.0
    @Published var rightPower: Double = 0.0
    @Published var selectedConditions: Set<String> = []
}

class MedicalProfileViewController: UITableViewController {
    
    // Keep outlets so storyboard connections don't break or crash
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var dateOfBirthPicker: UIDatePicker!
    @IBOutlet weak var leftEyeField: UITextField!
    @IBOutlet weak var rightEyeField: UITextField!
    @IBOutlet weak var leftStepper: UIStepper!
    @IBOutlet weak var rightStepper: UIStepper!
    @IBOutlet weak var conditionsStackView: UIStackView!
    @IBOutlet weak var genderButton: UIButton!
    
    private var user: User?
    private let dataModel = MedicalProfileDataModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let currentUser = SwiftDataManager.shared.getOrCreateUser()
        user = currentUser
        
        // Populate model from DB
        dataModel.name = currentUser.name
        dataModel.dateOfBirth = currentUser.dateOfBirth ?? Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
        dataModel.gender = currentUser.gender ?? "Prefer not to say"
        dataModel.leftPower = currentUser.leftEyePower
        dataModel.rightPower = currentUser.rightEyePower
        dataModel.selectedConditions = Set(currentUser.previousConditions)
        
        setupSwiftUI()
        
        // Add navigation bar Save button
        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(saveTapped))
        saveButton.tintColor = .accent
        navigationItem.rightBarButtonItem = saveButton
    }
    
    @objc private func saveTapped() {
        saveData(
            name: dataModel.name,
            dob: dataModel.dateOfBirth,
            gender: dataModel.gender,
            left: dataModel.leftPower,
            right: dataModel.rightPower,
            conditions: Array(dataModel.selectedConditions)
        )
    }
    
    private func setupSwiftUI() {
        // Disable standard table view separators and scrolling
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(red: 10/255, green: 10/255, blue: 12/255, alpha: 1)
        
        // Hide the navigation bar background to make it clean
        navigationController?.navigationBar.tintColor = .accent
        
        let swiftUIView = MedicalProfileView(model: dataModel)
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        addChild(hostingController)
        tableView.backgroundView = hostingController.view
        hostingController.didMove(toParent: self)
    }
    
    // MARK: - Table View Data Source Overrides
    // Returning 0 sections/rows completely disables the legacy storyboard table structure,
    // preventing any duplicate text labels or section headers from rendering behind the SwiftUI view.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    private func saveData(name: String, dob: Date, gender: String, left: Double, right: Double, conditions: [String]) {
        guard let user = user else { return }
        
        user.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        user.dateOfBirth = dob
        user.age = Self.computeAge(from: dob)
        user.gender = gender
        user.leftEyePower = left
        user.rightEyePower = right
        user.previousConditions = conditions
        
        do {
            try SwiftDataManager.shared.context.save()
            Task {
                await SupabaseManager.shared.syncUser(user)
            }
            let alert = UIAlertController(title: "Saved", message: nil, preferredStyle: .alert)
            present(alert, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                alert.dismiss(animated: true) {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        } catch {
            let alert = UIAlertController(title: "Couldn’t Save", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private static func computeAge(from dateOfBirth: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return max(0, components.year ?? 0)
    }
}
