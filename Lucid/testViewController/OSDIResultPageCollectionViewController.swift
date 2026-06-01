import UIKit
import SwiftUI
import Charts

// MARK: - Models

struct OSDIHistoryPoint: Identifiable {
    let id: UUID
    let title: String
    let shortDate: String
    let score: Double
    let date: Date
}

struct OSDIRecommendationItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

enum OSDIResultSection: Int, CaseIterable {
    case hero
    case history
    case recommendations
}


final class OSDIResultPageCollectionViewController: UICollectionViewController {

    var osdiScore: Double = 24.0
    var severity: String = "Moderate"

    private var historyPoints: [OSDIHistoryPoint] = []
    private var previousScore: Double?
    private var recommendations: [OSDIRecommendationItem] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewHierarchy()
        loadResultContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationItems()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    private func configureViewHierarchy() {
        title = "OSDI Result"
        view.backgroundColor = .black
        collectionView.backgroundColor = .black
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 32, right: 0)
        collectionView.contentInsetAdjustmentBehavior = .automatic
        collectionView.showsVerticalScrollIndicator = false
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
//        navigationController?.navigationBar.tintColor = .white

        collectionView.register(HeroScoreCell.self, forCellWithReuseIdentifier: HeroScoreCell.reuseIdentifier)
        collectionView.register(TrendHistoryCell.self, forCellWithReuseIdentifier: TrendHistoryCell.reuseIdentifier)
        collectionView.register(RecommendationsCell.self, forCellWithReuseIdentifier: RecommendationsCell.reuseIdentifier)
    }

    private func loadResultContent() {
        let recentSessions = OSDIDataManager.shared.fetchRecentOSDISessions(limit: 5)
        previousScore = recentSessions.count > 1 ? recentSessions[1].score : nil

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        historyPoints = recentSessions
            .reversed()
            .enumerated()
            .map { index, session in
                let isLatest = index == recentSessions.count - 1
                return OSDIHistoryPoint(
                    id: session.id,
                    title: isLatest ? "Today" : "Test \(index + 1)",
                    shortDate: formatter.string(from: session.date),
                    score: session.score,
                    date: session.date
                )
            }

        if historyPoints.isEmpty {
            let today = Date()
            historyPoints = [
                OSDIHistoryPoint(
                    id: UUID(),
                    title: "Today",
                    shortDate: formatter.string(from: today),
                    score: osdiScore,
                    date: today
                )
            ]
        }

        recommendations = recommendationItems(for: severity)
        collectionView.setCollectionViewLayout(createLayout(), animated: false)
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

        title = "OSDI Result"
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
            guard let section = OSDIResultSection(rawValue: sectionIndex) else { return nil }

            let height: NSCollectionLayoutDimension
            switch section {
            case .hero:
                height = .estimated(350)
            case .history:
                height = .estimated(110)
            case .recommendations:
                height = .estimated(180)
            }

            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(100)
                )
            )

            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: height
                ),
                subitems: [item]
            )

            let layoutSection = NSCollectionLayoutSection(group: group)
            layoutSection.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            return layoutSection
        }

        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        let areEqual: Bool = {
            guard let prev = previousScore else { return false }
            return abs(prev - osdiScore) < 0.0001
        }()
        configuration.interSectionSpacing = areEqual ? 12 : 12
        
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider, configuration: configuration)
    }

    private func insightText(for severity: String, score: Double) -> String {
        if score == 0 {
            return "Perfect score! Your eyes are in excellent shape with no signs of dry eye irritation. Keep doing what you're doing!"
        }
        
        switch severity {
        case "Normal":
            if score <= 6 {
                return "Awesome job! Your eyes feel happy and comfy with almost no dryness today. Keep blinking and taking little breaks!"
            } else {
                return "Great job! Your score is normal, and your eyes are working nicely. Remember to rest your eyes with tiny screen breaks."
            }
        case "Mild":
            return "You have a little dryness, like sand in your eyes sometimes. Drink water, blink more, and take small screen breaks to feel better."
        case "Moderate":
            return "Your eyes feel a bit rough and tired today. Try Blink Training, rest often, and be kind to your eyes so they can feel calm again."
        case "Severe":
            if score > 60 {
                return "Your eyes feel very dry and sore right now. Rest them, skip long screen time, and ask a grown-up eye doctor for help if it keeps hurting."
            } else {
                return "Your eyes are having a hard day and need extra care. Try warm eye hugs, slow blinks, and planned breaks to help them feel better."
            }
        default:
            return "Your eyes feel tired and dry. Give them rest, sip water, and do easy eye exercises to make them happy again."
        }
    }

    private func severityTint(for severity: String) -> UIColor {
        switch severity {
        case "Normal":
            return UIColor(red: 0.32, green: 0.84, blue: 0.55, alpha: 1.0)
        case "Mild":
            return UIColor(red: 1.0, green: 0.76, blue: 0.29, alpha: 1.0)
        case "Moderate":
            return .osdiOrange
        default:
            return UIColor(red: 1.0, green: 0.35, blue: 0.29, alpha: 1.0)
        }
    }

    private func recommendationItems(for severity: String) -> [OSDIRecommendationItem] {
        switch severity {
        case "Normal":
            return [
                OSDIRecommendationItem(title: "Smooth Pursuits", detail: "Try Smooth Pursuits to help your eyes track moving targets with fluid coordination."),
                OSDIRecommendationItem(title: "Figure Eight", detail: "Try Figure Eight to keep your eye muscles flexible, agile, and well-coordinated.")
            ]
        case "Mild":
            return [
                OSDIRecommendationItem(title: "Blink Training", detail: "Perfect for mild dryness. Boosts the tear film to naturally soothe your eyes."),
                OSDIRecommendationItem(title: "Peripheral Awareness", detail: "Helps widen your field of view and relaxes focused eye strain.")
            ]
        case "Moderate":
            return [
                OSDIRecommendationItem(title: "Blink Training", detail: "Essential to restore moisture. Helps clear up moderate fatigue and irritation."),
                OSDIRecommendationItem(title: "Saccadic Jumps", detail: "Improves visual agility and stimulates blinking reflexes to ease moderate strain.")
            ]
        default:
            return [
                OSDIRecommendationItem(title: "Blink Training", detail: "Focus on slow, full blinks to restore the soothing moisture barrier over your dry eyes."),
                OSDIRecommendationItem(title: "Digital Break", detail: "Highly recommended: take a 20-minute screen break to rest your eye muscles.")
            ]
        }
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        OSDIResultSection.allCases.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = OSDIResultSection(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }

        switch section {
        case .hero:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HeroScoreCell.reuseIdentifier, for: indexPath) as! HeroScoreCell
            cell.configure(
                score: osdiScore,
                severity: severity,
                severityColor: severityTint(for: severity),
                insight: insightText(for: severity, score: osdiScore)
            )
            cell.onInfoTapped = { [weak self] in
                self?.presentOSDIInfo()
            }
            return cell

        case .history:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrendHistoryCell.reuseIdentifier, for: indexPath) as! TrendHistoryCell
            cell.configure(
                current: osdiScore,
                previous: previousScore
            )
            return cell

        case .recommendations:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecommendationsCell.reuseIdentifier, for: indexPath) as! RecommendationsCell
            cell.configure(with: recommendations)
            return cell
        }
    }

    private func presentOSDIInfo() {
        let controller = UIHostingController(
            rootView: NavigationStack {
                OSDIInfoSheetView(score: osdiScore, severity: severity)
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

// MARK: - UIKit Cells

class PremiumCardCell: UICollectionViewCell {
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
        contentView.backgroundColor = .osdiCardBackground
        contentView.layer.cornerRadius = 24
        contentView.layer.cornerCurve = .continuous
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.05).cgColor
        contentView.layer.shadowColor = UIColor.osdiOrange.cgColor
        contentView.layer.shadowOpacity = 0.14
        contentView.layer.shadowRadius = 18
        contentView.layer.shadowOffset = CGSize(width: 0, height: 8)
    }
}

final class HeroScoreCell: PremiumCardCell {
    private let captionLabel = UILabel()
    private let scoreLabel = UILabel()
    private let severityLabel = UILabel()
    private let scoreBarView = OSDIInlineSeverityBarView()
    private let insightLabel = UILabel()
    private let infoButton = UIButton(type: .system)
    private let headerRow = UIView()

    private var animationStart: CFTimeInterval = 0
    private var animationDuration: CFTimeInterval = 0.9
    private var targetScore: Double = 0
    private var displayLink: CADisplayLink?
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
        displayLink?.invalidate()
        displayLink = nil
        onInfoTapped = nil
    }

    private func configureSubviews() {
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        captionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        captionLabel.textColor = UIColor.white.withAlphaComponent(0.56)
        captionLabel.text = "YOUR EYE COMFORT SCORE"
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
        severityLabel.textColor = .white
        severityLabel.numberOfLines = 0
        severityLabel.adjustsFontSizeToFitWidth = false
        severityLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        severityLabel.setContentHuggingPriority(.required, for: .vertical)

        insightLabel.translatesAutoresizingMaskIntoConstraints = false
        insightLabel.font = .systemFont(ofSize: 15, weight: .regular)
        insightLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        insightLabel.numberOfLines = 0
        insightLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        scoreBarView.translatesAutoresizingMaskIntoConstraints = false

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        headerRow.translatesAutoresizingMaskIntoConstraints = false
        headerRow.addSubview(captionLabel)
        headerRow.addSubview(infoButton)
        headerRow.addSubview(spacer)

        NSLayoutConstraint.activate([
            captionLabel.leadingAnchor.constraint(equalTo: headerRow.leadingAnchor),
            captionLabel.centerYAnchor.constraint(equalTo: infoButton.centerYAnchor),
            captionLabel.trailingAnchor.constraint(lessThanOrEqualTo: infoButton.leadingAnchor, constant: -12),

            infoButton.topAnchor.constraint(equalTo: headerRow.topAnchor),
            infoButton.trailingAnchor.constraint(equalTo: headerRow.trailingAnchor),
            infoButton.bottomAnchor.constraint(equalTo: headerRow.bottomAnchor),

            spacer.leadingAnchor.constraint(equalTo: captionLabel.trailingAnchor),
            spacer.trailingAnchor.constraint(equalTo: infoButton.leadingAnchor),
            spacer.topAnchor.constraint(equalTo: headerRow.topAnchor),
            spacer.bottomAnchor.constraint(equalTo: headerRow.bottomAnchor)
        ])

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
            headerRow.widthAnchor.constraint(equalTo: textStack.widthAnchor),
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

    func configure(score: Double, severity: String, severityColor: UIColor, insight: String) {
        targetScore = score
        severityLabel.text = severity
        severityLabel.textColor = severityColor
        scoreBarView.configure(score: score)
        insightLabel.text = insight
        animateScore()
    }

    private func updateScoreLabel(with scoreValue: Int) {
        let scoreString = "\(scoreValue)"
        let suffixString = "/100"
        
        let attributedText = NSMutableAttributedString(
            string: scoreString,
            attributes: [
                .font: UIFont.systemFont(ofSize: 74, weight: .bold),
                .foregroundColor: UIColor.white
            ]
        )
        attributedText.append(NSAttributedString(
            string: suffixString,
            attributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.58)
            ]
        ))
        scoreLabel.attributedText = attributedText
    }

    private func animateScore() {
        displayLink?.invalidate()
        updateScoreLabel(with: 0)
        animationStart = CACurrentMediaTime()

        let link = CADisplayLink(target: self, selector: #selector(handleDisplayLink))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func handleDisplayLink() {
        let elapsed = CACurrentMediaTime() - animationStart
        let progress = min(1, elapsed / animationDuration)
        let eased = 1 - pow(1 - progress, 3)
        updateScoreLabel(with: Int((targetScore * eased).rounded()))

        if progress >= 1 {
            updateScoreLabel(with: Int(targetScore.rounded()))
            displayLink?.invalidate()
            displayLink = nil
        }
    }

    @objc private func infoTapped() {
        onInfoTapped?()
    }
}

final class OSDIInlineSeverityBarView: UIView {
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
        if let gradient = barView.layer.sublayers?.first(where: { $0.name == "severityGradient" }) as? CAGradientLayer {
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
            UIColor(red: 0.97, green: 0.82, blue: 0.78, alpha: 1).cgColor,
            UIColor(red: 1.0, green: 0.70, blue: 0.48, alpha: 1).cgColor,
            UIColor(red: 1.0, green: 0.45, blue: 0.26, alpha: 1).cgColor,
            UIColor(red: 0.94, green: 0.16, blue: 0.13, alpha: 1).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.name = "severityGradient"
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

        ["Normal", "Mild", "Moderate", "Severe"].forEach { title in
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

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let gradient = barView.layer.sublayers?.first(where: { $0.name == "severityGradient" }) as? CAGradientLayer {
            gradient.frame = barView.bounds
            gradient.cornerRadius = barView.bounds.height / 2
        }
    }

    func configure(score: Double) {
        currentScore = max(0, min(score, 100))
        updateMarkerAndLabels(animated: window != nil)
    }

    private func updateMarkerAndLabels(animated: Bool) {
        let markerWidth: CGFloat = 4
        let availableWidth = max(0, barView.bounds.width - markerWidth)
        markerLeadingConstraint?.constant = availableWidth * CGFloat(currentScore / 100.0)

        let activeIndex: Int
        switch currentScore {
        case 0...12:
            activeIndex = 0
        case 13...22:
            activeIndex = 1
        case 23...32:
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

final class TrendHistoryCell: PremiumCardCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func configure(current: Double, previous: Double?) {
        var config = UIHostingConfiguration {
            OSDIPerformanceView(
                currentScore: current,
                previousScore: previous
            )
        }
        .margins(.all, 0)
        contentConfiguration = config
    }
}

struct OSDIPerformanceView: View {
    let currentScore: Double
    let previousScore: Double?

    private var percentChange: Double? {
        guard let prev = previousScore, prev != 0 else { return nil }
        return ((currentScore - prev) / prev) * 100
    }

    private var isImproved: Bool {
        guard let change = percentChange else { return false }
        return change < 0
    }

    private var changeText: String {
        guard let change = percentChange else {
            return "Your first eye comfort score is saved!"
        }

        let value = abs(Int(change.rounded()))

        return isImproved
        ? "\(value)% better comfort"
        : "\(value)% increase in strain"
    }

    private var changeColor: Color {
        guard let change = percentChange else { return .white }
        return change <= 0 ? .green : .red
    }

    private var scoreDifferenceText: String? {
        guard let previousScore else { return nil }

        let difference = currentScore - previousScore
        let formattedDifference = String(format: "%.1f", abs(difference))

        if difference < 0 {
            return "\(formattedDifference) points lower (more comfortable!) than last check-up"
        } else if difference > 0 {
            return "\(formattedDifference) points higher (more strain) than last check-up"
        } else {
            return "Just like last time! Steady and consistent."
        }
    }

    private var previousScoreText: String {
        guard let previousScore else {
            return "We've saved this to your trends!"
        }

        return "Last score: \(String(format: "%.1f", previousScore))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text("PERFORMANCE")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(uiColor: .osdiOrange))

            Text("Lower scores mean happier, more comfortable eyes!")
                .foregroundStyle(.green)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            if percentChange != nil {
                Text(changeText)
                    .foregroundStyle(changeColor)
                    .font(.system(size: 26, weight: .bold))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let scoreDifferenceText {
                Text(scoreDifferenceText)
                    .foregroundStyle(.white.opacity(0.72))
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(previousScoreText)
                .foregroundStyle(.white.opacity(0.55))
                .font(.system(size: 13, weight: .medium))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .osdiCardBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
final class RecommendationsCell: PremiumCardCell {
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
        titleLabel.text = "RECOMMENDATIONS"
        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = .osdiOrange

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

    func configure(with items: [OSDIRecommendationItem]) {
        let limitedItems = Array(items.prefix(3))

        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        limitedItems.forEach { item in
            stackView.addArrangedSubview(
                makeBulletRow(title: item.title, detail: item.detail)
            )
        }
    }

    private func makeBulletRow(title: String, detail: String) -> UIView {
        let bullet = UIView()
        bullet.translatesAutoresizingMaskIntoConstraints = false
        bullet.backgroundColor = .osdiOrange
        bullet.layer.cornerRadius = 4

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.text = title
        titleLabel.numberOfLines = 0

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.64)
        label.numberOfLines = 0
        label.text = detail

        let textStack = UIStackView(arrangedSubviews: [titleLabel, label])
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.axis = .vertical
        textStack.alignment = .fill
        textStack.spacing = 4

        let row = UIView()
        row.addSubview(bullet)
        row.addSubview(textStack)

        NSLayoutConstraint.activate([
            bullet.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            bullet.topAnchor.constraint(equalTo: row.topAnchor, constant: 8),
            bullet.widthAnchor.constraint(equalToConstant: 8),
            bullet.heightAnchor.constraint(equalToConstant: 8),

            textStack.leadingAnchor.constraint(equalTo: bullet.trailingAnchor, constant: 12),
            textStack.topAnchor.constraint(equalTo: row.topAnchor),
            textStack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            textStack.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])

        return row
    }
}

// MARK: - SwiftUI Chart

struct OSDIInfoSheetView: View {
    let score: Double
    let severity: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About OSDI")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text("OSDI measures ocular discomfort and how dry-eye symptoms affect daily visual tasks. Scores range from 0 to 100, and lower scores are better.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                }

                OSDIReferenceCurveView(score: score, severity: severity)

                VStack(alignment: .leading, spacing: 10) {
                    infoRow(title: "How the score is mapped", body: "The chart uses the number of answered questions and the sum of all response scores to derive the final OSDI result.")
                    infoRow(title: "Severity mapping", body: "0–12 is Normal, 13–22 is Mild, 23–32 is Moderate, and 33–100 is Severe.")
                    infoRow(title: "Current result", body: "Your current score is \(Int(score.rounded())), which falls in the \(severity) range.")
                }
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
        .background(Color(uiColor: .osdiCardBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct OSDIReferenceCurveView: View {
    let score: Double
    let severity: String
    @State private var isVisible = false

    private let xBuckets: [Int] = [5, 10, 15, 20, 25, 30, 35, 40, 45, 48]
    private let maxVisibleColumnsByAnswered: [Int: Int] = [
        1: 1,
        2: 2,
        3: 2,
        4: 3,
        5: 4,
        6: 5,
        7: 6,
        8: 6,
        9: 7,
        10: 8,
        11: 9,
        12: 10
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("OSDI CURVE")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(uiColor: .osdiOrange))

                Text("Result placement")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)

                Text("Your score is positioned on the OSDI severity scale. Lower scores indicate healthier ocular comfort.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
            }

            VStack(alignment: .leading, spacing: 16) {
                osdiReferenceChart

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Score")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                        Text("\(Int(score.rounded()))")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Severity")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                        Text(severity)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(severityColor)
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(uiColor: .osdiCardBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onAppear {
            isVisible = true
        }
    }

    private var osdiReferenceChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { proxy in
                let cellWidth = (proxy.size.width - 26) / CGFloat(xBuckets.count)
                let clampedColumn = markerColumnPosition
                let markerX = 26 + cellWidth * clampedColumn + (cellWidth / 2)

                ZStack(alignment: .topLeading) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack(spacing: 4) {
                            ForEach((1...12).reversed(), id: \.self) { answered in
                                Text("\(answered)")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .frame(width: 16, height: 22)
                            }
                        }

                        VStack(spacing: 4) {
                            ForEach((1...12).reversed(), id: \.self) { answered in
                                HStack(spacing: 4) {
                                    ForEach(Array(xBuckets.enumerated()), id: \.offset) { index, bucket in
                                        referenceCell(answered: answered, bucket: bucket, isActive: index < visibleColumnCount(for: answered))
                                            .frame(height: 22)
                                    }
                                }
                            }
                        }
                    }

                    VStack(spacing: 6) {
                        Text("Your score")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule(style: .continuous).fill(Color.green))

                        Circle()
                            .fill(Color.green)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 3))
                            .shadow(color: Color.green.opacity(0.45), radius: 10)
                    }
                    .offset(x: markerX - 34, y: -6)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.75, anchor: .top)
                    .animation(.easeOut(duration: 0.55), value: isVisible)
                }
            }
            .frame(height: 312)

            HStack(spacing: 4) {
                Spacer()
                    .frame(width: 26)
                ForEach(xBuckets, id: \.self) { bucket in
                    Text("\(bucket)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.68))
                        .frame(maxWidth: .infinity)
                }
            }

            Text("Sum of scores for all questions answered")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func referenceCell(answered: Int, bucket: Int, isActive: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(
                    isActive
                    ? LinearGradient(
                        colors: [
                            Color(uiColor: .osdiOrange).opacity(0.82),
                            Color.red.opacity(0.92)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [
                            Color.white.opacity(0.03),
                            Color.white.opacity(0.015)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color.white.opacity(isActive ? 0.08 : 0.04), lineWidth: 1)

            if isActive {
                Text(referenceScoreText(answered: answered, bucket: bucket))
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.horizontal, 2)
            }
        }
    }

    private func referenceScoreText(answered: Int, bucket: Int) -> String {
        let value = min(100.0, Double(bucket) * 25.0 / Double(answered))
        return String(format: "%.1f", value)
    }

    private func visibleColumnCount(for answered: Int) -> Int {
        maxVisibleColumnsByAnswered[answered] ?? 0
    }

    private var markerColumnPosition: CGFloat {
        let sum = max(0, min(score, 100)) * 12.0 / 25.0
        let normalized = sum / 48.0
        return CGFloat(normalized) * CGFloat(xBuckets.count - 1)
    }

    private var severityColor: Color {
        switch severity {
        case "Normal":
            return Color(red: 0.32, green: 0.84, blue: 0.55)
        case "Mild":
            return Color(red: 1.0, green: 0.76, blue: 0.29)
        case "Moderate":
            return Color(uiColor: .osdiOrange)
        default:
            return Color(red: 1.0, green: 0.35, blue: 0.29)
        }
    }
}

struct OSDISeverityBarView: View {
    let score: Double

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let markerX = proxy.size.width * CGFloat(max(0, min(score, 100)) / 100)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.97, green: 0.82, blue: 0.78),
                                    Color(red: 1.0, green: 0.70, blue: 0.48),
                                    Color(red: 1.0, green: 0.45, blue: 0.26),
                                    Color(red: 0.94, green: 0.16, blue: 0.13)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)

                    Capsule(style: .continuous)
                        .fill(Color.white)
                        .frame(width: 4, height: 20)
                        .shadow(color: .white.opacity(0.35), radius: 6)
                        .offset(x: max(0, min(proxy.size.width - 4, markerX - 2)))
                }
            }
            .frame(height: 12)

            HStack {
                severityLabel("Normal")
                Spacer()
                severityLabel("Mild")
                Spacer()
                severityLabel("Moderate")
                Spacer()
                severityLabel("Severe")
            }
        }
    }

    private func severityLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(0.78))
    }
}

// MARK: - Colors

private extension UIColor {
    static let osdiOrange = UIColor(red: 1.0, green: 0.478, blue: 0.0, alpha: 1.0)
    static let osdiNavyBlue = UIColor(red: 0.11, green: 0.18, blue: 0.34, alpha: 1.0)
    static let osdiCardBackground = UIColor(white: 0.07, alpha: 1.0)
}
