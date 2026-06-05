import UIKit
import SwiftUI

class SummaryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    
    private let dailyExercisesCount = 4
    private var allExercises: [ExerciseInfo] = [
        ExerciseInfo(id: "SmoothPursuit", title: "Smooth Pursuits", description: "Slowly follow a moving ball with your eyes to keep your vision steady.", iconName: "SmoothPursuits", segueIdentifier: "ShowSmoothPursuits", estimatedTimeSeconds: 135),
        ExerciseInfo(id: "SaccadicJump", title: "Saccadic Jumps", description: "Practice switching between directions with ease", iconName: "SaccadicJumps", segueIdentifier: "ShowSaccadicJump", estimatedTimeSeconds: 70),
        ExerciseInfo(id: "PencilPushup", title: "Pencil Push-Ups", description: "Train your eyes to work together as a team so you can see close-up things without strain.", iconName: "PencilPushUps", segueIdentifier: "ShowPencilPushUps", estimatedTimeSeconds: 60),
        ExerciseInfo(id: "Figure8", title: "Figure Eight", description: "Trace a loopy path with your eyes to boost flexibility and make focusing feel easier.", iconName: "FigureEight", segueIdentifier: "ShowFigureEight", estimatedTimeSeconds: 90),
        ExerciseInfo(id: "Blink", title: "Blink Training", description: "Take a moment for full, slow blinks to refresh your eyes and keep them from getting dry.", iconName: "BlinkTraining", segueIdentifier: "ShowBlinkTraining", estimatedTimeSeconds: 90),
        ExerciseInfo(id: "NearFar", title: "Near Far Focus", description: "Switch focus between close and distant objects to help your eyes adjust faster.", iconName: "NearFarFocus", segueIdentifier: "ShowNearFarFocus", estimatedTimeSeconds: 110)
    ]
    
    // MARK: - Data Properties for Trends
    var accuracyTrends: [TrendData] = []
    var accuracyAverage: String = "0"
    
    var responsivenessTrends: [TrendData] = []
    var responsivenessAverage: String = "0"
    
    var eyeTestTrends: [TrendData] = []
    var eyeTestAverage: String = "0"
    
    var osdiTrends: [TrendData] = []
    var osdiAverage: String = "0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        navigationController?.setNavigationBarHidden(false, animated: animated)
//        navigationController?.navigationBar.prefersLargeTitles = false
//        navigationItem.largeTitleDisplayMode = .never
//
//        let appearance = UINavigationBarAppearance()
//        appearance.configureWithOpaqueBackground()
//        appearance.backgroundColor = .black
//        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
//        navigationController?.navigationBar.standardAppearance = appearance
//        navigationController?.navigationBar.scrollEdgeAppearance = appearance
//        navigationController?.navigationBar.compactAppearance = appearance
//        navigationController?.navigationBar.tintColor = .white
        // Fetch the data right before reloading.
        let user = SwiftDataManager.shared.getOrCreateUser()
        user.dailyExerciseGoal = user.calculateDailyGoalFromRecommendations()
        try? SwiftDataManager.shared.context.save()
        
        loadTrendsData()
        updateDailyExerciseProgressIfNeeded()
            
        // Reloads the data so the gauge updates immediately when returning from an exercise
        collectionView.reloadData()
        
        setupBackground()
        
        collectionView
            .register(
                UICollectionReusableView.self,
                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                withReuseIdentifier: "HeaderView"
            )
        collectionView
            .register(
                UINib(nibName: "DailyExerciseCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "DailyExerciseCell"
            )
        collectionView
            .register(
                UINib(nibName: "AwardsCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "AwardsCell"
            )
        collectionView.register(
            UINib(nibName: "TrendsAllCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: TrendsAllCollectionViewCell.identifier
        )
        collectionView
            .register(
                UINib(nibName: "StreakCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "StreakCell"
            )
        
        collectionView
            .register(
                UINib(nibName: "PageLinkCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "ExerciseTestCell"
            )

        // Same card UI as the exercise screen
        collectionView.register(
            UINib(nibName: "ExerciseCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: "ExerciseCell"
        )

        // Recommendation card (XIB-based)
        collectionView.register(
            UINib(nibName: "RecommendationCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: RecommendationCollectionViewCell.reuseIdentifier
        )
        
        collectionView.collectionViewLayout = createLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    private func loadTrendsData() {
        // Fetch Exercise Accuracy
        let accuracyResult = TrendDataManager.shared.getExerciseAccuracyTrends()
        self.accuracyAverage = accuracyResult.average
        self.accuracyTrends = accuracyResult.data
        
        // Fetch Eye Responsiveness
        let responsivenessResult = TrendDataManager.shared.getEyeResponsivenessTrends()
        self.responsivenessAverage = responsivenessResult.average
        self.responsivenessTrends = responsivenessResult.data
        
        // Fetch Eye Test Scores (Full Checkup)
        let testResult = TrendDataManager.shared.getEyeTestTrends()
        self.eyeTestAverage = testResult.average
        self.eyeTestTrends = testResult.data
        
        // Fetch OSDI Scores
        let osdiResult = TrendDataManager.shared.getOSDITrends()
        self.osdiAverage = osdiResult.average
        self.osdiTrends = osdiResult.data
    }

    private func trendSubtitle(average: String, suffix: String, data: [TrendData], emptyPrompt: String) -> String {
        guard data.hasRecordedTrendData else { return emptyPrompt }
        return "\(average)\(suffix)"
    }
    
    private func setupBackground() {
        let bgImageView = UIImageView(
            image: UIImage(named: "BackgroundGradient")
        )
        bgImageView.contentMode = .scaleAspectFill
        self.collectionView.backgroundView = bgImageView
        self.collectionView.backgroundColor = .clear
    }
    
    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] (
            sectionIndex,
            layoutEnv
        ) -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }
            
            // MARK: - Shared Header
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(50)
            )
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            
            if sectionIndex == 0 {
                // MARK: - Section 0 (TestReminder + Recommendation + streak)
                var subitems: [NSCollectionLayoutItem] = []
                var groupHeight: CGFloat = 0
                
                let recItemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(145)
                )
                let streakItemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(130)
                )

                if self.isTestDue() {
                    let testReminderItem = NSCollectionLayoutItem(layoutSize: recItemSize)
                    testReminderItem.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
                    subitems.append(testReminderItem)
                    groupHeight += 145
                }
                
                let completed = self.completedDailyExercises()
                if completed.count < self.dailyExercisesCount {
                    let recItem = NSCollectionLayoutItem(layoutSize: recItemSize)
                    recItem.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
                    subitems.append(recItem)
                    groupHeight += 145
                }
                
                let streakItem = NSCollectionLayoutItem(layoutSize: streakItemSize)
                streakItem.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
                subitems.append(streakItem)
                groupHeight += 130

                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(groupHeight)
                )

                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: subitems
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)
                section.boundarySupplementaryItems = [sectionHeader]

                return section
                
            } else if sectionIndex == 1 {
                // MARK: - Section 1 (Exercise Test Entry)
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                
                // Height is 0.3 of the 200px awards block -> 70px
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(70)
                )
                
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
                
                return section
                
            } else if sectionIndex == 2 {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.50),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(210)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 4, trailing: 4)
                
                return section
                
            } else {
                // MARK: - Section 3 (Trends 2x2 Grid with Background)
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.50),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(70)
                )
                
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitem: item,
                    count: 2
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 44, trailing: 4)
                
                let tighterHeaderSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(45)
                )
                let tighterHeader = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: tighterHeaderSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [tighterHeader]
                
                let backgroundDecoration = NSCollectionLayoutDecorationItem.background(elementKind: "SectionBackground")
                backgroundDecoration.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 8, bottom: 20, trailing: 8)
                section.decorationItems = [backgroundDecoration]
                
                return section
            }
        }
        
        layout.register(RoundedBackgroundDecorationView.self, forDecorationViewOfKind: "SectionBackground")
        
        return layout
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "HeaderView",
            for: indexPath
        )
        header.subviews.forEach { $0.removeFromSuperview() }
        
        let label = UILabel()
        
        // Trends is now Section 3
        if indexPath.section == 3 {
            label.frame = CGRect(
                x: 16,
                y: 10,
                width: header.frame.width - 32,
                height: 24
            )
            label.text = "Trends"
            label.font = UIFont.systemFont(ofSize: 24, weight: .bold, width: .expanded)
        }
        
        label.textColor = .white
        header.addSubview(label)
        return header
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        // Sections: 0 (Today's exercise + streak), 1 (Exercise page link), 2 (Daily), 3 (Trends)
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            var count = 1
            let completed = completedDailyExercises()
            if completed.count < dailyExercisesCount { count += 1 }
            if isTestDue() { count += 1 }
            return count
        } else if section == 1 {
            return 1 // Exercise Test Entry
        } else if section == 2 {
            return 2 // Daily Goals & Awards (reverted back to original 2 items)
        }
        // Return 4 items for the Trends grid
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let testDue = isTestDue()
            let completed = completedDailyExercises()
            let recDue = completed.count < dailyExercisesCount
            
            var items: [String] = []
            if testDue { items.append("test") }
            if recDue { items.append("rec") }
            items.append("streak")
            
            let currentItemType = items[indexPath.item]
            
            if currentItemType == "streak" {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "StreakCell",
                    for: indexPath
                ) as! StreakCollectionViewCell

                let user = SwiftDataManager.shared.getOrCreateUser()
                user.updateTodayStreakStatus()
                let streakData = ExerciseDataManager.shared.fetchWeeklyStreak()

                cell.configure(with: streakData, currentStreak: user.currentStreak)
                return cell
            } else if currentItemType == "test" {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: RecommendationCollectionViewCell.reuseIdentifier,
                    for: indexPath
                ) as! RecommendationCollectionViewCell

                let state = getCheckupState()
                let titleText: String
                let reasonText: String
                let iconName: String
                
                if state == .OSDIDue {
                    titleText = "OSDI"
                    reasonText = "Hey check-in time. Let's see how your eyes have been feeling"
                    iconName = "doc.text.fill"
                } else {
                    titleText = "C Test"
                    reasonText = "Nice work on the OSDI! One more let's check how sharp your focus is today"
                    iconName = "eye.fill"
                }

                let testReminder = ExerciseInfo(
                    id: "TestReminder",
                    title: titleText,
                    description: "",
                    iconName: iconName,
                    segueIdentifier: "",
                    estimatedTimeSeconds: 0
                )
                cell.configure(with: testReminder, reason: reasonText)
                return cell
            } else { // "rec"
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: RecommendationCollectionViewCell.reuseIdentifier,
                    for: indexPath
                ) as! RecommendationCollectionViewCell

                if let exercise = currentDailyExercise() {
                    cell.configure(
                        with: exercise,
                        reason: getDynamicDescription(for: exercise.id)
                    )
                } else {
                    let fallback = ExerciseInfo(
                        id: "fallback",
                        title: "Today's Exercise",
                        description: "",
                        iconName: "BlinkTraining",
                        segueIdentifier: "",
                        estimatedTimeSeconds: 600
                    )
                    cell.configure(with: fallback, reason: "Take a gentle moment to refresh your eyes and nurture your daily visual wellness streak.")
                }

                return cell
            }
        } else if indexPath.section == 1 {
            // MARK: - Section 1 (Exercise Test Entry)
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "ExerciseTestCell",
                for: indexPath
            ) as! PageLinkCollectionViewCell
            
            cell.configure(Name:  "Exercises")
            return cell
            
        } else if indexPath.section == 2 {
            // MARK: - Section 2 (Daily Goals & Awards)
            switch indexPath.item {
            case 0:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "DailyExerciseCell",
                    for: indexPath
                ) as! DailyExerciseCollectionViewCell
                
                let user = SwiftDataManager.shared.getOrCreateUser()
                user.updateTodayStreakStatus()
                let todayRecord = ExerciseDataManager.shared.fetchTodayRecord()
                var completedSeconds = todayRecord.completedSeconds
                let goalSeconds = todayRecord.goalSeconds
                
                let todayCompleted = user.streak.first(where: { Calendar.current.isDateInToday($0.date) })?.isCompleted ?? false
                if todayCompleted {
                    completedSeconds = max(completedSeconds, goalSeconds)
                }
                
                cell.configure(currentSeconds: completedSeconds, goalSeconds: goalSeconds)
                return cell
            default:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "AwardsCell",
                    for: indexPath
                ) as! AwardsCollectionViewCell
                cell.configure(name: "Awards", date: "  ", image: "trophy.circle")
                return cell
            }
            
        } else {
            // MARK: - Updated Trends Data Binding
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TrendsAllCollectionViewCell.identifier,
                for: indexPath
            ) as! TrendsAllCollectionViewCell
            
            // Map the data into the 4 grid items
            switch indexPath.item {
            case 0:
                cell.configure(
                    title: "Accuracy",
                    subtitle: trendSubtitle(
                        average: accuracyAverage,
                        suffix: "% avg",
                        data: accuracyTrends,
                        emptyPrompt: "Complete exercise to get data"
                    ),
                    color: .accent,
                    iconName: "target",
                    isEmptyState: !accuracyTrends.hasRecordedTrendData
                )
            case 1:
                cell.configure(
                    title: "Responsiveness",
                    subtitle: trendSubtitle(
                        average: responsivenessAverage,
                        suffix: "s avg",
                        data: responsivenessTrends,
                        emptyPrompt: "Complete exercise to get data"
                    ),
                    color: .accent,
                    iconName: "bolt.fill",
                    isEmptyState: !responsivenessTrends.hasRecordedTrendData
                )
            case 2:
                cell.configure(
                    title: "C Test Score",
                    subtitle: trendSubtitle(
                        average: eyeTestAverage,
                        suffix: " score",
                        data: eyeTestTrends,
                        emptyPrompt: "Complete C Test to get data"
                    ),
                    color: .accent,
                    iconName: "eye.fill",
                    isEmptyState: !eyeTestTrends.hasRecordedTrendData
                )
            case 3:
                cell.configure(
                    title: "OSDI Score",
                    subtitle: trendSubtitle(
                        average: osdiAverage,
                        suffix: " score",
                        data: osdiTrends,
                        emptyPrompt: "Complete OSDI to get data"
                    ),
                    color: .accent,
                    iconName: "doc.text.fill",
                    isEmptyState: !osdiTrends.hasRecordedTrendData
                )
            default:
                break
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let testDue = isTestDue()
            let completed = completedDailyExercises()
            let recDue = completed.count < dailyExercisesCount
            
            var items: [String] = []
            if testDue { items.append("test") }
            if recDue { items.append("rec") }
            items.append("streak")
            
            let currentItemType = items[indexPath.item]
            
            if currentItemType == "test" {
                let state = getCheckupState()
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if state == .OSDIDue {
                    if let vc = storyboard.instantiateViewController(withIdentifier: "OSDIViewController") as? OSDIViewController {
                        vc.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(vc, animated: true)
                    }
                } else if state == .CTestDue {
                    if let vc = storyboard.instantiateViewController(withIdentifier: "LandoltCViewController") as? LandoltCViewController {
                        vc.hidesBottomBarWhenPushed = true
                        navigationController?.pushViewController(vc, animated: true)
                    }
                }
            } else if currentItemType == "rec" {
                guard let exercise = currentDailyExercise() else { return }
                launchExercise(exercise)
            } else if currentItemType == "streak" {
                let user = SwiftDataManager.shared.getOrCreateUser()
                user.updateTodayStreakStatus()
                let todayCompleted = user.streak.first(where: { Calendar.current.isDateInToday($0.date) })?.isCompleted ?? false
                if !todayCompleted {
                } else {
                    let alert = UIAlertController(
                        title: "Goal Completed!",
                        message: "Yay, you did it! Your daily goal is complete. Your eyes thank you!",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "Hooray!", style: .default))
                    present(alert, animated: true)
                }
            }
            return
        }
        // Section 2: Daily Goals & Strains
        else if indexPath.section == 2 {
            if indexPath.item == 1 {
                let storyboard = UIStoryboard(name: "Summary", bundle: nil)
                if let vc = storyboard.instantiateViewController(withIdentifier: "AwardsViewController") as? AwardsViewController {
                    navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
        // MARK: - Section 1: Exercise Tests Navigation
        else if indexPath.section == 1 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "ExerciseViewController")
            navigationController?.pushViewController(vc, animated: true)
        }
        // MARK: - Section 3: Trends Navigation
        else if indexPath.section == 3 {
            // Instantiate your new SwiftUI-powered detail view
            let trendsDetailVC = TrendsDetailViewController()
            
            // Push it onto the navigation stack
            navigationController?.pushViewController(trendsDetailVC, animated: true)
        }
    }
}

// MARK: - Daily exercise sequencing (one at a time)
extension SummaryViewController {
    struct Keys {
        static let dayStamp = "summary.dailyExercises.dayStamp"
        static let completedIds = "summary.dailyExercises.completedIds"
        static let weeklyStamp = "summary.dailyExercises.weeklyStamp"
        static let weeklyPool = "summary.dailyExercises.weeklyPool"
        static let lastLaunchExerciseId = "summary.dailyExercises.lastLaunchExerciseId"
        static let lastLaunchCompletedSeconds = "summary.dailyExercises.lastLaunchCompletedSeconds"
    }
    
    // MARK: - Bi-Weekly Checkup State Machine
    enum CheckupState {
        case notDue
        case OSDIDue
        case CTestDue
    }

    func getCheckupState() -> CheckupState {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let lastOSDI = user.osdiSessions.map { $0.date }.max()
        let lastCTest = user.eyeTestSessions.map { $0.startingTime }.max()
        
        // If there are absolutely no sessions, OSDI is due first
        if lastOSDI == nil && lastCTest == nil {
            return .OSDIDue
        }
        
        // If OSDI has been taken but C-Test hasn't
        if let _ = lastOSDI, lastCTest == nil {
            return .CTestDue
        }
        
        // If C-Test has been taken but OSDI hasn't
        if let _ = lastCTest, lastOSDI == nil {
            return .OSDIDue
        }
        
        // If both exist
        if let osdiDate = lastOSDI, let ctestDate = lastCTest {
            // If the latest OSDI is newer than the latest C-Test, it means the user is in the middle of a checkup cycle
            if osdiDate > ctestDate {
                return .CTestDue
            }
            
            // If the latest is C-Test, check if 14 days have passed since completion to start a new checkup cycle
            let calendar = Calendar.current
            if let days = calendar.dateComponents([.day], from: ctestDate, to: Date()).day, days >= 14 {
                return .OSDIDue
            }
            
            return .notDue
        }
        
        return .notDue
    }

    func isTestDue() -> Bool {
        return getCheckupState() != .notDue
    }
    
    
    private func getDynamicDescription(for id: String) -> String {
        let reasons: [String]
        switch id {
        case "Blink":
            reasons = [
                "Your eyes are basically begging for a blink break right now. Let's hydrate them! 💧",
                "Screen time got your eyes feeling dry? Blink Training is literally a spa day for your eyeballs.",
                "Five minutes of blinking practice and your eyes will feel SO much better. Trust me."
            ]
        case "NearFar":
            reasons = [
                "Near, far — it's like gym for your eyes but way more fun (and less sweaty).",
                "Shifting focus near and far is one of the best things you can do after staring at a screen.",
                "Your eye muscles need variety too! Let's give them a little stretch."
            ]
        case "SaccadicJump":
            reasons = [
                "Think of this like eye agility training — snap, snap, snap! Super satisfying.",
                "Quick eye movements = sharper, faster focus. This one's actually pretty fun to do.",
                "Let's train your eyes to react faster."
            ]
        case "SmoothPursuit":
            reasons = [
                "Follow the dot with your eyes — smooth and steady wins the race here.",
                "This one's actually kinda relaxing. Just let your eyes glide along the path.",
                "Great for keeping your eye tracking smooth. Feels like meditation but for your eyes."
            ]
        case "Figure8":
            reasons = [
                "Trace an infinity loop with your eyes — it's weirdly satisfying and really good for flexibility.",
                "Figure eights are low-key the best stretch for your eye muscles. Sneaky effective!",
                "A chill, loopy exercise that keeps your eyes nimble and happy."
            ]
        case "PencilPushup":
            reasons = [
                "Watch the target move closer — your eyes will learn to team up and focus together.",
                "This is great for when your eyes feel a bit crossed or strained from close-up work.",
                "Train both eyes to focus on the same spot."
            ]
        default:
            reasons = ["Let's knock out today's eye exercise and keep that streak alive! 🔥"]
        }
        
        return reasons.randomElement() ?? reasons[0]
    }
    
    private func currentDailyExercise() -> ExerciseInfo? {
        let pool = weeklyExercisePool()
        let completed = completedDailyExercises()
        let remaining = pool.filter { !completed.contains($0.id) }
        return remaining.first
    }
    
    func completedDailyExercises() -> [String] {
        resetDayIfNeeded()
        return UserDefaults.standard.stringArray(forKey: Keys.completedIds) ?? []
    }
    
    func markExerciseCompleted(_ id: String) {
        resetDayIfNeeded()
        var completed = UserDefaults.standard.stringArray(forKey: Keys.completedIds) ?? []
        guard !completed.contains(id) else { return }
        completed.append(id)
        UserDefaults.standard.set(completed, forKey: Keys.completedIds)
    }
    
    func updateDailyExerciseProgressIfNeeded() {
        resetDayIfNeeded()
        
        guard let lastId = UserDefaults.standard.string(forKey: Keys.lastLaunchExerciseId) else { return }
        
        let wasSuccessful = UserDefaults.standard.bool(forKey: "summary.dailyExercises.lastLaunchSuccess")
        let baselineSeconds = UserDefaults.standard.integer(forKey: Keys.lastLaunchCompletedSeconds)
        let todayRecord = ExerciseDataManager.shared.fetchTodayRecord()
        let delta = todayRecord.completedSeconds - baselineSeconds
        
        if wasSuccessful || delta >= 30 {
            markExerciseCompleted(lastId)
            _ = ProgressManager.shared.evaluateAndUnlock()
        }
        
        UserDefaults.standard.removeObject(forKey: Keys.lastLaunchExerciseId)
        UserDefaults.standard.removeObject(forKey: Keys.lastLaunchCompletedSeconds)
        UserDefaults.standard.removeObject(forKey: "summary.dailyExercises.lastLaunchSuccess")
    }
    
    func resetDayIfNeeded() {
        let stamp = dayStamp()
        let existing = UserDefaults.standard.string(forKey: Keys.dayStamp)
        if existing != stamp {
            UserDefaults.standard.set(stamp, forKey: Keys.dayStamp)
            UserDefaults.standard.set([], forKey: Keys.completedIds)
            UserDefaults.standard.removeObject(forKey: Keys.lastLaunchExerciseId)
            UserDefaults.standard.removeObject(forKey: Keys.lastLaunchCompletedSeconds)
            
            let user = SwiftDataManager.shared.getOrCreateUser()
            user.checkDailyReset()
        }
    }
    
    private func weeklyExercisePool() -> [ExerciseInfo] {
        let stamp = weekStamp()
        let existing = UserDefaults.standard.string(forKey: Keys.weeklyStamp)
        if existing != stamp {
            let pool = buildWeeklyPool()
            UserDefaults.standard.set(stamp, forKey: Keys.weeklyStamp)
            UserDefaults.standard.set(pool.map(\.id), forKey: Keys.weeklyPool)
            return pool
        }
        
        if let storedIds = UserDefaults.standard.stringArray(forKey: Keys.weeklyPool), !storedIds.isEmpty {
            let byId = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.id, $0) })
            let mapped = storedIds.compactMap { byId[$0] }
            if mapped.count >= dailyExercisesCount { return Array(mapped.prefix(dailyExercisesCount)) }
        }
        
        return buildWeeklyPool()
    }
    
    private func buildWeeklyPool() -> [ExerciseInfo] {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let recommendedIds = user.recommendedExercises
        let byId = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.id, $0) })
        
        var pool: [ExerciseInfo] = []
        for id in recommendedIds {
            if let ex = byId[id], !pool.contains(where: { $0.id == ex.id }) {
                pool.append(ex)
            }
        }
        for ex in allExercises where !pool.contains(where: { $0.id == ex.id }) {
            pool.append(ex)
        }
        
        return Array(pool.prefix(dailyExercisesCount))
    }
    
    private func launchExercise(_ exercise: ExerciseInfo) {
        let todayRecord = ExerciseDataManager.shared.fetchTodayRecord()
        UserDefaults.standard.set(exercise.id, forKey: Keys.lastLaunchExerciseId)
        UserDefaults.standard.set(todayRecord.completedSeconds, forKey: Keys.lastLaunchCompletedSeconds)
        
        let vc = instantiateExerciseViewController(for: exercise)
        vc?.hidesBottomBarWhenPushed = true
        if let vc {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    private func instantiateExerciseViewController(for exercise: ExerciseInfo) -> UIViewController? {
        switch exercise.id {
        case "SaccadicJump":
            return UIStoryboard(name: "SaccadicJumps", bundle: nil).instantiateViewController(withIdentifier: "SaccadicJumpsVC")
        case "SmoothPursuit":
            return UIStoryboard(name: "SmoothPursits", bundle: nil).instantiateViewController(withIdentifier: "SmoothPursuitsVC")
        case "PencilPushup":
            return UIStoryboard(name: "PencilPushUp", bundle: nil).instantiateViewController(withIdentifier: "PencilPushUpVC")
        case "Figure8":
            return UIStoryboard(name: "FigureEight", bundle: nil).instantiateViewController(withIdentifier: "FigureEightVC")
        case "NearFar":
            return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NearFarFocusVC")
        case "Blink":
            return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BlinkTrainingVC")
        default:
            return nil
        }
    }
    
    func dayStamp(date: Date = Date()) -> String {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }
    
    func weekStamp(date: Date = Date()) -> String {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(comps.yearForWeekOfYear ?? 0)-W\(comps.weekOfYear ?? 0)"
    }
}

class RoundedBackgroundDecorationView: UICollectionReusableView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 50% Black
        self.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        // Rounded corners
        self.layer.cornerRadius = 20
        self.clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
