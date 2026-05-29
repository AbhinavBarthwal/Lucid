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
            showAlert(message: "Please fill in all the password fields to continue!")
            return
        }

        if newPassword.count < 8 {
            showAlert(message: "Let's make sure your new password is at least 8 characters long for safety.")
            return
        }

        if newPassword != confirmPassword {
            showAlert(message: "Oops, the passwords you typed don't match. Could you check them again?")
            return
        }

        let savedPassword = user.password ?? user.email.flatMap { CredentialStore.shared.password(for: $0) } ?? ""
        if !savedPassword.isEmpty, savedPassword != oldPassword {
            showAlert(message: "The old password you entered doesn't seem to match our records. Please try again!")
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
            showAlert(message: "All done! Your password has been successfully updated.")
        } catch {
            showAlert(message: "We ran into a little trouble updating your password. Please try again in a moment!")
        }
    }


    func showAlert(message: String) {
        let alert = UIAlertController(title: "Just a heads up", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
        present(alert, animated: true)
    }
}
