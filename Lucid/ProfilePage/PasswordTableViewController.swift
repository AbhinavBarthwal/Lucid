import UIKit

class PasswordTableViewController: UITableViewController {

    @IBOutlet weak var oldPasswordField: UITextField!
    @IBOutlet weak var newPasswordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!


    override func viewDidLoad() {
        super.viewDidLoad()
    }


    @IBAction func saveTapped(_ sender: Any) {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let oldPassword = oldPasswordField.text ?? ""
        let newPassword = newPasswordField.text ?? ""
        let confirmPassword = confirmPasswordField.text ?? ""

        if oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty {
            showAlert(message: "All fields are required")
            return
        }

        if newPassword.count < 8 {
            showAlert(message: "Password must be at least 8 characters")
            return
        }

        if newPassword != confirmPassword {
            showAlert(message: "Passwords do not match")
            return
        }

        let savedPassword = user.password ?? user.email.flatMap { CredentialStore.shared.password(for: $0) } ?? ""
        if !savedPassword.isEmpty, savedPassword != oldPassword {
            showAlert(message: "Old password is incorrect")
            return
        }

        user.password = newPassword
        if let email = user.email, !email.isEmpty {
            _ = CredentialStore.shared.save(password: newPassword, for: email)
        }

        do {
            try SwiftDataManager.shared.context.save()
            Task {
                await SupabaseManager.shared.syncUser(user)
            }
            showAlert(message: "Password changed successfully.")
        } catch {
            showAlert(message: "Could not save your new password right now.")
        }
    }


    func showAlert(message: String) {
        let alert = UIAlertController(title: "Notice", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
