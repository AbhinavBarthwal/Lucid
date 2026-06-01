import UIKit

class AwardsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var awardNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(name: String, date: String , image : String) {
        let topStack = contentView.subviews.compactMap { $0 as? UIStackView }.first
        if let headerLabel = topStack?.arrangedSubviews.compactMap({ $0 as? UILabel }).first {
            headerLabel.text = name
            headerLabel.font = .systemFont(ofSize: 16, weight: .bold)
            headerLabel.textColor = .white
            headerLabel.numberOfLines = 0
            headerLabel.lineBreakMode = .byWordWrapping
        }

        awardNameLabel.text = date
        awardNameLabel.textColor = UIColor.white.withAlphaComponent(0.65)
        awardNameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        
        dateLabel.text = "  "
        dateLabel.textColor = .clear

        let awardImage = UIImage(systemName: image) ?? UIImage(named: image)
        iconImageView.image = awardImage?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = UIColor(named: "AccentColor") ?? .systemOrange
    }
    
}
