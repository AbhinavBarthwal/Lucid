import UIKit

class ExerciseCollectionViewCell: UICollectionViewCell {

    // Connected outlets from the XIB
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var pillView: UIView!
    @IBOutlet weak var pillLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        self.titleLabel.textColor = .white
        self.descriptionLabel.textColor = .lightGray
        self.descriptionLabel.numberOfLines = 2
    }

    func configure(with exercise: ExerciseInfo, isRecommended: Bool) {
        titleLabel.text = exercise.title
        descriptionLabel.text = exercise.description
        iconImageView.image = UIImage(named: exercise.iconName)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        let seconds = exercise.estimatedTimeSeconds
        pillLabel.text = formatDuration(seconds)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) sec"
        } else {
            let minutes = Double(seconds) / 60.0
            if minutes.truncatingRemainder(dividingBy: 1.0) == 0 {
                return "\(Int(minutes)) min"
            } else {
                let mins = seconds / 60
                let secs = seconds % 60
                return "\(mins)m \(secs)s"
            }
        }
    }
}
