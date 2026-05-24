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
        iconImageView.image = UIImage(named: exercise.iconName)
    }
}
