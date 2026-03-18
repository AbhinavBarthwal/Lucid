import UIKit
import SwiftData

class ExerciseTableViewController: UITableViewController {
    
    // This array drives TableView rows and logic
    let exercises = ["Blink", "SmoothPursuit", "PencilPushup", "Figure8", "NearFar"]
    
    // Reference to the SwiftData context
    var modelContext: ModelContext?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
    }

    private func setupBackground() {
        let bgImageView = UIImageView(image: UIImage(named: "BackgroundGradient"))
        bgImageView.contentMode = .scaleAspectFill
        self.tableView.backgroundView = bgImageView
        self.tableView.backgroundColor = .clear
    }

    // MARK: - Navigation & Data Passing
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // This method acts as the 'Gatekeeper' to pass your database context
        
        if let destinationVC = segue.destination as? SmoothPursuitsViewController {
            destinationVC.modelContext = self.modelContext
            print("Successfully passed context to Smooth Pursuit VC")
            
        } else if let blinkVC = segue.destination as? blinkTrainingViewController {
            blinkVC.modelContext = self.modelContext
            print("Successfully passed context to Blink VC")
        }
    }
}
