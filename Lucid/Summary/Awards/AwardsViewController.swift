//
//  AwardsViewController.swift
//  Lucid
//
//  Redesigned by Antigravity on 28/04/26.
//

import UIKit

// MARK: - Awards View Controller
class AwardsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet var collectionView: UICollectionView!

    // Outlets for Storyboard Popup View
    @IBOutlet weak var popupOverlay: UIView!
    @IBOutlet weak var dimmingView: UIView!
    @IBOutlet weak var popupCard: UIView!
    @IBOutlet weak var popupSymbolImageView: UIImageView!
    @IBOutlet weak var popupTitleLabel: UILabel!
    @IBOutlet weak var popupDetailLabel: UILabel!
    @IBOutlet weak var popupDateLabel: UILabel!
    @IBOutlet weak var popupProgressTrack: UIView!
    @IBOutlet weak var popupProgressFill: UIView!
    @IBOutlet weak var popupProgressFillWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var popupProgressLabel: UILabel!
    @IBOutlet weak var popupCloseButton: UIButton!

    private let cardGradientLayer = CAGradientLayer()

    // Section data: category title → badges in that category
    private struct Section {
        let title: String
        let badges: [Badge]
        let definitions: [AwardDefinition]
    }

    private var sections: [Section] = []
    private var allBadges: [Badge]  = []

    // Track which badge ids were just newly unlocked (to trigger animation)
    private var newlyUnlockedIds: Set<String> = []
    private var tappedCellFrame: CGRect?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupCollectionView()
        setupPopupDesign()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cardGradientLayer.frame = popupCard.bounds
    }

    // MARK: - Data
    private func refreshData() {
        // Evaluate progress and unlock any newly earned badges
        let newIds = ProgressManager.shared.evaluateAndUnlock()
        newlyUnlockedIds = Set(newIds)

        allBadges = ProgressManager.shared.loadBadges()
        buildSections()
        collectionView.reloadData()
    }

    private func buildSections() {
        let categoryOrder: [(AwardCategory, String)] = [
            (.exerciseMilestone, "Exercise Milestones"),
            (.testMilestone,     "Test Milestones"),
            (.exerciseScore,     "Exercise Accuracy"),
            (.testScore,         "Vision Test Score"),
            (.streak,            "Daily Streaks"),
        ]

        sections = categoryOrder.compactMap { (cat, title) in
            let defs   = AwardCatalog.all.filter { $0.category == cat }
            let badges = defs.compactMap { def in allBadges.first { $0.id == def.id } }
            guard !badges.isEmpty else { return nil }
            return Section(title: title, badges: badges, definitions: defs)
        }
    }

    // MARK: - Collection View Setup
    private func setupCollectionView() {
        // Register NIB (still exists from original)
        collectionView.register(
            UINib(nibName: "BadgesCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "BadgeCell"
        )
        collectionView.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "BadgesHeader"
        )
        collectionView.dataSource = self
        collectionView.delegate   = self
        collectionView.collectionViewLayout = createLayout()
    }

    private func setupBackground() {
        let bgImageView = UIImageView(image: UIImage(named: "BackgroundGradient"))
        bgImageView.contentMode = .scaleAspectFill
        collectionView.backgroundView  = bgImageView
        collectionView.backgroundColor = .clear
    }

    private func setupPopupDesign() {
        // Gradient background for card
        cardGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        cardGradientLayer.endPoint   = CGPoint(x: 1, y: 1)
        cardGradientLayer.locations  = [0, 1]
        cardGradientLayer.cornerRadius = 36
        cardGradientLayer.masksToBounds = true
        popupCard.layer.insertSublayer(cardGradientLayer, at: 0)

        // Custom shadow decoration for card
        popupCard.layer.cornerRadius = 36
        popupCard.layer.maskedCorners = [
            .layerMinXMinYCorner, .layerMaxXMinYCorner,
            .layerMinXMaxYCorner, .layerMaxXMaxYCorner
        ]
        popupCard.clipsToBounds = false
        
        // Translucent thin border for premium card feel
        popupCard.layer.borderWidth = 1
        popupCard.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor

        // Styled button
        popupCloseButton.layer.cornerRadius = 24
        popupCloseButton.clipsToBounds = true
        popupCloseButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        popupCloseButton.layer.borderWidth = 1
        popupCloseButton.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        popupCloseButton.setTitleColor(.white, for: .normal)
        
        // Styled progress bar
        popupProgressTrack.layer.cornerRadius = 3
        popupProgressTrack.clipsToBounds = true
        popupProgressFill.layer.cornerRadius = 3
        popupProgressFill.clipsToBounds = true

        // Tap gesture for dimmingView to dismiss
        dimmingView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleDimTap))
        dimmingView.addGestureRecognizer(tap)
    }

    // MARK: - Compositional Layout
    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] (sectionIndex, _) in
            guard let self, sectionIndex < self.sections.count else { return nil }

            // Header
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                    heightDimension: .absolute(44))
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)

            // 3-column grid — each cell square-ish (110 pt tall)
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1/3),
                                                  heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .absolute(148))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 12, trailing: 8)
            section.boundarySupplementaryItems = [header]
            return section
        }
    }

    // MARK: - DataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        sections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].badges.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: "BadgesHeader", for: indexPath)
        header.subviews.forEach { $0.removeFromSuperview() }

        let label = UILabel()
        label.text      = sections[indexPath.section].title
        label.font      = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.frame     = CGRect(x: 16, y: 8, width: header.bounds.width - 32, height: 30)
        header.addSubview(label)
        return header
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "BadgeCell", for: indexPath) as! BadgesCollectionViewCell

        let sec   = sections[indexPath.section]
        let badge = sec.badges[indexPath.item]
        let def   = sec.definitions[indexPath.item]
        let shouldAnimate = newlyUnlockedIds.contains(badge.id)

        cell.configure(badge: badge, definition: def, animate: shouldAnimate)
        return cell
    }

    // MARK: - Delegate (tap → popup)
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sec   = sections[indexPath.section]
        let badge = sec.badges[indexPath.item]
        guard let def = ProgressManager.shared.definition(for: badge.id) else { return }
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            tappedCellFrame = collectionView.convert(cell.frame, to: view)
        } else {
            tappedCellFrame = nil
        }
        
        showAwardPopup(badge: badge, definition: def)
    }

    // MARK: - Award Popup Presentation
    private func showAwardPopup(badge: Badge, definition: AwardDefinition) {
        let tier = definition.tier
        cardGradientLayer.colors = tier.gradientColors.map { $0.cgColor }

        let config = UIImage.SymbolConfiguration(pointSize: 40, weight: .medium)
        popupSymbolImageView.image = UIImage(systemName: badge.imageName, withConfiguration: config)
        popupSymbolImageView.tintColor = tier.contrastColor

        popupTitleLabel.text      = badge.title
        popupTitleLabel.textColor = tier.contrastColor

        if badge.isUnlocked {
            popupDetailLabel.text = definition.detail
            popupDateLabel.text   = "Earned on \(badge.dateEarned ?? "")"
            popupProgressLabel.text = "Completed!"
        } else {
            popupDetailLabel.text = getLockedDescription(for: definition)
            popupDateLabel.text   = "Not yet unlocked"
            popupProgressLabel.text = "\(badge.progressValue) / \(badge.targetValue)"
        }
        
        popupDetailLabel.textColor   = tier.contrastColor.withAlphaComponent(0.85)
        popupDateLabel.textColor     = tier.contrastColor.withAlphaComponent(0.65)
        popupProgressLabel.textColor = tier.contrastColor.withAlphaComponent(0.8)
        
        popupProgressTrack.backgroundColor = tier.contrastColor.withAlphaComponent(0.2)
        popupProgressFill.backgroundColor  = tier.contrastColor
        
        popupCloseButton.backgroundColor = tier.contrastColor.withAlphaComponent(0.2)
        popupCloseButton.layer.borderColor = tier.contrastColor.withAlphaComponent(0.25).cgColor
        popupCloseButton.setTitleColor(tier.contrastColor, for: .normal)

        popupCard.layer.shadowColor   = tier.glowColor.cgColor
        popupCard.layer.shadowRadius  = 20
        popupCard.layer.shadowOpacity = badge.isUnlocked ? 0.8 : 0.2
        popupCard.layer.shadowOffset  = .zero

        popupSymbolImageView.alpha = badge.isUnlocked ? 1.0 : 0.5

        popupOverlay.isHidden = false
        dimmingView.alpha = 0
        popupCard.alpha = 0
        popupCard.transform = .identity
        popupProgressFillWidthConstraint.constant = 0
        view.layoutIfNeeded()

        let trackWidth = popupProgressTrack.bounds.width
        let ratio = badge.targetValue > 0 ? CGFloat(badge.progressValue) / CGFloat(badge.targetValue) : 0

        var startTransform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        if let cellFrame = tappedCellFrame {
            let cardCenter = popupCard.center
            let cellCenter = CGPoint(x: cellFrame.midX, y: cellFrame.midY)
            let dx = cellCenter.x - cardCenter.x
            let dy = cellCenter.y - cardCenter.y
            let scaleX = cellFrame.width / max(1, popupCard.bounds.width)
            let scaleY = cellFrame.height / max(1, popupCard.bounds.height)
            startTransform = CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scaleX, y: scaleY)
        }
        popupCard.transform = startTransform

        UIView.animate(withDuration: 0.38, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.6) {
            self.dimmingView.alpha = 1
            self.popupCard.alpha   = 1
            self.popupCard.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 0.55, delay: 0.05, options: .curveEaseOut) {
                self.popupProgressFillWidthConstraint.constant = trackWidth * min(ratio, 1.0)
                self.view.layoutIfNeeded()
            }
        }
    }

    private func getLockedDescription(for definition: AwardDefinition) -> String {
        switch definition.category {
        case .exerciseMilestone:
            let plural = definition.targetValue == 1 ? "exercise" : "exercises"
            return "Complete \(definition.targetValue) \(plural) to unlock this badge."
        case .testMilestone:
            let plural = definition.targetValue == 1 ? "test" : "tests"
            return "Complete \(definition.targetValue) eye \(plural) to unlock this badge."
        case .exerciseScore:
            return "Maintain an average exercise accuracy of \(definition.targetValue)% or higher to unlock this badge."
        case .testScore:
            return "Achieve a score of \(definition.targetValue) or higher on the Landolt C-Test to unlock this badge."
        case .streak:
            return "Maintain a daily exercise streak of \(definition.targetValue) days to unlock this badge."
        }
    }

    private func dismissAwardPopup() {
        var endTransform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        if let cellFrame = tappedCellFrame {
            let cardCenter = popupCard.center
            let cellCenter = CGPoint(x: cellFrame.midX, y: cellFrame.midY)
            let dx = cellCenter.x - cardCenter.x
            let dy = cellCenter.y - cardCenter.y
            let scaleX = cellFrame.width / max(1, popupCard.bounds.width)
            let scaleY = cellFrame.height / max(1, popupCard.bounds.height)
            endTransform = CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scaleX, y: scaleY)
        }
        
        UIView.animate(withDuration: 0.32, delay: 0, options: .curveEaseInOut) {
            self.dimmingView.alpha = 0
            self.popupCard.alpha   = 0
            self.popupCard.transform = endTransform
        } completion: { _ in
            self.popupOverlay.isHidden = true
            self.tappedCellFrame = nil
        }
    }

    @objc private func handleDimTap() {
        dismissAwardPopup()
    }

    @IBAction func closePopupTapped(_ sender: Any) {
        dismissAwardPopup()
    }

    // MARK: - Navigation
    @IBAction func backButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
