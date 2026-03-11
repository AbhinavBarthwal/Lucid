import UIKit

class ExerciseTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Create the ImageView with your specific background
        let bgImageView = UIImageView(image: UIImage(named: "BackgroundGradient"))
        
        // 2. Set the content mode to cover the entire screen
        bgImageView.contentMode = .scaleAspectFill
        
        // 3. Assign it to the table
        self.tableView.backgroundView = bgImageView
        
        // 4. Ensure transparency of the table and cells
        self.tableView.backgroundColor = .clear
    
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
        
    }
    // In your ExerciseTableViewController.swift
  
}
