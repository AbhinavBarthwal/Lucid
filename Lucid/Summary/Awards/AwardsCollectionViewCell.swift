import UIKit

class AwardsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var awardNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(name: String, date: String , image : String) {
        awardNameLabel.text = name
        dateLabel.text = date
        iconImageView.image = UIImage(named: image)
    }
    
}
