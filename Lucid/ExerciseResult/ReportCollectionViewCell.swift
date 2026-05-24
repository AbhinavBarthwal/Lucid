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
        scoreLabel.font = .systemFont(ofSize: 48, weight: .bold)
        scoreLabel.adjustsFontSizeToFitWidth = true
        scoreLabel.minimumScaleFactor = 0.75

        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        captionLabel.text = "EXERCISE SCORE"
        captionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        captionLabel.textColor = .exerciseResultOrange
        captionLabel.textAlignment = .center

        scoreMeaningLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreMeaningLabel.font = .systemFont(ofSize: 14, weight: .medium)
        scoreMeaningLabel.textColor = UIColor.white.withAlphaComponent(0.68)
        scoreMeaningLabel.textAlignment = .center
        scoreMeaningLabel.numberOfLines = 2

        contentView.addSubview(captionLabel)
        contentView.addSubview(scoreMeaningLabel)

        NSLayoutConstraint.activate([
            captionLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            captionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            captionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            scoreMeaningLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            scoreMeaningLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            scoreMeaningLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18)
        ])
    }
    
    func configure(score: Int, sessionType: String, errors: Int) {
        scoreLabel.text = "\(score)%"
        captionLabel.text = sessionType == "SaccadicJumps" ? "RESPONSE SCORE" : "EXERCISE SCORE"
        switch sessionType {
        case "SmoothPursuit":
            scoreMeaningLabel.text = errors == 0
                ? "Excellent tracking today. No missed gaze checks recorded."
                : "\(errors) missed gaze checks. Higher score means smoother tracking."
        case "SaccadicJumps":
            scoreMeaningLabel.text = errors == 0
                ? "Clean directional responses across the session."
                : "\(errors) missed responses. Higher score means faster directional accuracy."
        default:
            scoreMeaningLabel.text = errors == 0
                ? "Clean blink set. No missed blink checks recorded."
                : "\(errors) errors recorded. Higher score means stronger blink completion."
        }
    }

    func configureCompletion(title: String, message: String) {
        scoreLabel.text = "Done"
        captionLabel.text = title.uppercased()
        scoreMeaningLabel.text = message
    }
}
