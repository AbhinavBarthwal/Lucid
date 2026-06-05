//
//  ReportCollectionViewCell.swift
//  Lucid
//
//  Created by Kanishka Bansal on 15/03/26.
//

import UIKit

class ReportCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var ringGauge: FullRingGauge!
    @IBOutlet weak var scoreLabel: UILabel!
    private let captionLabel = UILabel()
    private let scoreMeaningLabel = UILabel()
    private let stackView = UIStackView()

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .clear
        clipsToBounds = false
        contentView.backgroundColor = .exerciseResultCard
        contentView.layer.cornerRadius = 24
        contentView.layer.cornerCurve = .continuous
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.05).cgColor
        contentView.layer.shadowColor = UIColor.exerciseResultOrange.cgColor
        contentView.layer.shadowOpacity = 0.14
        contentView.layer.shadowRadius = 18
        contentView.layer.shadowOffset = CGSize(width: 0, height: 8)
        contentView.clipsToBounds = true

        ringGauge.isHidden = true
        
        scoreLabel.textColor = .white
        scoreLabel.font = .systemFont(ofSize: 36, weight: .bold)
        scoreLabel.adjustsFontSizeToFitWidth = true
        scoreLabel.minimumScaleFactor = 0.75
        scoreLabel.textAlignment = .center

        captionLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        captionLabel.textColor = .exerciseResultOrange
        captionLabel.textAlignment = .center

        scoreMeaningLabel.textColor = UIColor.white.withAlphaComponent(0.68)
        scoreMeaningLabel.numberOfLines = 0
        scoreMeaningLabel.textAlignment = .center

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stackView)

        // Remove scoreLabel from its original hierarchy and add to stackView
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.removeFromSuperview()

        stackView.addArrangedSubview(captionLabel)
        stackView.addArrangedSubview(scoreLabel)
        stackView.addArrangedSubview(scoreMeaningLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(score: Int, sessionType: String, errors: Int) {
        scoreLabel.isHidden = false
        scoreMeaningLabel.textAlignment = .center
        scoreMeaningLabel.font = .systemFont(ofSize: 11, weight: .medium)
        
        scoreLabel.text = "\(score)%"
        captionLabel.text = sessionType == "SaccadicJumps" ? "RESPONSE SCORE" : "EXERCISE SCORE"
        switch sessionType {
        case "SmoothPursuit":
            scoreMeaningLabel.text = errors == 0
                ? "you did very well today and touched every point"
                : "there were \(errors) missed points, but we will improve upon them for sure"
        case "SaccadicJumps":
            scoreMeaningLabel.text = errors == 0
                ? "your response as per the direction announced were on point, Welldone!"
                : "while there were \(errors) errors, we will get it better next time."
        default:
            scoreMeaningLabel.text = errors == 0
                ? "Lets goooo! Wonderfull session"
                : "while there were \(errors) errors, we will get it better next time."
        }
    }

    func configureCompletion(title: String, message: String) {
        scoreLabel.isHidden = false
        scoreMeaningLabel.textAlignment = .center
        scoreMeaningLabel.font = .systemFont(ofSize: 13, weight: .medium)
        
        scoreLabel.text = "Done"
        captionLabel.text = title.uppercased()
        scoreMeaningLabel.text = message
    }

    func configureResponsiveness(avgReactionTimeSeconds: Double) {
        scoreLabel.isHidden = false
        scoreMeaningLabel.textAlignment = .center
        scoreMeaningLabel.font = .systemFont(ofSize: 11, weight: .medium)
        
        scoreLabel.text = String(format: "%.2fs", avgReactionTimeSeconds)
        captionLabel.text = "RESPONSIVENESS"
        scoreMeaningLabel.text = "lower that 0.5s is good and if it is higher than that there is a room for improvement."
    }

    func configureWisdom(title: String, message: String) {
        scoreLabel.isHidden = true
        captionLabel.text = title.uppercased()
        scoreMeaningLabel.text = message
        scoreMeaningLabel.textAlignment = .left
        scoreMeaningLabel.font = .systemFont(ofSize: 15, weight: .regular)
    }
}
