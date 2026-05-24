//
//  BadgesCollectionViewCell.swift
//  Lucid
//
//  Redesigned by Antigravity on 28/04/26.
//

import UIKit

class BadgesCollectionViewCell: UICollectionViewCell {

    // MARK: - Legacy IBOutlets (connected in XIB — kept for XIB compatibility)
    @IBOutlet weak var icon: UIImageView?
    @IBOutlet weak var iconName: UILabel?
    @IBOutlet weak var iconTime: UILabel?

    // MARK: - UI Elements (programmatic)
    private let gradientLayer = CAGradientLayer()
    private let shimmerLayer  = CAGradientLayer()

    private let symbolImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor   = .white
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font          = UIFont.systemFont(ofSize: 11, weight: .semibold)
        l.textColor     = .white
        l.textAlignment = .center
        l.numberOfLines = 2
        l.adjustsFontSizeToFitWidth = true
        l.minimumScaleFactor = 0.7
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font          = UIFont.systemFont(ofSize: 9, weight: .regular)
        l.textColor     = UIColor.white.withAlphaComponent(0.75)
        l.textAlignment = .center
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Progress bar (track + fill)
    private let progressTrack: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        v.layer.cornerRadius = 2
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let progressFill: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.layer.cornerRadius = 2
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // Lock for locked state
    private let lockView: UIImageView = {
        let iv = UIImageView()
        iv.image               = UIImage(systemName: "lock.fill")
        iv.tintColor           = UIColor.white.withAlphaComponent(0.55)
        iv.contentMode         = .scaleAspectFit
        iv.isHidden            = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // Progress fill width constraint
    private var progressFillWidthConstraint: NSLayoutConstraint?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCard()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCard()
    }

    // MARK: - Setup
    private func setupCard() {
        contentView.layer.cornerRadius = 16
        contentView.clipsToBounds = true

        // Gradient bg
        gradientLayer.locations  = [0, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        contentView.layer.insertSublayer(gradientLayer, at: 0)

        // Subtle shimmer overlay
        shimmerLayer.colors     = [UIColor.white.withAlphaComponent(0.07).cgColor, UIColor.clear.cgColor]
        shimmerLayer.locations  = [0, 1]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0)
        shimmerLayer.endPoint   = CGPoint(x: 1, y: 1)
        contentView.layer.insertSublayer(shimmerLayer, at: 1)

        contentView.addSubview(symbolImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(progressTrack)
        progressTrack.addSubview(progressFill)
        contentView.addSubview(lockView)

        NSLayoutConstraint.activate([
            // Symbol centred, upper portion
            symbolImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            symbolImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            symbolImageView.widthAnchor.constraint(equalToConstant: 36),
            symbolImageView.heightAnchor.constraint(equalToConstant: 36),

            // Name
            nameLabel.topAnchor.constraint(equalTo: symbolImageView.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),

            // Date / progress text
            dateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),

            // Progress track at bottom
            progressTrack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            progressTrack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            progressTrack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            progressTrack.heightAnchor.constraint(equalToConstant: 4),

            // Progress fill
            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),

            // Lock (top-right corner)
            lockView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            lockView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            lockView.widthAnchor.constraint(equalToConstant: 14),
            lockView.heightAnchor.constraint(equalToConstant: 14),
        ])

        progressFillWidthConstraint = progressFill.widthAnchor.constraint(equalToConstant: 0)
        progressFillWidthConstraint?.isActive = true
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
        shimmerLayer.frame  = contentView.bounds
    }

    // MARK: - Configure
    func configure(badge: Badge, definition: AwardDefinition?, animate: Bool = false) {
        let tier = definition?.tier ?? .bronze

        gradientLayer.colors = tier.gradientColors.map { $0.cgColor }

        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        symbolImageView.image = UIImage(systemName: badge.imageName, withConfiguration: config)
        symbolImageView.tintColor = tier.contrastColor
        lockView.tintColor = tier.contrastColor.withAlphaComponent(0.55)

        nameLabel.text = badge.title
        nameLabel.textColor = tier.contrastColor
        
        dateLabel.text = badge.isUnlocked
            ? (badge.dateEarned ?? "")
            : "\(badge.progressValue)/\(badge.targetValue)"
        dateLabel.textColor = tier.contrastColor.withAlphaComponent(0.75)

        if badge.isUnlocked {
            contentView.alpha     = 1.0
            lockView.isHidden     = true
            symbolImageView.alpha = 1.0
            layer.shadowColor     = tier.glowColor.cgColor
            layer.shadowRadius    = 8
            layer.shadowOpacity   = 0.7
            layer.shadowOffset    = .zero
        } else {
            contentView.alpha     = 0.42
            lockView.isHidden     = false
            symbolImageView.alpha = 0.6
            layer.shadowOpacity   = 0
        }

        // Progress bar
        let ratio = badge.targetValue > 0
            ? CGFloat(badge.progressValue) / CGFloat(badge.targetValue)
            : 0
        setNeedsLayout()
        layoutIfNeeded()
        let trackWidth = progressTrack.bounds.width
        progressFillWidthConstraint?.constant = trackWidth * min(ratio, 1.0)
        progressTrack.backgroundColor = tier.contrastColor.withAlphaComponent(0.2)
        progressFill.backgroundColor = badge.isUnlocked
            ? tier.contrastColor
            : tier.contrastColor.withAlphaComponent(0.6)
    }

    // MARK: - Legacy configure (backward compatibility)
    func configure(name: String, date: String, image: String?) {
        nameLabel.text = name
        dateLabel.text = date
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        symbolImageView.image = image.flatMap { UIImage(systemName: $0, withConfiguration: config) }
        gradientLayer.colors = AwardTier.bronze.gradientColors.map { $0.cgColor }
        contentView.alpha = 1.0
        lockView.isHidden = true
    }

    func configureEmptyState(text: String) {
        nameLabel.text          = text
        nameLabel.font          = UIFont.systemFont(ofSize: 14, weight: .bold)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0
        dateLabel.text          = ""
        symbolImageView.image   = nil
        lockView.isHidden       = true
        gradientLayer.colors    = AwardTier.bronze.gradientColors.map { $0.cgColor }
        contentView.alpha       = 0.5
        progressFillWidthConstraint?.constant = 0
    }

    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        layer.removeAllAnimations()
        lockView.isHidden   = true
        contentView.alpha   = 1
        layer.shadowOpacity = 0
        progressFillWidthConstraint?.constant = 0
    }
}
