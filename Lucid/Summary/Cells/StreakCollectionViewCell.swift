import UIKit

class StreakCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var dayCircles: [UIView]!
    @IBOutlet var dateLabels: [UILabel]!
    
    @IBOutlet weak var streakCountLabel: UILabel!
    @IBOutlet weak var streakUnitLabel: UILabel!
    
    private let phraseLabel = UILabel()
    private let blobImageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    
    private enum StreakTone {
        case missed
        case days
        case weeks
        case months
    }
    
    
    
    private let blobImages: [StreakTone: [String]] = [
        .missed: ["StreakBlobSad", "StreakBlobWorried"],
        .days: ["StreakBlobHopeful", "StreakBlobDetermined"],
        .weeks: ["StreakBlobExcited", "StreakBlobHappy"],
        .months: ["StreakBlobExcited", "StreakBlobCalm"]
    ]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCard()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
        blobImageView.layer.cornerRadius = 0
    }

    func configure(with streakData: [(date: Date, isCompleted: Bool)], currentStreak: Int) {
        hideCalendarStrip()
        
        let todayCompleted = streakData.first { Calendar.current.isDateInToday($0.date) }?.isCompleted ?? false
        let tone = tone(for: currentStreak, todayCompleted: todayCompleted)
        let display = displayValue(for: currentStreak)
        
        streakCountLabel?.text = "\(display.value)"
        
        if streakUnitLabel == nil {
            streakUnitLabel = contentView.subviews.compactMap { $0 as? UILabel }.first { $0.text == "Day" || $0.text == "Days" || $0.text == "Week" || $0.text == "Weeks" || $0.text == "Month" || $0.text == "Months" }
        }
        streakUnitLabel?.text = display.unit
        streakUnitLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        streakUnitLabel?.textColor = UIColor(red: 1.0, green: 0.63, blue: 0.11, alpha: 1.0)
        
        phraseLabel.text = getPhrase(for: currentStreak, todayCompleted: todayCompleted)
        blobImageView.image = UIImage(named: blobImages[tone]?.randomElement() ?? "StreakBlobHopeful")
        applyGradient(for: tone)
    }
    
    private func setupCard() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
        layer.masksToBounds = true
        
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.insertSublayer(gradientLayer, at: 0)
        
        streakCountLabel?.font = .systemFont(ofSize: 56, weight: .heavy)
        streakCountLabel?.textColor = UIColor(red: 1.0, green: 0.48, blue: 0.02, alpha: 1.0)
        
        if streakUnitLabel == nil {
            streakUnitLabel = contentView.subviews.compactMap { $0 as? UILabel }.first { $0.text == "Day" }
        }
        streakUnitLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        streakUnitLabel?.textColor = UIColor(red: 1.0, green: 0.63, blue: 0.11, alpha: 1.0)
        
        let titleLabel = contentView.subviews.compactMap { $0 as? UILabel }.first { $0.text == "Exercise Streak" }
        titleLabel?.textColor = .white
        titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        
        phraseLabel.translatesAutoresizingMaskIntoConstraints = false
        phraseLabel.font = .systemFont(ofSize: 13, weight: .medium)
        phraseLabel.textColor = .white.withAlphaComponent(0.92)
        phraseLabel.textAlignment = .left
        phraseLabel.numberOfLines = 3
        phraseLabel.adjustsFontSizeToFitWidth = true
        phraseLabel.minimumScaleFactor = 0.8
        contentView.addSubview(phraseLabel)
        
        blobImageView.translatesAutoresizingMaskIntoConstraints = false
        blobImageView.contentMode = .scaleAspectFit
        blobImageView.clipsToBounds = false
        contentView.addSubview(blobImageView)
        
        if let title = titleLabel {
            NSLayoutConstraint.activate([
                phraseLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
                phraseLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
                phraseLabel.trailingAnchor.constraint(equalTo: blobImageView.leadingAnchor, constant: -8),
                phraseLabel.bottomAnchor.constraint(lessThanOrEqualTo: streakCountLabel.topAnchor, constant: -4)
            ])
        } else {
            NSLayoutConstraint.activate([
                phraseLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
                phraseLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 36),
                phraseLabel.trailingAnchor.constraint(equalTo: blobImageView.leadingAnchor, constant: -8),
                phraseLabel.bottomAnchor.constraint(lessThanOrEqualTo: streakCountLabel.topAnchor, constant: -4)
            ])
        }
        
        NSLayoutConstraint.activate([
            blobImageView.widthAnchor.constraint(equalToConstant: 120),
            blobImageView.heightAnchor.constraint(equalToConstant: 94),
            blobImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 2),
            blobImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 14)
        ])
    }
    
    private func hideCalendarStrip() {
        dayCircles?.forEach { $0.superview?.superview?.isHidden = true }
        dateLabels?.forEach { $0.isHidden = true }
    }
    
    private func tone(for currentStreak: Int, todayCompleted: Bool) -> StreakTone {
        if currentStreak == 0 {
            return .missed
        } else if currentStreak >= 30 {
            return .months
        } else if currentStreak >= 7 {
            return .weeks
        } else {
            return .days
        }
    }
    
    private func displayValue(for days: Int) -> (value: Int, unit: String) {
        if days >= 30 {
            let months = max(1, days / 30)
            return (months, months == 1 ? "Month" : "Months")
        }
        
        if days >= 7 {
            let weeks = max(1, days / 7)
            return (weeks, weeks == 1 ? "Week" : "Weeks")
        }
        
        return (days, days == 1 ? "Day" : "Days")
    }
    
    private func getPhrase(for streak: Int, todayCompleted: Bool) -> String {
        let display = displayValue(for: streak)
        let streakText = "\(display.value) \(display.unit.lowercased())"
        
        if todayCompleted {
            return "Yay, you completed today's goal! Luc is super proud of you!"
        } else {
            if streak == 0 {
                let incompletePhrases = [
                    "Let's make Luc happy by starting your daily streak!",
                    "Luc is excited to help you start your daily streak today!",
                    "Keep Luc smiling! A quick session will start your streak.",
                    "Let's do a quick exercise to make Luc proud!"
                ]
                return incompletePhrases.randomElement() ?? "Let's do some exercises!"
            } else {
                let incompletePhrases = [
                    "Keep your \(streakText) streak going! Luc is waiting for you.",
                    "Luc is rooting for you! A quick session will keep your \(streakText) streak going strong.",
                    "Keep Luc smiling! Complete an exercise to protect your \(streakText) streak.",
                    "A quick session is all it takes to keep your \(streakText) streak alive."
                ]
                return incompletePhrases.randomElement() ?? "Maintain your streak!"
            }
        }
    }
    
    private func applyGradient(for tone: StreakTone) {
        let colors: [CGColor]
        
        switch tone {
        case .missed:
            colors = [
                UIColor(red: 0.45, green: 0.25, blue: 0.15, alpha: 1.0).cgColor,
                UIColor(red: 0.11, green: 0.07, blue: 0.27, alpha: 1.0).cgColor,
                UIColor(red: 0.02, green: 0.02, blue: 0.10, alpha: 1.0).cgColor
            ]
        case .days:
            colors = [
                UIColor(red: 0.58, green: 0.33, blue: 0.08, alpha: 1.0).cgColor,
                UIColor(red: 0.22, green: 0.15, blue: 0.24, alpha: 1.0).cgColor,
                UIColor(red: 0.04, green: 0.03, blue: 0.16, alpha: 1.0).cgColor
            ]
        case .weeks:
            colors = [
                UIColor(red: 0.62, green: 0.38, blue: 0.08, alpha: 1.0).cgColor,
                UIColor(red: 0.26, green: 0.14, blue: 0.28, alpha: 1.0).cgColor,
                UIColor(red: 0.05, green: 0.03, blue: 0.18, alpha: 1.0).cgColor
            ]
        case .months:
            colors = [
                UIColor(red: 0.70, green: 0.42, blue: 0.10, alpha: 1.0).cgColor,
                UIColor(red: 0.30, green: 0.11, blue: 0.30, alpha: 1.0).cgColor,
                UIColor(red: 0.04, green: 0.02, blue: 0.16, alpha: 1.0).cgColor
            ]
        }
        
        gradientLayer.colors = colors
        gradientLayer.locations = [0.0, 0.58, 1.0]
    }
}
