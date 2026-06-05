import UIKit
import SwiftUI

typealias CTestCollectionViewController = CTestResultPageCollectionViewController

// MARK: - Models

struct CTestEyeResult {
    let eyeTitle: String
    let rawScore: Int
    let statusText: String
    let insightText: String
    let tintColor: UIColor

    static func make(for eyeTitle: String, rawScore: Int) -> CTestEyeResult {
        let clampedScore = min(max(rawScore, 0), 6)

        let statusText: String
        let insightText: String
        let tintColor: UIColor

        switch clampedScore {
        case 6:
            statusText = "Excellent Acuity"
            insightText = "Optimal clarity! Your eye resolved the smallest shapes easily, showing sharp and healthy vision."
            tintColor = .cTestPositive
        case 5:
            statusText = "Very Good Acuity"
            insightText = "Strong focus! This eye saw almost all details clearly."
            tintColor = .cTestPositive
        case 4:
            statusText = "Good Acuity"
            insightText = "Clear functional vision. You identified most orientations, though there is minor room to sharpen."
            tintColor = .cTestPositive
        case 3:
            statusText = "Moderate Acuity"
            insightText = "Fair detail recognition. You resolved larger shapes easily, but struggled slightly with smaller ones."
            tintColor = .cTestOrange
        case 2:
            statusText = "Lower Detail Clarity"
            insightText = "A bit soft on details. Larger targets were clear, but smaller orientation details were tricky."
            tintColor = .cTestWarning
        case 1:
            statusText = "Reduced Acuity"
            insightText = "Struggled with shape details today. This can occur with screen fatigue or poor lighting."
            tintColor = .cTestWarning
        default:
            statusText = "Needs Care & Practice"
            insightText = "Very tricky to identify directions. This suggests high visual fatigue. We recommend resting your eyes."
            tintColor = .cTestWarning
        }

        return CTestEyeResult(
            eyeTitle: eyeTitle,
            rawScore: clampedScore,
            statusText: statusText,
            insightText: insightText,
            tintColor: tintColor
        )
    }
}

struct CTestComparison {
    let previousLeft: Int
    let previousRight: Int
}

private struct CTestWisdomItem {
    let title: String
    let body: String
}

private enum CTestResultSection: Int, CaseIterable {
    case hero
    case performance
    case eyes
    case wisdom
}


private struct CTestPerformanceViewModel {
    let previousText: String
    let subtitleText: String

    static func make(previous: CTestComparison) -> CTestPerformanceViewModel {
        let previousAverage = Double(previous.previousLeft + previous.previousRight) / 2.0
        return CTestPerformanceViewModel(
            previousText: String(format: "%.1f / 6", previousAverage),
            subtitleText: "Previous saved score"
        )
    }
}
// MARK: - View Controller

final class CTestResultPageCollectionViewController: UICollectionViewController {

    var leftEyeResult: CTestEyeResult = .make(for: "Left Eye", rawScore: 0)
    var rightEyeResult: CTestEyeResult = .make(for: "Right Eye", rawScore: 0)
    var previousResult: CTestComparison?

    private var wisdomItems: [CTestWisdomItem] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        loadContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationItems()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    private func configureView() {
        title = "C Test Results"
        view.backgroundColor = .black
        collectionView.backgroundColor = .black
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 32, right: 0)
        collectionView.contentInsetAdjustmentBehavior = .automatic
        collectionView.setCollectionViewLayout(createLayout(), animated: false)

        collectionView.register(CTestHeroCell.self, forCellWithReuseIdentifier: CTestHeroCell.reuseIdentifier)
        collectionView.register(CTestComparisonCell.self, forCellWithReuseIdentifier: CTestComparisonCell.reuseIdentifier)
        collectionView.register(CTestWisdomCell.self, forCellWithReuseIdentifier: CTestWisdomCell.reuseIdentifier)
        collectionView.register(CTestEyeCardCell.self, forCellWithReuseIdentifier: CTestEyeCardCell.reuseIdentifier)
    }

    private func loadContent() {
        wisdomItems = recommendationItems()
        collectionView.reloadData()
    }

    @objc private func dismissScreen() {
        if let navigationController, navigationController.presentingViewController != nil {
            navigationController.dismiss(animated: true)
        } else if let navigationController {
            navigationController.popToRootViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func configureNavigationItems() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.prefersLargeTitles = false

        title = "C Test Results"
        navigationItem.hidesBackButton = true
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(dismissScreen)
        )
    }

    private func createLayout() -> UICollectionViewLayout {
        let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider = { sectionIndex, _ in
            guard let section = CTestResultSection(rawValue: sectionIndex) else { return nil }

            let sectionHeight: NSCollectionLayoutDimension

            switch section {
            case .hero:
                sectionHeight = .estimated(260)

            case .performance:
                sectionHeight = .estimated(180)

            case .eyes:
                sectionHeight = .estimated(180)

            case .wisdom:
                sectionHeight = .estimated(180)
            }

            if section == .eyes {
                let item = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(0.5),
                        heightDimension: .fractionalHeight(1.0)
                    )
                )
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2)

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: sectionHeight
                    ),
                    subitems: [item]
                )

                let layoutSection = NSCollectionLayoutSection(group: group)
                layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
                return layoutSection
            }

            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: sectionHeight
                ),
                subitems: [item]
            )

            let layoutSection = NSCollectionLayoutSection(group: group)
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)

            return layoutSection
        }

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.interSectionSpacing = 8
        
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider, configuration: configuration)
    }

    private func recommendationItems() -> [CTestWisdomItem] {
        let averageScore = Double(leftEyeResult.rawScore + rightEyeResult.rawScore) / 2.0

        if averageScore <= 2.5 {
            return [
                CTestWisdomItem(
                    title: "Saccadic Jumps",
                    body: "Speeds up your eye reaction time and helps you lock on targets faster."
                ),
                CTestWisdomItem(
                    title: "Near Far Focus",
                    body: "Trains your eyes to quickly adjust between close and distant objects."
                )
            ]
        } else if averageScore <= 4.5 {
            return [
                CTestWisdomItem(
                    title: "Smooth Pursuits",
                    body: "Great for helping your eyes follow movement smoothly and comfortably."
                ),
                CTestWisdomItem(
                    title: "Blink Training",
                    body: "Refreshes your eyes and keeps them feeling comfortable during focus tasks."
                )
            ]
        } else {
            return [
                CTestWisdomItem(
                    title: "Figure Eight",
                    body: "A fun way to boost eye flexibility and coordination while keeping performance sharp."
                ),
                CTestWisdomItem(
                    title: "Near Far Focus",
                    body: "A great way to keep your eye muscles agile when they are already performing well."
                )
            ]
        }
    }
    
    private func computeTrend() -> Double? {
        guard let previousResult else { return nil }

        let currentAvg = Double(leftEyeResult.rawScore + rightEyeResult.rawScore) / 2
        let previousAvg = Double(previousResult.previousLeft + previousResult.previousRight) / 2

        return currentAvg - previousAvg
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        CTestResultSection.allCases.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = CTestResultSection(rawValue: section) else { return 0 }

        switch section {
        case .hero, .wisdom:
            return 1
        case .performance:
            return previousResult == nil ? 0 : 1
        case .eyes:
            return 2
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = CTestResultSection(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }

        switch section {
        case .hero:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CTestHeroCell.reuseIdentifier,
                for: indexPath
            ) as! CTestHeroCell
            cell.configure(left: leftEyeResult, right: rightEyeResult)
            cell.onInfoTapped = { [weak self] in
                self?.presentCTestInfo()
            }
            return cell

        case .wisdom:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CTestWisdomCell.reuseIdentifier,
                for: indexPath
            ) as! CTestWisdomCell
            cell.configure(with: wisdomItems)
            return cell

        case .eyes:
            let result = indexPath.item == 0 ? leftEyeResult : rightEyeResult
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CTestEyeCardCell.reuseIdentifier,
                for: indexPath
            ) as! CTestEyeCardCell
            cell.configure(with: result)
            return cell
            
        case .performance:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CTestComparisonCell.reuseIdentifier,
                for: indexPath
            ) as! CTestComparisonCell
            guard let previousResult else { return cell }
            cell.configure(previous: previousResult, left: leftEyeResult, right: rightEyeResult)
            return cell
        
        }
    }

    private func presentCTestInfo() {
        let controller = UIHostingController(
            rootView: NavigationStack {
                CTestInfoSheetView(leftResult: leftEyeResult, rightResult: rightEyeResult)
            }
        )
        controller.modalPresentationStyle = .pageSheet
        if let sheet = controller.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(controller, animated: true)
    }
}

// MARK: - Base Card

private class CTestBaseCardCell: UICollectionViewCell {
    static var reuseIdentifier: String { String(describing: self) }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureCardAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureCardAppearance()
    }

    private func configureCardAppearance() {
        backgroundColor = .clear
        contentView.backgroundColor = .cTestCard
        contentView.layer.cornerRadius = 24
        contentView.layer.cornerCurve = .continuous
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.05).cgColor
        contentView.layer.shadowColor = UIColor.cTestOrange.cgColor
        contentView.layer.shadowOpacity = 0.14
        contentView.layer.shadowRadius = 18
        contentView.layer.shadowOffset = CGSize(width: 0, height: 8)
    }
}

// MARK: - Hero Cell

private final class CTestHeroCell: CTestBaseCardCell {
    private let captionLabel = UILabel()
    private let scoreLabel = UILabel()
    private let severityLabel = UILabel()
    private let scoreBarView = CTestInlineScoreBarView()
    private let insightLabel = UILabel()
    private let infoButton = UIButton(type: .system)

    var onInfoTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureSubviews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onInfoTapped = nil
    }

    private func configureSubviews() {
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        captionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        captionLabel.textColor = UIColor.white.withAlphaComponent(0.56)
        captionLabel.text = "Your average C Test score"
        captionLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        infoButton.setContentHuggingPriority(.required, for: .horizontal)

        infoButton.translatesAutoresizingMaskIntoConstraints = false
        infoButton.tintColor = .white
        infoButton.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        infoButton.layer.cornerRadius = 18
        infoButton.layer.cornerCurve = .continuous
        infoButton.layer.borderWidth = 1
        infoButton.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        infoButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        infoButton.addTarget(self, action: #selector(infoTapped), for: .touchUpInside)

        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        scoreLabel.numberOfLines = 1
        scoreLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        scoreLabel.setContentHuggingPriority(.defaultLow, for: .vertical)

        severityLabel.translatesAutoresizingMaskIntoConstraints = false
        severityLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        insightLabel.translatesAutoresizingMaskIntoConstraints = false
        insightLabel.font = .systemFont(ofSize: 15, weight: .regular)
        insightLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        insightLabel.numberOfLines = 0

        scoreBarView.translatesAutoresizingMaskIntoConstraints = false

        let headerRow = UIStackView(arrangedSubviews: [captionLabel, infoButton])
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.distribution = .fill
        headerRow.spacing = 16

        let textStack = UIStackView(arrangedSubviews: [headerRow, scoreLabel, severityLabel, scoreBarView, insightLabel])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 8
        
        textStack.setCustomSpacing(10, after: scoreLabel)
        textStack.setCustomSpacing(10, after: severityLabel)
        textStack.setCustomSpacing(14, after: scoreBarView)

        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            infoButton.widthAnchor.constraint(equalToConstant: 36),
            infoButton.heightAnchor.constraint(equalToConstant: 36),
            scoreBarView.widthAnchor.constraint(equalTo: textStack.widthAnchor),
            scoreLabel.widthAnchor.constraint(equalTo: textStack.widthAnchor),
            severityLabel.widthAnchor.constraint(equalTo: textStack.widthAnchor),
            insightLabel.widthAnchor.constraint(equalTo: textStack.widthAnchor),
            scoreBarView.heightAnchor.constraint(equalToConstant: 34),

            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    func configure(left: CTestEyeResult, right: CTestEyeResult) {
        let averageScore = Double(left.rawScore + right.rawScore) / 2.0
        let severity = summaryTitle(for: averageScore)

        updateScoreLabel(with: averageScore)
        severityLabel.text = severity.text
        severityLabel.textColor = severity.color
        scoreBarView.configure(score: averageScore)
        insightLabel.text = heroInsight(left: left, right: right)
    }

    private func updateScoreLabel(with averageScore: Double) {
        let scoreString = String(format: "%.1f", averageScore)
        let suffixString = "/6"
        
        let attributedText = NSMutableAttributedString(
            string: scoreString,
            attributes: [
                .font: UIFont.systemFont(ofSize: 66, weight: .bold),
                .foregroundColor: UIColor.white
            ]
        )
        attributedText.append(NSAttributedString(
            string: suffixString,
            attributes: [
                .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.58)
            ]
        ))
        scoreLabel.attributedText = attributedText
    }

    private func summaryTitle(for score: Double) -> (text: String, color: UIColor) {
        switch score {
        case 5...6:
            return ("Strong Visual Performance", .cTestPositive)
        case 3..<5:
            return ("Steady Visual Performance", .cTestOrange)
        default:
            return ("Let's Practice Together", .cTestWarning)
        }
    }

    private func heroInsight(left: CTestEyeResult, right: CTestEyeResult) -> String {
        let diff = abs(left.rawScore - right.rawScore)
        if diff >= 2 {
            let strongerEye = left.rawScore > right.rawScore ? "left" : "right"
            let weakerEye = left.rawScore < right.rawScore ? "left" : "right"
            return "There is a noticeable difference between your eyes today. Your \(strongerEye) eye was sharper than your \(weakerEye) eye. Focus exercises can help."
        }
        
        let avg = Double(left.rawScore + right.rawScore) / 2.0
        if avg >= 5.0 {
            return "Superb performance! Both of your eyes are demonstrating high visual resolution today."
        } else if avg >= 3.0 {
            return "Good, balanced performance! Both eyes are working together smoothly and sharing the effort."
        } else {
            return "Both eyes are feeling a bit tired or strained. Consistent daily exercises will help boost your focus."
        }
    }

    @objc private func infoTapped() {
        onInfoTapped?()
    }
}

private final class CTestInlineScoreBarView: UIView {
    private let barView = UIView()
    private let markerView = UIView()
    private let labelsStack = UIStackView()
    private var rangeLabels: [UILabel] = []
    private var markerLeadingConstraint: NSLayoutConstraint?
    private var currentScore: Double = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureSubviews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        barView.layer.cornerRadius = barView.bounds.height / 2
        markerView.layer.cornerRadius = markerView.bounds.height / 2
        if let gradient = barView.layer.sublayers?.first(where: { $0.name == "cTestGradient" }) as? CAGradientLayer {
            gradient.frame = barView.bounds
            gradient.cornerRadius = barView.bounds.height / 2
        }
        updateMarkerAndLabels(animated: false)
    }

    private func configureSubviews() {
        barView.translatesAutoresizingMaskIntoConstraints = false
        barView.backgroundColor = .clear
        barView.layer.borderWidth = 1
        barView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.98, green: 0.85, blue: 0.79, alpha: 1).cgColor,
            UIColor(red: 1.0, green: 0.70, blue: 0.48, alpha: 1).cgColor,
            UIColor(red: 1.0, green: 0.45, blue: 0.26, alpha: 1).cgColor,
            UIColor(red: 0.94, green: 0.16, blue: 0.13, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.name = "cTestGradient"
        barView.layer.insertSublayer(gradient, at: 0)

        markerView.translatesAutoresizingMaskIntoConstraints = false
        markerView.backgroundColor = .white
        markerView.layer.shadowColor = UIColor.white.cgColor
        markerView.layer.shadowOpacity = 0.3
        markerView.layer.shadowRadius = 5
        markerView.layer.shadowOffset = .zero

        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        labelsStack.axis = .horizontal
        labelsStack.distribution = .fillEqually
        labelsStack.alignment = .center

        ["Needs Care", "Fair", "Good", "Strong"].forEach { title in
            let label = UILabel()
            label.font = .systemFont(ofSize: 8, weight: .semibold)
            label.textColor = UIColor.white.withAlphaComponent(0.82)
            label.textAlignment = .center
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.75
            label.text = title
            rangeLabels.append(label)
            labelsStack.addArrangedSubview(label)
        }

        addSubview(barView)
        barView.addSubview(markerView)
        addSubview(labelsStack)

        markerLeadingConstraint = markerView.leadingAnchor.constraint(equalTo: barView.leadingAnchor)

        NSLayoutConstraint.activate([
            barView.topAnchor.constraint(equalTo: topAnchor),
            barView.leadingAnchor.constraint(equalTo: leadingAnchor),
            barView.trailingAnchor.constraint(equalTo: trailingAnchor),
            barView.heightAnchor.constraint(equalToConstant: 12),

            markerView.centerYAnchor.constraint(equalTo: barView.centerYAnchor),
            markerView.widthAnchor.constraint(equalToConstant: 4),
            markerView.heightAnchor.constraint(equalToConstant: 20),
            markerLeadingConstraint!,

            labelsStack.topAnchor.constraint(equalTo: barView.bottomAnchor, constant: 6),
            labelsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            labelsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(score: Double) {
        currentScore = max(0, min(score, 6))
        updateMarkerAndLabels(animated: window != nil)
    }

    private func updateMarkerAndLabels(animated: Bool) {
        let markerWidth: CGFloat = 4
        let availableWidth = max(0, barView.bounds.width - markerWidth)
        markerLeadingConstraint?.constant = availableWidth * CGFloat(currentScore / 6.0)

        let activeIndex: Int
        switch currentScore {
        case 0..<1.5:
            activeIndex = 0
        case 1.5..<3:
            activeIndex = 1
        case 3..<4.5:
            activeIndex = 2
        default:
            activeIndex = 3
        }

        for (index, label) in rangeLabels.enumerated() {
            let isActive = index == activeIndex
            label.textColor = isActive ? .white : UIColor.white.withAlphaComponent(0.82)
            label.font = .systemFont(ofSize: 8, weight: isActive ? .bold : .semibold)
        }

        let animations = {
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.35, animations: animations)
        } else {
            animations()
        }
    }
}

// MARK: - Performance Cell

private final class CTestComparisonCell: CTestBaseCardCell {
    private let title = UILabel()
    private let result = UILabel()
    private let subtitle = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureSubviews()
    }

    private func configureSubviews() {
        title.text = "YOUR LAST SCORE"
        title.textColor = .cTestOrange
        title.font = .systemFont(ofSize: 12, weight: .semibold)

        result.font = .systemFont(ofSize: 40, weight: .bold)
        result.textColor = .white

        subtitle.textColor = UIColor.white.withAlphaComponent(0.7)
        subtitle.font = .systemFont(ofSize: 15, weight: .medium)
        subtitle.numberOfLines = 0
        subtitle.lineBreakMode = .byWordWrapping

        let stack = UIStackView(arrangedSubviews: [title, result, subtitle])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 22),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -22),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -22)
        ])
    }

    func configure(previous: CTestComparison, left: CTestEyeResult, right: CTestEyeResult) {
        let currentAvg = Double(left.rawScore + right.rawScore) / 2.0
        let previousAvg = Double(previous.previousLeft + previous.previousRight) / 2.0
        let delta = currentAvg - previousAvg

        let currentFormatted = String(format: "%.1f", currentAvg)
        let previousFormatted = String(format: "%.1f", previousAvg)
        result.text = "\(previousFormatted) → \(currentFormatted) / 6"

        let tag: String
        let comparisonLine: String

        if delta == 0 {
            tag = "Steady"
            comparisonLine = "Same as last time, let's keep up the good work "
        } else if delta > 0 {
            let pts = String(format: "%.1f", delta)
            if delta >= 2 {
                tag = "Great!"
                comparisonLine = "Up \(pts) points from last time, your eyes are getting sharper!"
            } else if delta >= 1 {
                tag = "Good"
                comparisonLine = "Up \(pts) point from your last test. Nice steady progress!"
            } else {
                tag = "Decent"
                comparisonLine = "Slightly up \(pts) pts, small improvement keep it up!"
            }
        } else {
            let pts = String(format: "%.1f", abs(delta))
            if abs(delta) >= 2 {
                tag = "Low"
                comparisonLine = "Down \(pts) points from last time. Eyes might be tired!"
            } else {
                tag = "Okay"
                comparisonLine = "Slightly down \(pts) pts. Small swings are totally normal, no worries!"
            }
        }

        subtitle.text = "\(tag) — \(comparisonLine)"
    }
}

// MARK: - Wisdom Cell

private final class CTestWisdomCell: CTestBaseCardCell {
    private let titleLabel = UILabel()
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureSubviews()
    }

    private func configureSubviews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "YOUR CUSTOM RECOMMENDATIONS"
        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = .cTestOrange
        titleLabel.numberOfLines = 0

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8

        contentView.addSubview(titleLabel)
        contentView.addSubview(stackView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with items: [CTestWisdomItem]) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        items.forEach { item in
            stackView.addArrangedSubview(makeWisdomRow(item: item))
        }
    }

    private func makeWisdomRow(item: CTestWisdomItem) -> UIView {
        let bullet = UIView()
        bullet.translatesAutoresizingMaskIntoConstraints = false
        bullet.backgroundColor = .cTestOrange
        bullet.layer.cornerRadius = 3

        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        title.textColor = .white
        title.text = item.title
        title.numberOfLines = 0

        let body = UILabel()
        body.translatesAutoresizingMaskIntoConstraints = false
        body.font = .systemFont(ofSize: 12, weight: .medium)
        body.textColor = UIColor.white.withAlphaComponent(0.60)
        body.numberOfLines = 0
        body.text = item.body

        let textStack = UIStackView(arrangedSubviews: [title, body])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 3

        let row = UIView()
        row.addSubview(bullet)
        row.addSubview(textStack)

        NSLayoutConstraint.activate([
            bullet.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            bullet.topAnchor.constraint(equalTo: row.topAnchor, constant: 6),
            bullet.widthAnchor.constraint(equalToConstant: 6),
            bullet.heightAnchor.constraint(equalToConstant: 6),

            textStack.leadingAnchor.constraint(equalTo: bullet.trailingAnchor, constant: 10),
            textStack.topAnchor.constraint(equalTo: row.topAnchor),
            textStack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            textStack.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])

        return row
    }
}

// MARK: - Eye Card

private final class CTestEyeCardCell: CTestBaseCardCell {
    private let eyeLabel = UILabel()
    private let scoreLabel = UILabel()
    private let statusLabel = UILabel()
    private let insightLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureSubviews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureSubviews()
    }

    private func configureSubviews() {
        eyeLabel.textColor = UIColor.white.withAlphaComponent(0.68)
        eyeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        eyeLabel.textAlignment = .center

        scoreLabel.textColor = .white
        scoreLabel.font = .systemFont(ofSize: 34, weight: .bold)
        scoreLabel.textAlignment = .center

        statusLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        insightLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        insightLabel.font = .systemFont(ofSize: 11, weight: .medium)
        insightLabel.textAlignment = .center
        insightLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [eyeLabel, scoreLabel, statusLabel, insightLabel])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),
            stack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }

    func configure(with result: CTestEyeResult) {
        eyeLabel.text = result.eyeTitle.uppercased()
        scoreLabel.text = "\(result.rawScore)/6"
        statusLabel.text = result.statusText
        statusLabel.textColor = result.tintColor
        insightLabel.text = result.insightText
    }
}

// MARK: - Info Sheet

private struct CTestInfoSheetView: View {
    let leftResult: CTestEyeResult
    let rightResult: CTestEyeResult
    @Environment(\.dismiss) private var dismiss

    private var averageScore: Double {
        Double(leftResult.rawScore + rightResult.rawScore) / 2.0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About C Test")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text("The C Test shows a C shape facing different directions. It checks how clearly each eye can see and compares your left and right eye.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                }

                infoRow(
                    title: "How the score works",
                    body: "Each eye is scored out of 6. Higher values mean that eye correctly handled more targets during the test."
                )

                infoRow(
                    title: "Why both eyes matter",
                    body: "Looking at both eyes separately helps surface imbalance. A repeated gap between left and right can be more useful than a single score alone."
                )

                infoRow(
                    title: "Current result",
                    body: "Left eye: \(leftResult.rawScore)/6. Right eye: \(rightResult.rawScore)/6. Average performance today: \(String(format: "%.1f", averageScore))/6."
                )
            }
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundStyle(.white)
            }
        }
    }

    private func infoRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Text(body)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.68))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .cTestCard))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Colors

private extension UIColor {
    static let cTestOrange = UIColor(red: 1.0, green: 0.47, blue: 0.0, alpha: 1.0)
    static let cTestWarning = UIColor(red: 1.0, green: 0.63, blue: 0.28, alpha: 1.0)
    static let cTestPositive = UIColor(red: 0.32, green: 0.84, blue: 0.55, alpha: 1.0)
    static let cTestCard = UIColor(white: 0.09, alpha: 1.0)
}
