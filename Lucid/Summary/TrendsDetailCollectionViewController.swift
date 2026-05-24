import UIKit
import SwiftUI

class TrendsDetailViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var collectionView: UICollectionView!
    
    // MARK: - Data Properties
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
        
        let responsivenessResult = TrendDataManager.shared.getEyeResponsivenessTrends()
        self.responsivenessAverage = responsivenessResult.average
        self.responsivenessTrends = responsivenessResult.data
        
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
            lore = "This score tracks how good your eyes are at following moving things on the screen without getting distracted. Think of it like playing a game where you have to keep your laser focus on a moving target. If your eyes stay right on the dot, your score goes up! High accuracy means your eye muscles are getting stronger and working together super well."
            let val = Double(average) ?? 0
            status = val == 0 ? "Try doing some exercises so we can measure how accurately your eyes can follow targets!" : (val > 90 ? "Whoa, your eyes are like a hawk! You are tracking things super well. Keep it up!" : "Your tracking is okay, but let's try to focus a bit more next time. Practice makes perfect!")
        case 1:
            title = "C Test Score"
            average = self.eyeTestAverage
            data = self.eyeTestTrends
            max = 6
            lore = "The C Test is like that chart with the letters at the eye doctor's office, but we use the letter 'C' pointing in different directions instead. It checks how clear and sharp your vision is from a distance. A higher score means your eyes can see smaller details easily without squinting. It's basically a score of how sharp your vision is!"
            status = (Double(average) ?? 0) == 0 ? "Take a C Test to find out how sharp your eyes can see today!" : "Your vision is looking pretty good, but let's keep exercising so it stays super sharp!"
        case 2:
            title = "OSDI Score"
            average = self.osdiAverage
            data = self.osdiTrends
            direction = 0
            lore = "OSDI is a fancy name for checking if your eyes are dry, itchy, or tired from looking at screens all day. For this score, lower is actually way better! If your score is high, it means your eyes are crying out for a break. If it's low, it means your eyes are feeling fresh, happy, and well-rested!"
            let val = Double(average) ?? 0
            status = val == 0 ? "Take the quick OSDI quiz to find out if your eyes are getting too tired from screens!" : (val < 13 ? "Awesome! Your eyes are feeling super fresh and relaxed. Keep up the good work!" : "Uh oh, your eyes are feeling a bit tired or dry. You should take a break from screens and blink more!")
        case 3:
            title = "Eye Responsiveness"
            average = self.responsivenessAverage
            data = self.responsivenessTrends
            direction = 0
            max = 3
            lore = "This measures how fast your eyes react when something changes on the screen, measured in seconds. A lower number means your eyes and brain are communicating super fast! Think of it like a reflex test for your eyes. The quicker you react, the sharper your visual reflexes are."
            let val = Double(average) ?? 0
            status = val == 0 ? "Do a Blink Training or Saccadic Jumps session to measure your eye reflex speed!" : (val < 0.8 ? "Lightning fast! Your eye reflexes are incredibly sharp." : "Your eye reflexes are working well! Keep training to get even faster.")
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
