import UIKit

class AwardsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var awardNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var arrowImageView: UIImageView!

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
        iconImageView.preferredSymbolConfiguration = config()
    }

    private func hardCodeData() {
        awardNameLabel.text = "Focused Champ"
        dateLabel.text = "21/11/2025"
        
        iconImageView.image = UIImage(systemName: "infinity.circle.fill")
        
        let arrowConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium, scale: .small)
        
        arrowImageView.image = UIImage(systemName: "chevron.right.circle.fill", withConfiguration: arrowConfig)
        arrowImageView.tintColor = .systemGray
    }
    
    func configure(name: String, date: String) {
        awardNameLabel.text = name
        dateLabel.text = date
        let config = UIImage.SymbolConfiguration.preferringMulticolor
        iconImageView.image = UIImage(systemName: "infinity.circle.fill", withConfiguration: config())
    }
}

