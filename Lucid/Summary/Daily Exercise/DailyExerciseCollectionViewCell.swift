import UIKit

class DailyExerciseCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var gaugeView: SemiCircleGauge!
    @IBOutlet weak var currentMinsLabel: UILabel!
    @IBOutlet weak var totalMinsLabel: UILabel!

    override func awakeFromNib() {
            super.awakeFromNib()
    }

        func configure(current: Int, goal: Int) {
            currentMinsLabel.text = "\(current)m"
            totalMinsLabel.text = "\(goal)m"
            let calculatedProgress = goal > 0 ? CGFloat(current) / CGFloat(goal) : 0
            gaugeView.setProgress(calculatedProgress)
    }
}
