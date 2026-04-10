import UIKit

class ExerciseCollectionViewCell: UICollectionViewCell {

    // Your connected outlets from the XIB
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()


        self.titleLabel.textColor = .white
        self.descriptionLabel.textColor = .lightGray
        self.descriptionLabel.numberOfLines = 0
    }


    func configure(with exercise: ExerciseInfo, isRecommended: Bool) {
        titleLabel.text = exercise.title
        descriptionLabel.text = exercise.description
        iconImageView.image = UIImage(named: exercise.iconName)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
    }
}
