import UIKit

final class GuidanceOverlayViewController: UIViewController {
    static let lastShownBuildKey = "Lucid.guidanceOverlay.didShow"
    static let didFinishNotification = Notification.Name("Lucid.guidanceOverlay.didFinish")
    static let didRequestNavigateToTestNotification = Notification.Name("Lucid.guidanceOverlay.didRequestNavigateToTest")

    private enum Target {
        case exerciseRecommendation
        case exerciseStreak
        case awards
    }

    private struct Callout {
        let title: String
        let body: String
    }

    private struct Step {
        let callout: Callout
        let target: Target
    }

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    private let dimView = UIView()
    private let pageControl = UIPageControl()
    private let hintLabel = UILabel()
    private var skipButton: UIButton?

    private let steps: [Step] = [
        Step(
            callout: Callout(
                title: "Daily Recommendation",
                body: "See your personalized daily eye exercise recommendation right here."
            ),
            target: .exerciseRecommendation
        ),
        Step(
            callout: Callout(
                title: "Exercise Streak",
                body: "Track your consistency. Complete exercises daily to keep Luc happy and healthy!"
            ),
            target: .exerciseStreak
        ),
        Step(
            callout: Callout(
                title: "Awards & Milestones",
                body: "Check out the custom awards, badges, and streaks you've unlocked along the way."
            ),
            target: .awards
        )
    ]

    private let arrowLayer = CAShapeLayer()
    private let blurMask = CAShapeLayer()
    private let dimMask = CAShapeLayer()
    private let spotlightStrokeLayer = CAShapeLayer()
    private var calloutViews: [UIView] = []
    private var stabilizationWorkItems: [DispatchWorkItem] = []
    private var hasDismissedIntroChrome = false
    private var lastResolvedTargetRect: CGRect?

    private var currentStepIndex = 0 {
        didSet {
            renderStep()
            scheduleStabilizationPasses()
        }
    }

    static func canPresent(from rootViewController: UIViewController?) -> Bool {
        guard let summary = findVisibleSummary(in: rootViewController) else { return false }
        summary.loadViewIfNeeded()
        return summary.viewIfLoaded?.window != nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        configureViewHierarchy()
        setupLayers()
        applyAppearance()
        addTapGesture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pageControl.alpha = 1
        hintLabel.alpha = 1
        renderStep()
        scheduleStabilizationPasses()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        blurMask.frame = view.bounds
        dimMask.frame = view.bounds
        renderStep()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelStabilizationPasses()
    }

    private func configureViewHierarchy() {
        view.backgroundColor = .clear

        blurView.translatesAutoresizingMaskIntoConstraints = false
        dimView.translatesAutoresizingMaskIntoConstraints = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.translatesAutoresizingMaskIntoConstraints = false

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.32)

        view.addSubview(blurView)
        view.addSubview(dimView)
        view.addSubview(pageControl)
        view.addSubview(hintLabel)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -118),

            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hintLabel.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -10)
        ])
    }

    private func setupLayers() {
        blurMask.fillRule = .evenOdd
        blurView.layer.mask = blurMask

        dimMask.fillRule = .evenOdd
        dimView.layer.mask = dimMask

        arrowLayer.strokeColor = UIColor.white.withAlphaComponent(0.92).cgColor
        arrowLayer.lineWidth = 2.4
        arrowLayer.lineCap = .round
        arrowLayer.lineJoin = .round
        arrowLayer.fillColor = UIColor.clear.cgColor
        arrowLayer.shadowColor = UIColor.black.cgColor
        arrowLayer.shadowOpacity = 0.35
        arrowLayer.shadowRadius = 6
        arrowLayer.shadowOffset = CGSize(width: 0, height: 2)
        dimView.layer.addSublayer(arrowLayer)

        spotlightStrokeLayer.fillColor = UIColor.clear.cgColor
        spotlightStrokeLayer.strokeColor = UIColor.white.withAlphaComponent(0.92).cgColor
        spotlightStrokeLayer.lineWidth = 2.0
        spotlightStrokeLayer.shadowColor = UIColor.black.cgColor
        spotlightStrokeLayer.shadowOpacity = 0.25
        spotlightStrokeLayer.shadowRadius = 5
        spotlightStrokeLayer.shadowOffset = CGSize(width: 0, height: 2)
        dimView.layer.addSublayer(spotlightStrokeLayer)
    }

    private func applyAppearance() {
        blurView.alpha = 0.88

        pageControl.numberOfPages = steps.count
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.24)
        pageControl.currentPageIndicatorTintColor = UIColor(red: 1.0, green: 0.62, blue: 0.22, alpha: 1.0)
        pageControl.isUserInteractionEnabled = false

        hintLabel.text = "Tap anywhere to continue"
        hintLabel.textColor = UIColor.white.withAlphaComponent(0.72)
        hintLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        hintLabel.textAlignment = .center

        skipButton?.alpha = 0
        skipButton?.isEnabled = false
        skipButton?.isHidden = true
    }

    private func addTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleNext))
        view.addGestureRecognizer(tap)
    }

    private func renderStep() {
        guard isViewLoaded, view.window != nil, (0..<steps.count).contains(currentStepIndex) else { return }

        let step = steps[currentStepIndex]
        pageControl.currentPage = currentStepIndex

        calloutViews.forEach { $0.removeFromSuperview() }
        calloutViews.removeAll()

        guard let targetRect = resolveTargetRect(for: step.target) else {
            lastResolvedTargetRect = nil
            clearOverlayPath()
            return
        }

        lastResolvedTargetRect = targetRect

        let spotlightRect = targetRect.insetBy(dx: -6, dy: -6)
        let spotlightPath = UIBezierPath(roundedRect: spotlightRect, cornerRadius: 16)
        let maskPath = UIBezierPath(rect: view.bounds)
        maskPath.append(spotlightPath)
        blurMask.path = maskPath.cgPath
        dimMask.path = maskPath.cgPath
        spotlightStrokeLayer.path = spotlightPath.cgPath

        let calloutView = makeCalloutView(for: step.callout)
        view.addSubview(calloutView)
        calloutViews.append(calloutView)

        let safeFrame = overlaySafeFrame()
        let calloutWidth = min(max(220, safeFrame.width * 0.52), 280)
        calloutView.bounds = CGRect(x: 0, y: 0, width: calloutWidth, height: 10)
        let fittedSize = calloutView.systemLayoutSizeFitting(
            CGSize(width: calloutWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        let calloutFrame = bestCalloutFrame(
            around: spotlightRect,
            target: step.target,
            size: CGSize(width: calloutWidth, height: fittedSize.height),
            safeFrame: safeFrame
        )
        calloutView.frame = calloutFrame

        drawArrow(from: calloutFrame, to: spotlightRect, target: step.target)
    }

    private func clearOverlayPath() {
        let fullScreenPath = UIBezierPath(rect: view.bounds)
        blurMask.path = fullScreenPath.cgPath
        dimMask.path = fullScreenPath.cgPath
        spotlightStrokeLayer.path = nil
        arrowLayer.path = nil
    }

    private func scheduleStabilizationPasses() {
        cancelStabilizationPasses()

        let delays: [TimeInterval] = [0.05, 0.14, 0.28, 0.45, 0.7, 1.0]
        for delay in delays {
            let workItem = DispatchWorkItem { [weak self] in
                self?.stabilizeCurrentStepIfNeeded()
            }
            stabilizationWorkItems.append(workItem)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        }
    }

    private func cancelStabilizationPasses() {
        stabilizationWorkItems.forEach { $0.cancel() }
        stabilizationWorkItems.removeAll()
    }

    private func stabilizeCurrentStepIfNeeded() {
        guard isViewLoaded, view.window != nil, (0..<steps.count).contains(currentStepIndex) else { return }
        let previousRect = lastResolvedTargetRect
        renderStep()

        guard let previousRect, let currentRect = lastResolvedTargetRect else { return }
        if rectsAreStable(previousRect, currentRect) {
            cancelStabilizationPasses()
        }
    }

    private func rectsAreStable(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        let tolerance: CGFloat = 1.5
        return abs(lhs.minX - rhs.minX) <= tolerance &&
            abs(lhs.minY - rhs.minY) <= tolerance &&
            abs(lhs.width - rhs.width) <= tolerance &&
            abs(lhs.height - rhs.height) <= tolerance
    }

    private func overlaySafeFrame() -> CGRect {
        view.bounds.inset(by: UIEdgeInsets(
            top: view.safeAreaInsets.top + 18,
            left: 18,
            bottom: view.safeAreaInsets.bottom + 160,
            right: 18
        ))
    }

    private func bestCalloutFrame(around targetRect: CGRect, target: Target, size: CGSize, safeFrame: CGRect) -> CGRect {
        let margin: CGFloat = 22
        let above = CGRect(
            x: targetRect.midX - size.width / 2,
            y: targetRect.minY - size.height - margin,
            width: size.width,
            height: size.height
        )
        let below = CGRect(
            x: targetRect.midX - size.width / 2,
            y: targetRect.maxY + margin,
            width: size.width,
            height: size.height
        )
        let left = CGRect(
            x: targetRect.minX - size.width - margin,
            y: targetRect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        let right = CGRect(
            x: targetRect.maxX + margin,
            y: targetRect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )

        let candidates: [CGRect]
        switch target {
        case .exerciseRecommendation:
            candidates = [below, above, right, left]
        case .exerciseStreak:
            candidates = [below, above, left, right]
        case .awards:
            candidates = [above, below, right, left]
        }

        let clamped = candidates.map { frame in
            CGRect(
                x: min(max(frame.minX, safeFrame.minX), safeFrame.maxX - frame.width),
                y: min(max(frame.minY, safeFrame.minY), safeFrame.maxY - frame.height),
                width: frame.width,
                height: frame.height
            )
        }

        let best = clamped.min { lhs, rhs in
            overlayPenalty(for: lhs, targetRect: targetRect, safeFrame: safeFrame) <
            overlayPenalty(for: rhs, targetRect: targetRect, safeFrame: safeFrame)
        }

        return best ?? CGRect(
            x: safeFrame.midX - size.width / 2,
            y: safeFrame.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    private func overlayPenalty(for frame: CGRect, targetRect: CGRect, safeFrame: CGRect) -> CGFloat {
        let intersection = frame.intersection(targetRect)
        let overlapArea = intersection.isNull ? 0 : intersection.width * intersection.height
        let centerDistance = hypot(frame.midX - safeFrame.midX, frame.midY - safeFrame.midY) * 0.03
        return overlapArea + centerDistance
    }

    private func resolveTargetRect(for target: Target) -> CGRect? {
        guard let summary = Self.findVisibleSummary(in: presentingViewController ?? view.window?.rootViewController) else { return nil }
        summary.loadViewIfNeeded()

        guard let collectionView = summary.collectionView, summary.viewIfLoaded?.window != nil else { return nil }

        summary.view.layoutIfNeeded()
        collectionView.layoutIfNeeded()

        switch target {
        case .exerciseRecommendation:
            let count = collectionView.numberOfItems(inSection: 0)
            for item in 0..<count {
                let indexPath = IndexPath(item: item, section: 0)
                if let cell = visibleCell(at: indexPath, in: collectionView) as? RecommendationCollectionViewCell {
                    return rectForTargetView(cell.contentView)
                }
            }
            return nil
        case .exerciseStreak:
            let count = collectionView.numberOfItems(inSection: 0)
            for item in 0..<count {
                let indexPath = IndexPath(item: item, section: 0)
                if let cell = visibleCell(at: indexPath, in: collectionView) as? StreakCollectionViewCell {
                    return rectForTargetView(cell.contentView)
                }
            }
            return nil
        case .awards:
            return rectForCell(
                at: IndexPath(item: 1, section: 2),
                in: collectionView
            ) { cell in
                cell as? AwardsCollectionViewCell
            } targetView: { (cell: AwardsCollectionViewCell) in
                cell.contentView
            }
        }
    }

    private func rectForCell<Cell: UICollectionViewCell>(
        at indexPath: IndexPath,
        in collectionView: UICollectionView,
        matcher: (UICollectionViewCell) -> Cell?,
        targetView: (Cell) -> UIView
    ) -> CGRect? {
        guard let cell = visibleCell(at: indexPath, in: collectionView) else { return nil }
        guard let matchedCell = matcher(cell) else { return nil }
        return rectForTargetView(targetView(matchedCell))
    }

    private func rectForCells<Cell: UICollectionViewCell>(
        at indexPaths: [IndexPath],
        in collectionView: UICollectionView,
        matcher: (UICollectionViewCell) -> Cell?,
        targetView: (Cell) -> UIView
    ) -> CGRect? {
        var unionRect: CGRect?

        for indexPath in indexPaths {
            guard let cell = visibleCell(at: indexPath, in: collectionView) else { continue }
            guard let matchedCell = matcher(cell) else { continue }

            let rect = rectForTargetView(targetView(matchedCell))
            unionRect = unionRect == nil ? rect : unionRect?.union(rect)
        }

        return unionRect
    }

    private func visibleCell(at indexPath: IndexPath, in collectionView: UICollectionView) -> UICollectionViewCell? {
        UIView.performWithoutAnimation {
            collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            collectionView.superview?.layoutIfNeeded()
            collectionView.layoutIfNeeded()
        }
        collectionView.layoutIfNeeded()
        return collectionView.cellForItem(at: indexPath)
    }

    private func rectForTargetView(_ targetView: UIView) -> CGRect {
        let rectInOverlay = view.convert(targetView.bounds, from: targetView)
        return rectInOverlay.integral
    }

    private func normalizedText(_ text: String?) -> String {
        (text ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }

    private func drawArrow(from calloutFrame: CGRect, to spotlightRect: CGRect, target: Target) {
        let startPoint: CGPoint
        let endPoint: CGPoint

        if calloutFrame.maxY < spotlightRect.minY {
            startPoint = CGPoint(x: calloutFrame.midX, y: calloutFrame.maxY + 4)
            endPoint = arrowEndPoint(for: target, spotlightRect: spotlightRect, fallback: CGPoint(x: spotlightRect.midX, y: spotlightRect.minY - 6))
        } else if calloutFrame.minY > spotlightRect.maxY {
            startPoint = CGPoint(x: calloutFrame.midX, y: calloutFrame.minY - 4)
            endPoint = arrowEndPoint(for: target, spotlightRect: spotlightRect, fallback: CGPoint(x: spotlightRect.midX, y: spotlightRect.maxY + 6))
        } else if calloutFrame.maxX < spotlightRect.minX {
            startPoint = CGPoint(x: calloutFrame.maxX + 4, y: calloutFrame.midY)
            endPoint = arrowEndPoint(for: target, spotlightRect: spotlightRect, fallback: CGPoint(x: spotlightRect.minX - 6, y: spotlightRect.midY))
        } else {
            startPoint = CGPoint(x: calloutFrame.minX - 4, y: calloutFrame.midY)
            endPoint = arrowEndPoint(for: target, spotlightRect: spotlightRect, fallback: CGPoint(x: spotlightRect.maxX + 6, y: spotlightRect.midY))
        }

        let controlOffsetX = (endPoint.x - startPoint.x) * 0.45
        let controlOffsetY = (endPoint.y - startPoint.y) * 0.45

        let controlPoint1 = CGPoint(x: startPoint.x + controlOffsetX, y: startPoint.y)
        let controlPoint2 = CGPoint(x: endPoint.x - controlOffsetX, y: endPoint.y - controlOffsetY)

        let path = UIBezierPath()
        path.move(to: startPoint)
        path.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        appendArrowHead(to: path, tip: endPoint, tailReference: controlPoint2)
        arrowLayer.path = path.cgPath
    }

    private func arrowEndPoint(for target: Target, spotlightRect: CGRect, fallback: CGPoint) -> CGPoint {
        switch target {
        case .exerciseRecommendation:
            return CGPoint(x: spotlightRect.midX, y: spotlightRect.minY + 4)
        case .exerciseStreak:
            return fallback
        case .awards:
            return CGPoint(x: spotlightRect.midX, y: spotlightRect.minY + 6)
        }
    }

    private func appendArrowHead(to path: UIBezierPath, tip: CGPoint, tailReference: CGPoint) {
        let dx = tip.x - tailReference.x
        let dy = tip.y - tailReference.y
        let angle = atan2(dy, dx)
        let length: CGFloat = 10
        let spread: CGFloat = .pi / 7

        let pointA = CGPoint(
            x: tip.x - cos(angle - spread) * length,
            y: tip.y - sin(angle - spread) * length
        )
        let pointB = CGPoint(
            x: tip.x - cos(angle + spread) * length,
            y: tip.y - sin(angle + spread) * length
        )

        path.move(to: tip)
        path.addLine(to: pointA)
        path.move(to: tip)
        path.addLine(to: pointB)
    }

    private func makeCalloutView(for callout: Callout) -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 280, height: 120))
        container.backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = callout.title
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor(red: 1.0, green: 0.62, blue: 0.22, alpha: 1.0)
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)

        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.text = callout.body
        bodyLabel.textAlignment = .center
        bodyLabel.numberOfLines = 0
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.96)
        bodyLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8

        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    private static func findVisibleSummary(in viewController: UIViewController?) -> SummaryViewController? {
        guard let viewController else { return nil }

        if let summary = viewController as? SummaryViewController, summary.viewIfLoaded?.window != nil {
            return summary
        }
        if let navigationController = viewController as? UINavigationController {
            if let visible = findVisibleSummary(in: navigationController.visibleViewController) {
                return visible
            }
            for child in navigationController.viewControllers {
                if let summary = findVisibleSummary(in: child) {
                    return summary
                }
            }
        }
        if let tabBarController = viewController as? UITabBarController {
            if let selected = findVisibleSummary(in: tabBarController.selectedViewController) {
                return selected
            }
            for child in tabBarController.viewControllers ?? [] {
                if let summary = findVisibleSummary(in: child) {
                    return summary
                }
            }
        }
        for child in viewController.children {
            if let summary = findVisibleSummary(in: child) {
                return summary
            }
        }
        if let presented = viewController.presentedViewController {
            return findVisibleSummary(in: presented)
        }

        return nil
    }

    @objc private func handleNext() {
        if !hasDismissedIntroChrome {
            hasDismissedIntroChrome = true
            UIView.animate(withDuration: 0.2) {
                self.pageControl.alpha = 0
                self.hintLabel.alpha = 0
            }
        }

        if currentStepIndex < steps.count - 1 {
            currentStepIndex += 1
        } else {
            completeOverlay()
        }
    }

    @IBAction func skipTapped(_ sender: UIButton) {
        return
    }

    private func completeOverlay() {
        UserDefaults.standard.set(true, forKey: Self.lastShownBuildKey)
        dismiss(animated: true) {
            NotificationCenter.default.post(name: Self.didFinishNotification, object: nil)
        }
    }
}
