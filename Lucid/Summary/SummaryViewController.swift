import UIKit
import SwiftUI

class SummaryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    
    // MARK: - State Properties
    var isAlertDismissed: Bool = false // Tracks if the insight alert has been closed
    
    // MARK: - Data Properties for Trends
    var accuracyTrends: [TrendData] = []
    var accuracyAverage: String = "0"
    
    var eyeTestTrends: [TrendData] = []
    var eyeTestAverage: String = "0"
    
    var osdiTrends: [TrendData] = []
    var osdiAverage: String = "0"
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fetch the data right before reloading
        loadTrendsData()
            
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
        collectionView
            .register(
                UINib(
                    nibName: "DigitalEyeStrainCollectionViewCell",
                    bundle: nil
                ),
                forCellWithReuseIdentifier: "EyeStrainCell"
            )
        collectionView
            .register(
                UINib(
                    nibName: "LowLightScreenUsageCollectionViewCell",
                    bundle: nil
                ),
                forCellWithReuseIdentifier: "LowLightCell"
            )
        collectionView
            .register(
                UINib(nibName: "TrandsCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "TrendCell"
            )
        collectionView
            .register(
                UINib(nibName: "SummaryInsightCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "AlertCell"
            )
        collectionView
            .register(
                UINib(nibName: "StreakCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "StreakCell"
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
        return UICollectionViewCompositionalLayout { (
            sectionIndex,
            layoutEnv
        ) -> NSCollectionLayoutSection? in
            
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(50)
            )
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            
            if sectionIndex == 0 {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(120)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 4,
                    leading: 8,
                    bottom: 4,
                    trailing: 8
                )
                
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: itemSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 8,
                    leading: 0,
                    bottom: 0,
                    trailing: 0
                )
                
                section.boundarySupplementaryItems = [sectionHeader]
                return section
            } else if sectionIndex == 1 {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.50),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 4,
                    leading: 4,
                    bottom: 4,
                    trailing: 4
                )
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(200)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 0,
                    leading: 4,
                    bottom: 4,
                    trailing: 4
                )
                
//                section.boundarySupplementaryItems = [sectionHeader]
                return section
            } else {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(180)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 4,
                    leading: 8,
                    bottom: 4,
                    trailing: 8
                )
                
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: itemSize,
                    subitems: [item]
                )
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 0,
                    leading: 0,
                    bottom: 0,
                    trailing: 0
                )
                section.boundarySupplementaryItems = [sectionHeader]
                return section
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "HeaderView",
            for: indexPath
        )
        header.subviews.forEach { $0.removeFromSuperview() }
        
        let label = UILabel()
        
        if indexPath.section == 2 {
            
            label.frame = CGRect(
                x: 16,
                y: 10,
                width: header.frame.width - 32,
                height: 30
            )
            label.text = "Trends"
            label.font = .systemFont(ofSize: 24, weight: .bold)
        }
        
        label.textColor = .white
        header.addSubview(label)
        return header
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            // Adjust the number of items depending on if the alert is visible or dismissed
            return isAlertDismissed ? 1 : 2
        } else if section == 1 {
            return 4
        }
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            
            // If the alert isn't dismissed and we are at the first item, show the alert
            if !isAlertDismissed && indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "AlertCell",
                    for: indexPath
                ) as! SummaryInsightCollectionViewCell
                
                cell.configure(
                    name: "Excellent Work!!!",
                    description: "Your Overall Eye Health Score improved by 5 points this month, moving you closer to the ideal 100."
                )
                
                // Set the closure to handle what happens when the close button is tapped
                cell.onDismiss = { [weak self] in
                    guard let self = self else { return }
                    
                    // Update state so numberOfItemsInSection returns 1
                    self.isAlertDismissed = true
                    
                    // Animate the cell away
                    self.collectionView.performBatchUpdates({
                        self.collectionView.deleteItems(at: [IndexPath(item: 0, section: 0)])
                    }, completion: nil)
                }
                
                return cell
                
            } else {
                // If the alert is dismissed OR we are at index 1, show the Streak Cell
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "StreakCell",
                    for: indexPath
                ) as! StreakCollectionViewCell

                // FETCH DATA
                let user = SwiftDataManager.shared.getOrCreateUser()
                let streakData = ExerciseDataManager.shared.fetchWeeklyStreak()

                // CONFIGURE
                cell.configure(with: streakData, currentStreak: user.currentStreak)

                return cell
            }
            
        } else if indexPath.section == 1 {
            switch indexPath.item {
            case 0:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "DailyExerciseCell",
                    for: indexPath
                ) as! DailyExerciseCollectionViewCell
                
                // 1. Fetch today's exact record
                let todayRecord = ExerciseDataManager.shared.fetchTodayRecord()
                
                // 2. Convert the stored seconds into minutes for the UI
                let completedMins = todayRecord.completedSeconds / 60
                let goalMins = todayRecord.goalSeconds / 60
                
                // 3. Pass the dynamic data to the cell
                cell.configure(current: completedMins, goal: goalMins)
                
                return cell
            case 1:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "EyeStrainCell",
                    for: indexPath
                ) as! DigitalEyeStrainCollectionViewCell
                cell.configure(with: [70, 22, 60, 42, 80, 75, 48])
                return cell
            case 2:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "LowLightCell",
                    for: indexPath
                ) as! EyeTestSummaryCell
                
                return cell
            default:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "AwardsCell",
                    for: indexPath
                ) as! AwardsCollectionViewCell
                cell.configure(name: "Focused Champ", date: "21/11/2025" , image: "trophy.circle")
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TrendCell",
                for: indexPath
            )
            
            let currentTitle: String
            let currentAverage: String
            let currentData: [TrendData]
            let currentMax: Double
            
            if indexPath.item == 0 {
                currentTitle = "Exercise Accuracy"
                currentAverage = accuracyAverage
                currentData = accuracyTrends
                currentMax = 100 // Scales to 100%
            }
            else if indexPath.item == 1 {
                currentTitle = "C Test Score"
                currentAverage = eyeTestAverage
                currentData = eyeTestTrends
                currentMax = 6 // Scales to 6 (your Landolt C max score)
            } else {
                currentTitle = "OSDI score"
                currentAverage = osdiAverage
                currentData = osdiTrends
                currentMax = 100 // Scales to 100
            }
            
            cell.contentConfiguration = UIHostingConfiguration {
                TrendCardView(
                    title: currentTitle,
                    averageScore: currentAverage,
                    data: currentData,
                    yAxisMax: currentMax
                )
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.item == 3 {
            let storyboard = UIStoryboard(name: "Summary", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "AwardsViewController")
            navigationController?.pushViewController(vc, animated: true)
        }
        else if indexPath.section == 1 && indexPath.item == 2 {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "EyeTestStoryBoard")
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
