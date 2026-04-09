//
//  SummaryInsightCollectionViewCell.swift
//  Lucid
//
//  Created by Kanishka Bansal on 13/02/26.
//

import UIKit

// MARK: - Card Type
enum InsightCardType {
    case info
    case exercise
    case test
}

// MARK: - Model
struct ExerciseSuggestion {
    let title: String
    let description: String
    let symbolName: String
    let cardType: InsightCardType
    let nibName: String?
}

// MARK: - Delegate
protocol SummaryInsightCellDelegate: AnyObject {
    func didTapInsightCard(nibName: String, cardType: InsightCardType)
}

// MARK: - Cell
class SummaryInsightCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var badge: UIImageView!
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var descriprtionLabel: UILabel!

    weak var delegate: SummaryInsightCellDelegate?

    private var exercises: [ExerciseSuggestion] = []
    private var timer: Timer?
    private var currentIndex: Int = 0
    private var isTestDue: Bool = false

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupTapGesture()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopTimer()
        currentIndex = 0
    }

    deinit {
        stopTimer()
    }

    // MARK: - Public Entry Points
    func startDisplaying(isTestDue: Bool) {
        self.isTestDue = isTestDue
        buildExerciseList(isTestDue: isTestDue)

        if isTestDue {
            // Pin to test card, no rotation
            currentIndex = 1
            showExercise(at: currentIndex)
        } else {
            currentIndex = 0
            showExercise(at: currentIndex)
            startRotationTimer()
        }
    }

    func stopDisplaying() {
        stopTimer()
    }

    // MARK: - Build List
    private func buildExerciseList(isTestDue: Bool) {
        var list: [ExerciseSuggestion] = [
            ExerciseSuggestion(
                title: "Excellent Work!!!",
                description: "Your Overall Eye Health Score improved by 5 points this month, moving you closer to the ideal 100.",
                symbolName: "medal.fill",
                cardType: .info,
                nibName: nil
            ),
            ExerciseSuggestion(
                title: "Blink Training 👁️",
                description: "Tap to start your blink training session. Keeps your eyes lubricated and reduces strain.\n",
                symbolName: "eye.circle.fill",
                cardType: .exercise,
                nibName: "blinkTrainingViewController"
            ),
            ExerciseSuggestion(
                title: "Eye Exercises",
                description: "Tap to begin your eye exercise routine. Strengthens eye muscles and improves flexibility.",
                symbolName: "figure.mind.and.body",
                cardType: .exercise,
                nibName: "EyeExercisesTViewController"
            ),
            ExerciseSuggestion(
                title: "Near-Far Focus",
                description: "Tap to start near-far focus training. Improves your eye's ability to shift focus quickly.\n",
                symbolName: "scope",
                cardType: .exercise,
                nibName: "nearFarFocusViewController"
            ),
            ExerciseSuggestion(
                title: "20-20-20 Rule 👁️",
                description: "Look at something 20 feet away for 20 seconds. Do this now to reduce eye strain.\n",
                symbolName: "eye.fill",
                cardType: .info,
                nibName: nil
            ),
            ExerciseSuggestion(
                title: "Palming Rest",
                description: "Rub your palms together and cup them over closed eyes for 30 seconds. Relieves tension.\n",
                symbolName: "hand.raised.fill",
                cardType: .info,
                nibName: nil
            )
        ]

        if isTestDue {
            let testCard = ExerciseSuggestion(
                title: "Time for Your Eye Test! 🧪",
                description: "Your biweekly eye test is due. Tap to start all 3 tests now.\n",
                symbolName: "checklist.checked",
                cardType: .test,
                nibName: "TestMenu"
            )
            list.insert(testCard, at: 1)
        }

        self.exercises = list
    }

    // MARK: - UI Setup
    private func setupUI() {
        containerView.layer.cornerRadius = 20
        containerView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        containerView.clipsToBounds = true
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(tap)
        containerView.isUserInteractionEnabled = true
    }

    // MARK: - Tap Handler
    @objc private func handleTap() {
        guard currentIndex < exercises.count else { return }
        let current = exercises[currentIndex]
        guard let nibName = current.nibName else { return }
        delegate?.didTapInsightCard(nibName: nibName, cardType: current.cardType)
    }

    // MARK: - Timer
    private func startRotationTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.showNextExercise()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Rotation
    private func showNextExercise() {
        currentIndex = (currentIndex + 1) % exercises.count
        animateTransition {
            self.showExercise(at: self.currentIndex)
        }
    }

    // MARK: - Display
    private func showExercise(at index: Int) {
        guard index < exercises.count else { return }
        let exercise = exercises[index]

        headingLabel.text = exercise.title
        descriprtionLabel.text = exercise.description

        let config = UIImage.SymbolConfiguration.preferringMulticolor
        badge.image = UIImage(systemName: exercise.symbolName, withConfiguration: config())

        // Orange border for tappable cards
        let isTappable = exercise.nibName != nil
        UIView.animate(withDuration: 0.2) {
            self.containerView.layer.borderWidth = isTappable ? 1.0 : 0.0
            self.containerView.layer.borderColor = isTappable
                ? UIColor.orange.withAlphaComponent(0.6).cgColor
                : UIColor.clear.cgColor
        }
    }

    // MARK: - Animation
    private func animateTransition(updates: @escaping () -> Void) {
        UIView.transition(
            with: containerView,
            duration: 0.4,
            options: .transitionCrossDissolve,
            animations: updates,
            completion: nil
        )
    }

    // MARK: - configure (kept for compatibility but does NOT stop timer)
    func configure(name: String, description: String) {
        headingLabel.text = name
        descriprtionLabel.text = description
        let config = UIImage.SymbolConfiguration.preferringMulticolor
        badge.image = UIImage(systemName: "medal.fill", withConfiguration: config())
    }
}
