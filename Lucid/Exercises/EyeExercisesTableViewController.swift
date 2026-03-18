import UIKit
import SwiftData // Make sure to import SwiftData

class ExerciseTableViewController: UITableViewController {
    
    // 1. You need a reference to the context here first!
    var modelContext: ModelContext?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bgImageView = UIImageView(image: UIImage(named: "BackgroundGradient"))
        bgImageView.contentMode = .scaleAspectFill
        self.tableView.backgroundView = bgImageView
        self.tableView.backgroundColor = .clear

        view.subviews.forEach { subview in
            if let title = subview.viewWithTag(10) as? UILabel {
                title.font = UIFont.preferredFont(forTextStyle: .headline)
                title.setContentHuggingPriority(.defaultHigh, for: .vertical)
            }
            if let desc = subview.viewWithTag(20) as? UILabel {
                desc.numberOfLines = 0
                desc.setContentHuggingPriority(.defaultLow, for: .vertical)
            }
        }
    }

    // 2. Intercept the segue to pass the context
    // ExerciseTableViewController.swift
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? SmoothPursuitsViewController {
            destinationVC.modelContext = self.modelContext
        }
        // ADD THIS PART
        else if let blinkVC = segue.destination as? blinkTrainingViewController {
            blinkVC.modelContext = self.modelContext
            print("Successfully passed context to Blink VC")
        }
    }
}
