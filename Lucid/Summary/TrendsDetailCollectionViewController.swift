import UIKit
import SwiftUI

class TrendsDetailViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
     var collectionView: UICollectionView!
    
    // MARK: - Data Properties
    var accuracyTrends: [TrendData] = []
    var accuracyAverage: String = "0"
    
    var eyeTestTrends: [TrendData] = []
    var eyeTestAverage: String = "0"
    
    var osdiTrends: [TrendData] = []
    var osdiAverage: String = "0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Trends"

        
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadTrendsData()
        collectionView.reloadData()
    }
    
    private func setupCollectionView() {
        
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let bgImageView = UIImageView(
            image: UIImage(named: "BackgroundGradient")
        )
        bgImageView.contentMode = .scaleAspectFill
        collectionView.backgroundView = bgImageView

        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "TrendsDetailCell")
        
        view.addSubview(collectionView)
    }
    
    private func loadTrendsData() {
        let accuracyResult = TrendDataManager.shared.getExerciseAccuracyTrends()
        self.accuracyAverage = accuracyResult.average
        self.accuracyTrends = accuracyResult.data
        
        let testResult = TrendDataManager.shared.getEyeTestTrends()
        self.eyeTestAverage = testResult.average
        self.eyeTestTrends = testResult.data
        
        let osdiResult = TrendDataManager.shared.getOSDITrends()
        self.osdiAverage = osdiResult.average
        self.osdiTrends = osdiResult.data
    }
    
    func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(250))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(250))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        section.interGroupSpacing = 8
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrendsDetailCell", for: indexPath)
        
        let currentTitle: String
        let currentAverage: String
        let currentData: [TrendData]
        let currentMax: Double
        let betterDirection: Int
        let currentLore: String
        
        switch indexPath.item {
        case 0:
            currentTitle = "Exercise Accuracy"
            currentAverage = accuracyAverage
            currentData = accuracyTrends
            currentMax = 100
            betterDirection = 1
            currentLore = "Exercise accuracy measures how precisely your eyes track on-screen targets during motion-based exercises. It compares your actual eye movement trajectory against the ideal path dictated by the exercise."
            
        case 1:
            currentTitle = "C Test Score"
            currentAverage = eyeTestAverage
            currentData = eyeTestTrends
            currentMax = 6
            betterDirection = 1
            currentLore = "Your C Test score reflects your visual acuity using the Landolt C standard. This score indicates your ability to distinguish fine details and helps track if your baseline vision is shifting over time."
            
        case 2:
            currentTitle = "OSDI Score"
            currentAverage = osdiAverage
            currentData = osdiTrends
            currentMax = 100
            betterDirection = 0 // Lower is better
            currentLore = "The Ocular Surface Disease Index (OSDI) evaluates dry eye symptoms and their impact on your vision. A lower score is better, indicating healthier eyes with minimal digital strain or dryness."
            
        case 3:
            currentTitle = "Eye Responsiveness"
            // Borrowing accuracy data for now
            currentAverage = accuracyAverage
            currentData = accuracyTrends
            currentMax = 100
            betterDirection = 1
            currentLore = "Eye responsiveness tracks your reaction time. It measures the exact delay between a sensory trigger—such as a haptic pulse or visual cue—and your initial, correct eye movement response."
            
        default:
            fatalError("Unexpected index path")
        }
        
        // MARK: - SwiftUI Integration
        cell.contentConfiguration = UIHostingConfiguration {
            VStack(alignment: .leading, spacing: 4) {
                TrendCardView(
                    title: currentTitle,
                    averageScore: currentAverage,
                    data: currentData,
                    yAxisMax: currentMax,
                    betterDirection: betterDirection
                )
                .frame(height: 140)
                
                Text(currentLore)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            .padding()
            .background(Color(UIColor.black).opacity(0.5))
            .cornerRadius(16)
        }
        
        cell.backgroundColor = .clear
        
        return cell
    }
}


