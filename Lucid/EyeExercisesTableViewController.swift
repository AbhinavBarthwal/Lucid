import UIKit

class EyeExercisesTableViewController: UITableViewController {
    func addGradientToBackground() {
        let backgroundView = UIView(frame: tableView.bounds)
        let gradientLayer = CAGradientLayer()
        
        // Use the screen bounds for full background
        gradientLayer.frame = UIScreen.main.bounds
        gradientLayer.colors = [
            UIColor(red: 0.05, green: 0.02, blue: 0.12, alpha: 1.0).cgColor,
            UIColor(red: 0.15, green: 0.08, blue: 0.25, alpha: 1.0).cgColor
        ]
        
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        
        // IMPORTANT: Set as backgroundView, not a subview of the main view
        self.tableView.backgroundView = backgroundView
        
        // Force the table to be clear so we can see through it
        self.tableView.backgroundColor = .clear
    }
}
