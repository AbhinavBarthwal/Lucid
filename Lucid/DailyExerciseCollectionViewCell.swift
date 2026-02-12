import UIKit

class DailyExerciseCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var gaugeView: SemiCircleGauge!
    
    @IBOutlet weak var currentMinsLabel: UILabel!
    @IBOutlet weak var totalMinsLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()

        configure(current: 9, goal: 20)
    }
    
    private func setupUI() {
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        containerView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        containerView.bringSubviewToFront(currentMinsLabel)
        containerView.bringSubviewToFront(totalMinsLabel)
    }
    
    func configure(current: Int, goal: Int) {
        currentMinsLabel.text = "\(current)"
        totalMinsLabel.text = "\(goal)"
        let calculatedProgress = goal > 0 ? CGFloat(current) / CGFloat(goal) : 0
        gaugeView.progress = calculatedProgress
    }
}
