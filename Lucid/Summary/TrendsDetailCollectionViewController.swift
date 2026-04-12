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
        
        let bgImageView = UIImageView(image: UIImage(named: "BackgroundGradient"))
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
    
    // MARK: - Tight Layout
    func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(250))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // Remove internal item insets entirely to stop double-spacing
        item.contentInsets = .zero
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(250))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        // This is the gap between cards. Set to 2 or 4 for a very tight look.
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrendsDetailCell", for: indexPath)
        
        var title = "", average = "", status = "", lore = ""
        var data: [TrendData] = []
        var max: Double = 100
        var direction = 1

        switch indexPath.item {
        case 0:
            title = "Exercise Accuracy"
            average = self.accuracyAverage
            data = self.accuracyTrends
            lore = "Exercise accuracy measures how precisely your eyes track targets."
            let val = Double(average) ?? 0
            status = val == 0 ? "Perform exercises to get an accuracy score." : (val > 90 ? "You're doing well, keep the score up!" : "Time to lock down to improve your eye health.")
        case 1:
            title = "C Test Score"
            average = self.eyeTestAverage
            data = self.eyeTestTrends
            max = 6
            lore = "Your C Test score reflects your visual acuity."
            status = (Double(average) ?? 0) == 0 ? "Take the C-Test to see your vision trends." : "Let’s try and take better care of our eyes."
        case 2:
            title = "OSDI Score"
            average = self.osdiAverage
            data = self.osdiTrends
            direction = 0
            lore = "OSDI evaluates dry eye symptoms. Lower is better."
            let val = Double(average) ?? 0
            status = val == 0 ? "Take OSDI test to get you trend data." : (val < 13 ? "Eyes are looking fresh! Keep it up." : "Time to reduce that eye strain.")
        case 3:
            title = "Eye Responsiveness"
            average = self.accuracyAverage
            data = self.accuracyTrends
            lore = "Tracks your reaction time to visual cues."
            status = (Double(average) ?? 0) == 0 ? "Start a session to measure your responsiveness." : "Let’s keep working on those reflexes."
        default: break
        }

        cell.contentConfiguration = UIHostingConfiguration {
            TrendCardContainer(title: title, average: average, data: data, max: max, direction: direction, lore: lore, status: status)
        }
        .margins(.all, 0) // CRITICAL: This removes the hidden UIKit padding inside the cell
        
        cell.backgroundColor = .clear
        return cell
    }
}

// MARK: - SwiftUI Container
struct TrendCardContainer: View {
    let title: String, average: String, data: [TrendData]
    let max: Double, direction: Int, lore: String, status: String
    @State private var showDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                TrendCardView(title: title, averageScore: average, data: data, yAxisMax: max, betterDirection: direction)
                Spacer()
                Button { showDetail = true } label: {
                    Image(systemName: "info.circle").font(.system(size: 16)).foregroundColor(.orange.opacity(0.7))
                }
            }
            .frame(height: 150)
            
            Text(status)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(12) // Space inside the card
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.4)))
        .sheet(isPresented: $showDetail) {
            InfoSheet(title: title, content: lore)
                .presentationDetents([.height(200)])
        }
    }
}

struct InfoSheet: View {
    let title: String, content: String
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text(content).padding()
                Spacer()
            }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
