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
                UINib(nibName: "DigitalEyeStrainCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "EyeStrainCell"
            )
        collectionView
            .register(
                UINib(nibName: "LowLightScreenUsageCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "LowLightCell"
            )
        // Updated to use the new XIB we created

        collectionView.register(
            UINib(nibName: "TrendsAllCollectionViewCell", bundle: nil),
            forCellWithReuseIdentifier: TrendsAllCollectionViewCell.identifier
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
            let layout = UICollectionViewCompositionalLayout { (
                sectionIndex,
                layoutEnv
            ) -> NSCollectionLayoutSection? in
                
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
                    // MARK: - Section 0 (Insights & Streaks)
                    let itemSize = NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(120)
                    )
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
                    
                    let group = NSCollectionLayoutGroup.horizontal(
                        layoutSize: itemSize,
                        subitems: [item]
                    )
                    
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)
                    section.boundarySupplementaryItems = [sectionHeader]
                    
                    return section
                    
                } else if sectionIndex == 1 {
                    // MARK: - Section 1 (Daily Goals & Strains)
                    let itemSize = NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(0.50),
                        heightDimension: .fractionalHeight(1.0)
                    )
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                    
                    let groupSize = NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(200)
                    )
                    let group = NSCollectionLayoutGroup.horizontal(
                        layoutSize: groupSize,
                        subitems: [item]
                    )
                    
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 4, trailing: 4)
                    
                    return section
                    
                }  else {
                    // MARK: - Section 2 (Trends 2x2 Grid with Background)
                    let itemSize = NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(0.50),
                        heightDimension: .fractionalHeight(1.0)
                    )
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    // Spacing between the individual cells in the grid
                    item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                    
                    let groupSize = NSCollectionLayoutSize(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(60)
                    )
                    
                    let group = NSCollectionLayoutGroup.horizontal(
                        layoutSize: groupSize,
                        subitem: item,
                        count: 2
                    )
                    
                    let section = NSCollectionLayoutSection(group: group)
                    
                    // 1. HOW TO INCREASE SECTION PADDING
                    // This `contentInsets` adds padding INSIDE the section.
                    // By increasing these values, you push the grid cells inward, giving your
                    // black background a nice visual border around the content.
                    section.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                    
                    // 2. HOW TO DECREASE THE GAP BETWEEN HEADER AND CONTENT
                    // We create a custom, shorter header just for this section.
                    // Reducing the absolute height from 50 to 35 pulls the content closer to the text.
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
                    
                    // 3. HOW TO STOP BACKGROUND FROM INCLUDING THE HEADER
                    let backgroundDecoration = NSCollectionLayoutDecorationItem.background(elementKind: "SectionBackground")
                    // A decoration view fills the ENTIRE section by default (including the header).
                    // To exclude the header, we set the top inset of the background to exactly match
                    // the height of the header (35). This pushes the black box down so it starts right below the text.
                    // Note: The leading/trailing values here define how wide the black box is on your screen.
                    backgroundDecoration.contentInsets = NSDirectionalEdgeInsets(top: 40, leading: 8, bottom: 0, trailing: 8)
                    section.decorationItems = [backgroundDecoration]
                    
                    return section
                }            }
            
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
        
        if indexPath.section == 2 {
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
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return isAlertDismissed ? 1 : 2
        } else if section == 1 {
            return 4
        }
        // Return 4 items for the Trends grid
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            
            if !isAlertDismissed && indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "AlertCell",
                    for: indexPath
                ) as! SummaryInsightCollectionViewCell
                
                cell.configure(
                    name: "Excellent Work!!!",
                    description: "Your Overall Eye Health Score improved by 5 points this month, moving you closer to the ideal 100."
                )
                
                cell.onDismiss = { [weak self] in
                    guard let self = self else { return }
                    self.isAlertDismissed = true
                    self.collectionView.performBatchUpdates({
                        self.collectionView.deleteItems(at: [IndexPath(item: 0, section: 0)])
                    }, completion: nil)
                }
                
                return cell
                
            } else {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "StreakCell",
                    for: indexPath
                ) as! StreakCollectionViewCell

                let user = SwiftDataManager.shared.getOrCreateUser()
                let streakData = ExerciseDataManager.shared.fetchWeeklyStreak()

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
                
                let todayRecord = ExerciseDataManager.shared.fetchTodayRecord()
                let completedMins = todayRecord.completedSeconds / 60
                let goalMins = todayRecord.goalSeconds / 60
                
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
        }  else {
            // MARK: - Updated Trends Data Binding
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: TrendsAllCollectionViewCell.identifier,
                for: indexPath
            ) as! TrendsAllCollectionViewCell
            
            // Map the data into the 4 grid items
            switch indexPath.item {
            case 0:
                cell.configure(title: "Accuracy", subtitle: "\(accuracyAverage)% AVG", color: .accent, iconName: "target")
            case 2:
                cell.configure(title: "C Test Score", subtitle: "\(eyeTestAverage) SCORE", color: .accent, iconName: "eye.fill")
            case 3:
                cell.configure(title: "OSDI Score", subtitle: "\(osdiAverage) SCORE", color: .accent, iconName: "doc.text.fill")
            case 1:
                cell.configure(title: "Responsivenes", subtitle: "20 MIN/DAY", color: .accent, iconName: "figure.walk")
            default:
                break
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            // Section 1: Daily Goals & Strains
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
            
            // MARK: - Section 2: Trends Navigation
            else if indexPath.section == 2 {
                // Instantiate your new SwiftUI-powered detail view
                let trendsDetailVC = TrendsDetailViewController()
                
                // Push it onto the navigation stack
                navigationController?.pushViewController(trendsDetailVC, animated: true)
            }
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
