import UIKit

class LowLightScreenUsageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var ringContainer: SemiCircleGauge! 

    override func awakeFromNib() {
        super.awakeFromNib()
    }



    func configure(usage: String, progress: CGFloat) {
        layoutIfNeeded()
        timeLabel.text = usage
        ringContainer.setProgress(0.9)
    }
}
