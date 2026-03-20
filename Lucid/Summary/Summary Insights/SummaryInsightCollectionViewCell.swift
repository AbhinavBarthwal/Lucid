import UIKit

class SummaryInsightCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var badge: UIImageView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var descriprtionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        hardCodeData()
    }

    private func setupUI() {
        containerView.layer.cornerRadius = 20
        containerView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        containerView.clipsToBounds = true
        
        let config = UIImage.SymbolConfiguration.preferringMulticolor
        badge.preferredSymbolConfiguration = config()
    }

    private func hardCodeData() {
        headingLabel.text = "Excellent Work"
        descriprtionLabel.text = "Your Overall Eye Health Score improved by 5 points this month, moving you closer to the ideal 100."
        
        badge.image = UIImage(systemName: "medal.fill")
        
        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .small)
    }
    
    func configure(name: String, description: String) {
        headingLabel.text = name
        descriprtionLabel.text = description
        let config = UIImage.SymbolConfiguration.preferringMulticolor
        badge.image = UIImage(systemName: "medal.fill", withConfiguration: config())
    }
}

