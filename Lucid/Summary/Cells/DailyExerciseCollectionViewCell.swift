import UIKit

class DailyExerciseCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var gaugeView: SemiCircleGauge!
    @IBOutlet weak var currentMinsLabel: UILabel!
    @IBOutlet weak var totalMinsLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Style titles programmatically with system font
        if let titleLabel = contentView.subviews.compactMap({ $0 as? UIStackView }).first?.arrangedSubviews.compactMap({ $0 as? UILabel }).first {
            titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
            titleLabel.textColor = .white
        }
        if let subtitleLabel = contentView.subviews.compactMap({ $0 as? UIStackView }).first?.arrangedSubviews.compactMap({ $0 as? UILabel }).last {
            subtitleLabel.font = .systemFont(ofSize: 12, weight: .medium)
            subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.68)
        }
        currentMinsLabel.font = .systemFont(ofSize: 22, weight: .bold)
        totalMinsLabel.font = .systemFont(ofSize: 22, weight: .bold)
    }

    func configure(currentSeconds: Int, goalSeconds: Int) {
        let currentMins = currentSeconds / 60
        let goalMins = goalSeconds / 60
        currentMinsLabel.text = "\(currentMins)m"
        totalMinsLabel.text = "\(goalMins)m"
        let calculatedProgress = goalSeconds > 0 ? CGFloat(currentSeconds) / CGFloat(goalSeconds) : 0
        gaugeView.setProgress(calculatedProgress)
    }
}
