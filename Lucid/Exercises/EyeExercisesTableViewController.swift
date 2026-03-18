import UIKit
<<<<<<< Updated upstream

class ExerciseTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Create the ImageView with your specific background
=======
import SwiftData

class ExerciseTableViewController: UITableViewController {
    
    let exercises = ["Blink", "SmoothPursuit", "PencilPushup", "Figure8", "NearFar"]
    
    // Reference to the SwiftData context
    var modelContext: ModelContext?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
    }

    private func setupBackground() {
>>>>>>> Stashed changes
        let bgImageView = UIImageView(image: UIImage(named: "BackgroundGradient"))
        
        // 2. Set the content mode to cover the entire screen
        bgImageView.contentMode = .scaleAspectFill
        
        // 3. Assign it to the table
        self.tableView.backgroundView = bgImageView
        
        // 4. Ensure transparency of the table and cells
        self.tableView.backgroundColor = .clear
<<<<<<< Updated upstream
    
            view.subviews.forEach { subview in

                if let title = subview.viewWithTag(10) as? UILabel {
                    title.font = UIFont.preferredFont(forTextStyle: .headline)
                    title.setContentHuggingPriority(.defaultHigh, for: .vertical)
                }
                
                // Fix Descriptions
                if let desc = subview.viewWithTag(20) as? UILabel {
                    desc.numberOfLines = 0
                    desc.setContentHuggingPriority(.defaultLow, for: .vertical)
                }
            }
=======
    }

    //Navigation & Data Passing
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destinationVC = segue.destination as? SmoothPursuitsViewController {
            destinationVC.modelContext = self.modelContext
            print("Successfully passed context to Smooth Pursuit VC")
            
        } else if let blinkVC = segue.destination as? blinkTrainingViewController {
            blinkVC.modelContext = self.modelContext
            print("Successfully passed context to Blink VC")
        }
>>>>>>> Stashed changes
        
    }
    // In your ExerciseTableViewController.swift
  
}
