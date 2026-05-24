import UIKit

class DailyExerciseCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var gaugeView: SemiCircleGauge!
    @IBOutlet weak var currentMinsLabel: UILabel!
    @IBOutlet weak var totalMinsLabel: UILabel!

    override func awakeFromNib() {
            super.awakeFromNib()
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
