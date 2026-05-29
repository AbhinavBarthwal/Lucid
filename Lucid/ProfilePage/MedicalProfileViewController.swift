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
    private var hostingController: UIHostingController<MedicalProfileView>?
    
    private var originalNavigationBarAppearance: UINavigationBarAppearance?
    private var originalScrollEdgeAppearance: UINavigationBarAppearance?
    private var originalCompactAppearance: UINavigationBarAppearance?
    private var originalTintColor: UIColor?
    private var originalPrefersLargeTitles: Bool = false
    
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.largeTitleDisplayMode = .never
        
        if let navBar = navigationController?.navigationBar {
            originalNavigationBarAppearance = navBar.standardAppearance
            originalScrollEdgeAppearance = navBar.scrollEdgeAppearance
            originalCompactAppearance = navBar.compactAppearance
            originalTintColor = navBar.tintColor
            originalPrefersLargeTitles = navBar.prefersLargeTitles
            
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor.black.withAlphaComponent(0.7)
            appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)
            
            let expandedFont = UIFont.systemFont(ofSize: 20, weight: .bold, width: .expanded)
            appearance.titleTextAttributes = [
                .font: expandedFont,
                .foregroundColor: UIColor.white
            ]
            
            navBar.standardAppearance = appearance
            navBar.scrollEdgeAppearance = appearance
            navBar.compactAppearance = appearance
            navBar.tintColor = .accent
            navBar.prefersLargeTitles = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let navBar = navigationController?.navigationBar {
            navBar.standardAppearance = originalNavigationBarAppearance ?? UINavigationBarAppearance()
            navBar.scrollEdgeAppearance = originalScrollEdgeAppearance
            navBar.compactAppearance = originalCompactAppearance
            navBar.tintColor = originalTintColor
            navBar.prefersLargeTitles = originalPrefersLargeTitles
        }
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
        
        let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        if dob > tenYearsAgo {
            let alert = UIAlertController(
                title: "Just a heads up",
                message: "Lucid is designed for ages 10 and older. We look forward to welcoming you soon!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Got it!", style: .default))
            present(alert, animated: true)
            return
        }
        
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
            let alert = UIAlertController(title: "All saved!", message: nil, preferredStyle: .alert)
            present(alert, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                alert.dismiss(animated: true) {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        } catch {
            let alert = UIAlertController(
                title: "Couldn't save changes",
                message: "We ran into a little trouble saving your changes. Let's try again in a bit.",
                preferredStyle: .alert
            )
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
