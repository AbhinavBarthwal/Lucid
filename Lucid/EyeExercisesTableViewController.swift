import UIKit



//struct Exercise {
//    let title: String
//    let description: String
//    let image: String
//}
//
//let exercises: [Exercise] = [
//    Exercise(title: "Smooth Pursuits",
//             description: "Slowly follow a moving object with your eyes to keep your vision steady, clear, and focused.",
//             image: "SmoothPursuits"),
//
//    Exercise(title: "Saccadic Jumps",
//             description: "Practice jumping your gaze quickly between two spots to build speed and accuracy in your vision.",
//             image: "SaccadicJumps"),
//
//    Exercise(title: "Pencil Push Ups",
//             description: "Train your eyes to work together as a team so you can see close-up things without any strain.",
//             image: "PencilPushUps"),
//
//    Exercise(title: "Figure Eight",
//             description: "Trace a loopy path with your eyes to boost flexibility and make focusing easier.",
//             image: "FigureEight"),
//
//    Exercise(title: "Blink Training",
//             description: "Take slow blinks to refresh your eyes and prevent dryness.",
//             image: "BlinkTraining"),
//
//    Exercise(title: "Peripheral Awareness",
//             description: "Notice what is happening around you without turning your head.",
//             image: "PeripheralAwareness"),
//
//    Exercise(title: "Near Far Focus",
//             description: "Switch focus between near and distant objects to adjust faster.",
//             image: "NearFarFocus")
//]



class ExerciseTableViewController: UITableViewController {
    
    @IBOutlet weak var imageLabel: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    //    @IBOutlet weak var cellTitleLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Create the ImageView with your specific background
//        let base = UIFont.systemFont(ofSize: 16, weight: .medium, width: .expanded)
//        let descriptor = base.fontDescriptor.addingAttributes([
//            UIFontDescriptor.AttributeName.traits: [
//                UIFontDescriptor.TraitKey.width: UIFont.Width.expanded.rawValue
//            ]
//        ])
       // cellTitleLabel.font = UIFont(descriptor: descriptor, size: 0)
        let bgImageView = UIImageView(image: UIImage(named: "BackgroundGradient"))
        
        // 2. Set the content mode to cover the entire screen
        bgImageView.contentMode = .scaleAspectFill
        
        // 3. Assign it to the table
        self.tableView.backgroundView = bgImageView
        
        // 4. Ensure transparency of the table and cells
        self.tableView.backgroundColor = .clear
        

            // This finds every label with tag 10 (Titles) and 20 (Descriptions)
            view.subviews.forEach { subview in
                // Fix Titles
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
    
//    
//    override func tableView(_ tableView: UITableView,
//                            numberOfRowsInSection section: Int) -> Int {
//        
//        return exercises.count
//    }
//
//    
//    override func tableView(_ tableView: UITableView,
//                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//
//        let cell = tableView.dequeueReusableCell(withIdentifier: "ExerciseCell",
//                                                 for: indexPath)
//
//        let exercise = exercises[indexPath.row]
//        
//        
//        cell.textLabel?.text = exercise.title
//        cell.detailTextLabel?.text = exercise.description
//        cell.imageView?.image = UIImage(named: exercise.image)
//
//        return cell
//    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        let label = UILabel()
 
        label.textColor = .secondaryLabel
        label.frame = CGRect(x: 16, y: 10, width: 200, height: 20)

        if section == 0 {
 
            label.text = "Exercise"
            label.font = UIFont.systemFont(ofSize: 20, weight: .bold, width: .standard)
            headerView.addSubview(label)
            return headerView
        }
        if section == 1{
            label.text = "Tests"
            headerView.addSubview(label)
            label.font = UIFont.systemFont(ofSize: 20, weight: .bold, width: .expanded)
            return headerView
        }
        return nil
    }

    // YOU MUST ADD THIS: Without this, the table doesn't know how much space to give the header
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 || section == 1{
            return 35// Adjust this value to push the cells further down
        }
        return UITableView.automaticDimension
    }
}

