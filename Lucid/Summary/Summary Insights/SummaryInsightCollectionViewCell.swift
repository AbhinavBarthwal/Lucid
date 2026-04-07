import UIKit

class SummaryInsightCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var badge: UIImageView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var descriprtionLabel: UILabel!
    
    // Add this closure to let the View Controller know when the close button is tapped
    var onDismiss: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        hardCodeData()
    }

    private func setupUI() {
        let config = UIImage.SymbolConfiguration.preferringMulticolor
        badge.preferredSymbolConfiguration = config()
    }

    private func hardCodeData() {
        headingLabel.text = "Excellent Work"
        descriprtionLabel.text = "Your Overall Eye Health Score improved by 5 points this month, moving you closer to the ideal 100."
        
        badge.image = UIImage(systemName: "medal.fill")
        
        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .small)
    }
    
    func configure(name: String, description: String) {
        headingLabel.text = name
        descriprtionLabel.text = description
        let config = UIImage.SymbolConfiguration.preferringMulticolor
        badge.image = UIImage(systemName: "medal.fill", withConfiguration: config())
    }
    
    // Connect this to the close button in your XIB file
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        onDismiss?()
    }
}
