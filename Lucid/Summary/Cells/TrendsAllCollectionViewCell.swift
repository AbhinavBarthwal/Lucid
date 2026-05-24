import UIKit

class TrendsAllCollectionViewCell: UICollectionViewCell {

    static let identifier = "TrendsAllCell"
    
    @IBOutlet weak var iconContainerView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Circular mask for the icon background
        iconContainerView.layer.cornerRadius = 16 // Half of the 32 width/height
        iconContainerView.clipsToBounds = true
        
        // Subtle translucent background to match the aesthetic
        iconContainerView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
    }
    
    /// Call this in cellForItemAt
    func configure(title: String, subtitle: String, color: UIColor, iconName: String = "minus") {
        titleLabel.text = title
        
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = color
        
        // Using SF Symbols for high-fidelity scaling
        let config = UIImage.SymbolConfiguration(weight: .black)
        iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
        iconImageView.tintColor = color
    }
}
