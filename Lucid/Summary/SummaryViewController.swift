import UIKit
import SwiftUI

class SummaryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    
    private let dailyExercisesCount = 4
    private var allExercises: [ExerciseInfo] = [
        ExerciseInfo(id: "SmoothPursuit", title: "Smooth Pursuits", description: "Slowly follow a moving object with your eyes to keep your vision steady and focused.", iconName: "SmoothPursuits", segueIdentifier: "ShowSmoothPursuits", estimatedTimeSeconds: 135),
        ExerciseInfo(id: "SaccadicJump", title: "Saccadic Jumps", description: "Practice jumping your gaze quickly between two spots to build speed and accuracy.", iconName: "SaccadicJumps", segueIdentifier: "ShowSaccadicJump", estimatedTimeSeconds: 70),
        ExerciseInfo(id: "PencilPushup", title: "Pencil Push-Ups", description: "Train your eyes to work together as a team so you can see close-up things without strain.", iconName: "PencilPushUps", segueIdentifier: "ShowPencilPushUps", estimatedTimeSeconds: 60),
        ExerciseInfo(id: "Figure8", title: "Figure Eight", description: "Trace a loopy path with your eyes to boost flexibility and make focusing feel easier.", iconName: "FigureEight", segueIdentifier: "ShowFigureEight", estimatedTimeSeconds: 90),
        ExerciseInfo(id: "Blink", title: "Blink Training", description: "Take a moment for full, slow blinks to refresh your eyes and keep them from getting dry.", iconName: "BlinkTraining", segueIdentifier: "ShowBlinkTraining", estimatedTimeSeconds: 90),
        ExerciseInfo(id: "PeripheralAwareness", title: "Peripheral Awareness", description: "Learn to notice what is happening around you without having to turn your head.", iconName: "PeripheralAwareness", segueIdentifier: "ShowPeripheralAwareness", estimatedTimeSeconds: 75),
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
            return 2 // Daily Goals & Awards (removed digital eye strain & low light usage)
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

                let testReminder = ExerciseInfo(
                    id: "TestReminder",
                    title: "Eye Test ",
                    description: "",
                    iconName: "C-Test",
                    segueIdentifier: "",
                    estimatedTimeSeconds: 0
                )
                cell.configure(with: testReminder, reason: "Time for your biweekly eye test!")
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
                    cell.configure(with: fallback, reason: "Complete an exercise to maintain your daily streak.")
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
                cell.configure(name: ".", date: "." , image: "trophy.circle")
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
                cell.configure(title: "Accuracy", subtitle: "\(accuracyAverage)% AVG", color: .accent, iconName: "target")
            case 1:
                cell.configure(title: "Responsiveness", subtitle: "\(responsivenessAverage)s AVG", color: .accent, iconName: "bolt.fill")
            case 2:
                cell.configure(title: "C Test Score", subtitle: "\(eyeTestAverage) SCORE", color: .accent, iconName: "eye.fill")
            case 3:
                cell.configure(title: "OSDI Score", subtitle: "\(osdiAverage) SCORE", color: .accent, iconName: "doc.text.fill")
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
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "EyeTestStoryBoard")
                navigationController?.pushViewController(vc, animated: true)
            } else if currentItemType == "rec" {
                guard let exercise = currentDailyExercise() else { return }
                launchExercise(exercise)
            } else if currentItemType == "streak" {
                let user = SwiftDataManager.shared.getOrCreateUser()
                user.updateTodayStreakStatus()
                let todayCompleted = user.streak.first(where: { Calendar.current.isDateInToday($0.date) })?.isCompleted ?? false
                if !todayCompleted {
                    if let exercise = currentDailyExercise() {
                        launchExercise(exercise)
                    } else if let fallback = allExercises.first {
                        launchExercise(fallback)
                    }
                } else {
                    let alert = UIAlertController(title: "Goal Completed!", message: "You completed today's goal!", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Awesome", style: .default))
                    present(alert, animated: true)
                }
            }
            return
        }
        // Section 2: Daily Goals & Strains
        else if indexPath.section == 2 {
            if indexPath.item == 0 {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "OSDIViewController")
                navigationController?.pushViewController(vc, animated: true)
            } else if indexPath.item == 1 {
                let storyboard = UIStoryboard(name: "Summary", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "AwardsViewController")
                navigationController?.pushViewController(vc, animated: true)
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
    
    // MARK: - Dynamic Description Generator
    private func isTestDue() -> Bool {
        let user = SwiftDataManager.shared.getOrCreateUser()
        let calendar = Calendar.current
        
        let lastOSDI = user.osdiSessions.map { $0.date }.max() ?? .distantPast
        let lastCTest = user.eyeTestSessions.map { $0.startingTime }.max() ?? .distantPast
        
        let lastTestDate = max(lastOSDI, lastCTest)
        if lastTestDate == .distantPast { return true }
        
        if let days = calendar.dateComponents([.day], from: lastTestDate, to: Date()).day, days >= 14 {
            return true
        }
        return false
    }
    
    private func getDynamicDescription(for id: String) -> String {
        let reasons: [String]
        switch id {
        case "Blink":
            reasons = [
                "Blink fully to refresh and lubricate your eyes.",
                "Slow, complete blinks reduce digital dryness.",
                "A short blink break eases screen fatigue."
            ]
        case "PeripheralAwareness":
            reasons = [
                "Relax tunnel vision by engaging your side view.",
                "Expand your field of view to ease screen tension.",
                "Train peripheral vision to reduce eye strain."
            ]
        case "NearFar":
            reasons = [
                "Switch focus near and far to stay sharp.",
                "Train quick focus shifts for clearer vision.",
                "Prevent focus lock by changing distances."
            ]
        case "SaccadicJump":
            reasons = [
                "Practice quick gaze jumps for speed and accuracy.",
                "Sharp saccades improve reaction and control.",
                "Snap between targets to build precision."
            ]
        case "SmoothPursuit":
            reasons = [
                "Follow smooth motion to steady your gaze.",
                "Gentle tracking builds coordination without strain.",
                "Keep eye movements fluid for visual comfort."
            ]
        case "Figure8":
            reasons = [
                "Trace loops to keep eye muscles flexible.",
                "Figure 8s build endurance and control.",
                "A balanced stretch for smooth eye movement."
            ]
        case "PencilPushup":
            reasons = [
                "Train convergence for easier close-up work.",
                "Strengthen teamwork between your eyes.",
                "Improve near focus to reduce reading strain."
            ]
        default:
            reasons = ["Complete this exercise to maintain your eye health and daily streak."]
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
        case "PeripheralAwareness":
            return UIStoryboard(name: "PeripheralAwareness", bundle: nil).instantiateViewController(withIdentifier: "PeripheralVC")
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
