import UIKit
import SwiftData 

class ExerciseTableViewController: UITableViewController {
    
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


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "ShowExercise" {
                if let destinationVC = segue.destination as? UIViewController {
                    destinationVC.hidesBottomBarWhenPushed = true
                }
            }
        
        if let destinationVC = segue.destination as? SmoothPursuitsViewController {
            destinationVC.modelContext = self.modelContext
        }

        else if let blinkVC = segue.destination as? blinkTrainingViewController {
            blinkVC.modelContext = self.modelContext
            print("Successfully passed context to Blink VC")
        }
    }
}
