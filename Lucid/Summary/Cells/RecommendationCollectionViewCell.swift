import UIKit

class RecommendationCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = "RecommendationCell"

    // MARK: - IBOutlets
    @IBOutlet weak var reasonLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    // MARK: - Configure
    func configure(with exercise: ExerciseInfo, reason: String) {
        titleLabel.text = exercise.title
        reasonLabel.text = reason
        let iconImage = UIImage(systemName: exercise.iconName) ?? UIImage(named: exercise.iconName)
        iconImageView.image = iconImage?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = UIColor(named: "AccentColor") ?? .systemOrange
        
        // Dynamic styling to force beautiful system sans-serif font
        titleLabel.font = .systemFont(ofSize: 19, weight: .bold)
        reasonLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .white
        reasonLabel.textColor = UIColor.white.withAlphaComponent(0.9)
    }
}
