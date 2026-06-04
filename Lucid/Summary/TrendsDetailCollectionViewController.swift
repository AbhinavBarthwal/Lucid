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
        var showCustomOSDISheet = false
        var showCustomCTestSheet = false

        // Reordered index mapping:
        // 0: OSDI Score
        // 1: C Test Score
        // 2: Exercise Accuracy
        // 3: Eye Responsiveness
        switch indexPath.item {
        case 0:
            title = "OSDI Score"
            average = self.osdiAverage
            data = self.osdiTrends
            direction = 0
            showCustomOSDISheet = true
            lore = "OSDI checks how dry, tired, or sore your eyes feel and how much that affects daily tasks. Scores range from 0 to 100. Lower is better. 0-12 is Normal, 13-22 is Mild, 23-32 is Moderate, and 33-100 is Severe. Your score comes from the questions you answered."
            let val = Double(average) ?? 0
            let hasData = data.contains(where: { $0.value >= 0 })
            status = !hasData ? "Take the quick OSDI quiz to find out if your eyes are getting too tired from screens!" : (val < 13 ? "Awesome! Your eyes are feeling super fresh and relaxed. Keep up the good work!" : "Uh oh, your eyes are feeling a bit tired or dry. You should take a break from screens and blink more!")
        case 1:
            title = "C Test Score"
            average = self.eyeTestAverage
            data = self.eyeTestTrends
            max = 6
            showCustomCTestSheet = true
            lore = "The C Test shows a C shape facing different directions. It checks how clearly each eye can see. Each eye is scored out of 6. Higher scores mean that eye got more targets right. Comparing left and right eye scores can show if one eye needs more care."
            let val = Double(average) ?? 0
            let hasData = data.contains(where: { $0.value >= 0 })
            if !hasData {
                status = "Take a C Test to find out how sharp your eyes can see today!"
            } else if val >= 5.0 {
                status = "Whoa, super sharp! Your vision is looking excellent. Keep up the exercises to maintain it!"
            } else if val >= 3.0 {
                status = "Your vision is looking pretty good, but let's keep exercising so it stays super sharp!"
            } else {
                status = "Your vision score is quite low. Daily focus training can help improve your clarity!"
            }
        case 2:
            title = "Exercise Accuracy"
            average = self.accuracyAverage
            data = self.accuracyTrends
            lore = "This score shows how well your eyes follow moving things on the screen. If your eyes stay on the dot, your score goes up. A high score means your eyes are tracking well."
            let val = Double(average) ?? 0
            let hasData = data.contains(where: { $0.value >= 0 })
            status = !hasData ? "Try doing some exercises so we can measure how accurately your eyes can follow targets!" : (val > 90 ? "Whoa, your eyes are like a hawk! You are tracking things super well. Keep it up!" : "Your tracking is okay, but let's try to focus a bit more next time. Practice makes perfect!")
        case 3:
            title = "Eye Responsiveness"
            average = self.responsivenessAverage
            data = self.responsivenessTrends
            direction = 0
            max = 3
            lore = "This shows how fast your eyes react when something changes on the screen. It is measured in seconds. A lower number means a faster reaction."
            let val = Double(average) ?? 0
            let hasData = data.contains(where: { $0.value >= 0 })
            status = !hasData ? "Do a Blink Training or Saccadic Jumps session to measure your eye reflex speed!" : (val < 0.8 ? "Lightning fast! Your eye reflexes are incredibly sharp." : "Your eye reflexes are working well! Keep training to get even faster.")
        default: break
        }

        cell.contentConfiguration = UIHostingConfiguration {
            TrendCardContainer(
                title: title,
                average: average,
                data: data,
                max: max,
                direction: direction,
                lore: lore,
                status: status,
                showCustomOSDISheet: showCustomOSDISheet,
                showCustomCTestSheet: showCustomCTestSheet
            )
        }
        .margins(.all, 0)
        
        cell.backgroundColor = .clear
        return cell
    }
}

// MARK: - SwiftUI Container
struct TrendCardContainer: View {
    let title: String, average: String, data: [TrendData]
    let max: Double, direction: Int, lore: String, status: String
    let showCustomOSDISheet: Bool
    let showCustomCTestSheet: Bool
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
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.4)))
        .sheet(isPresented: $showDetail) {
            if showCustomOSDISheet {
                NavigationStack {
                    OSDIInfoSheetView(
                        score: Double(average) ?? 0.0,
                        severity: {
                            let scoreVal = Double(average) ?? 0.0
                            if scoreVal <= 12 { return "Normal" }
                            else if scoreVal <= 22 { return "Mild" }
                            else if scoreVal <= 32 { return "Moderate" }
                            else { return "Severe" }
                        }()
                    )
                }
            } else if showCustomCTestSheet {
                NavigationStack {
                    CTestTrendsInfoSheetView(score: Int((Double(average) ?? 0.0).rounded()))
                }
            } else {
                InfoSheet(title: title, content: lore)
                    .presentationDetents([.fraction(0.8)])
            }
        }
    }
}

struct InfoSheet: View {
    let title: String, content: String
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text(content)
                    .font(.system(size: 19, weight: .regular, design: .rounded))
                    .padding()
                Spacer()
            }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}

// Custom Swift UI view for C Test Info Sheet inside Trends
struct CTestTrendsInfoSheetView: View {
    let score: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About C Test")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text("The C test uses a Landolt C target to check how well each eye identifies the opening direction. It is a simple way to screen visual sharpness and compare left and right eye performance.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.72))
                }

                infoRow(
                    title: "How the score works",
                    body: "Each eye is scored out of 6. Higher values mean that eye correctly handled more targets during the test."
                )

                infoRow(
                    title: "Why both eyes matter",
                    body: "Looking at both eyes separately helps surface imbalance. A repeated gap between left and right can be more useful than a single score alone."
                )

                infoRow(
                    title: "Current result",
                    body: "Your average vision score is \(score)/6."
                )
            }
            .padding(20)
        }
        .background(Color.black.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundStyle(.white)
            }
        }
    }

    private func infoRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
            Text(body)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.68))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(white: 0.09))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
