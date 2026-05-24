import UIKit
import SwiftUI

class ReportViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    
    var sessionType: String = "Blink"
    var overallScore: Int = 0
    var totalErrors: Int = 0
    var chartData: [String: [Float]] = [:]
    var completionTitle: String?
    var completionMessage: String?
    
    var directionErrors: [String: Double] = [:]
    var avgHeadMovement: Float = 0.0
    var avgReactionTimeSeconds: Double?
    
    private var leftChartData: [BlinkBarData] = []
    private var rightChartData: [BlinkBarData] = []
    private var directionalChartData: [BlinkBarData] = []
    private var leftEyeStrength: Int = 0
    private var rightEyeStrength: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Performance Report"
        setupBackground()
        processIncomingData()
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
        collectionView.register(UINib(nibName: "ReportCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ReportCell")
        collectionView.register(UINib(nibName: "MetricCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "MetricCell")
        collectionView.register(UINib(nibName: "ChartCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ChartCell")
        collectionView.collectionViewLayout = createLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.compactAppearance = appearance
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.hidesBackButton = true
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(finishAndReturnToMain)
        )
    }

    private func processIncomingData() {
        if sessionType == "Blink" {
            let leftPeaks = chartData["Left"] ?? []
            let rightPeaks = chartData["Right"] ?? []
            
            let lAvg = leftPeaks.isEmpty ? 0 : leftPeaks.reduce(0, +) / Float(leftPeaks.count)
            let rAvg = rightPeaks.isEmpty ? 0 : rightPeaks.reduce(0, +) / Float(rightPeaks.count)
            
            self.leftEyeStrength = Int(lAvg * 100)
            self.rightEyeStrength = Int(rAvg * 100)

            self.leftChartData = leftPeaks.enumerated().map { index, peak in
                BlinkBarData(timeSecond: index + 1, performed: Int(peak * 100), total: 100)
            }
            self.rightChartData = rightPeaks.enumerated().map { index, peak in
                BlinkBarData(timeSecond: index + 1, performed: Int(peak * 100), total: 100)
            }
        } else if usesDirectionalReport {
            self.directionalChartData = order.enumerated().map { index, direction in
                let errorRate = directionErrors[direction] ?? 0.0
                return BlinkBarData(timeSecond: index + 1, performed: Int(100 - errorRate), total: 100)
            }
        }
    }
    
    private func setupBackground() {
        view.backgroundColor = .black
        collectionView.backgroundColor = .black
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 32, right: 0)
        collectionView.showsVerticalScrollIndicator = false
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int { return 3 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if sessionType == "Completion" { return section == 0 ? 1 : 0 }
        if section == 0 { return 1 }
        if section == 1 {
            let baseCount = usesDirectionalReport ? order.count : 3
            let reactionExtra = avgReactionTimeSeconds != nil ? 1 : 0
            return baseCount + reactionExtra
        }
        if section == 2 { return sessionType == "SaccadicJumps" ? 0 : (usesDirectionalReport ? 1 : 2) }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReportCell", for: indexPath) as! ReportCollectionViewCell
            if sessionType == "Completion" {
                cell.configureCompletion(
                    title: completionTitle ?? "Exercise Complete",
                    message: completionMessage ?? ReportViewController.randomCompletionMessage()
                )
            } else {
                cell.configure(score: self.overallScore, sessionType: self.sessionType, errors: totalErrors)
            }
            return cell
            
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MetricCell", for: indexPath) as! MetricCollectionViewCell
            let baseCount = usesDirectionalReport ? order.count : 3
            if indexPath.item == baseCount, let rt = avgReactionTimeSeconds {
                // Extra reaction time cell at the end
                cell.configure(title: "Avg Response", value: String(format: "%.2fs", rt))
            } else if usesDirectionalReport {
                let direction = order[indexPath.item]
                let accuracy = Int(100 - (directionErrors[direction] ?? 0.0))
                cell.configure(title: displayName(for: direction), value: "\(accuracy)%")
            } else {
                if indexPath.item == 0 { cell.configure(title: "Left Eye", value: "\(self.leftEyeStrength)%") }
                else if indexPath.item == 1 { cell.configure(title: "Right Eye", value: "\(self.rightEyeStrength)%") }
                else { cell.configure(title: "Errors", value: "\(self.totalErrors)") }
            }
            return cell
            
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChartCell", for: indexPath) as! ChartCollectionViewCell
            if usesDirectionalReport {
                cell.configure(title: "Tracking Accuracy", data: directionalChartData, description: directionalInsightText())
            } else {
                let currentData = (indexPath.item == 0) ? leftChartData : rightChartData
                let currentTitle = (indexPath.item == 0) ? "Left Eye Intensity" : "Right Eye Intensity"
                cell.configure(title: currentTitle, data: currentData, description: "Red bars indicate incomplete blinks i.e. number below the 0.75 threshold.")
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath)
        
        header.subviews.forEach { $0.removeFromSuperview() }
        
        if indexPath.section == 1 {
            let titleLabel = UILabel()
            titleLabel.text = sectionTitle
            titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
            titleLabel.textColor = .exerciseResultOrange
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let descLabel = UILabel()
            descLabel.text = sectionDescription
            descLabel.font = .systemFont(ofSize: 14)
            descLabel.textColor = UIColor.white.withAlphaComponent(0.68)
            descLabel.numberOfLines = 0
            descLabel.translatesAutoresizingMaskIntoConstraints = false
            
            header.addSubview(titleLabel)
            header.addSubview(descLabel)
            
            NSLayoutConstraint.activate([
                titleLabel.topAnchor.constraint(equalTo: header.topAnchor, constant: 15),
                titleLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
                titleLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
                
                descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
                descLabel.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 16),
                descLabel.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -16),
                descLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -10) // This defines the bottom bound
            ])
        } else if indexPath.section == 2 {
            let label = UILabel()
            label.text = usesDirectionalReport ? "Tracking Analysis" : "Intensity Charts"
            label.font = .systemFont(ofSize: 18, weight: .bold)
            label.textColor = .exerciseResultOrange
            label.frame = CGRect(x: 16, y: 10, width: header.frame.width - 32, height: 25)
            header.addSubview(label)
        }
        
        return header
    }
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnv) -> NSCollectionLayoutSection? in
            
            let tallHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(120))
            let tallHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: tallHeaderSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

 
            let smallHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
            let smallHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: smallHeaderSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

            if sectionIndex == 0 {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(self.sessionType == "Completion" ? 210 : 170)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
                return section
                
            } else if sectionIndex == 1 {
                if self.sessionType == "SaccadicJumps" {
                    let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0)))
                    item.contentInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)

                    let row = NSCollectionLayoutGroup.horizontal(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.5)),
                        subitems: [item, item]
                    )
                    let group = NSCollectionLayoutGroup.vertical(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(210)),
                        subitems: [row, row]
                    )
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = .init(top: 0, leading: 12, bottom: 20, trailing: 12)
                    section.boundarySupplementaryItems = [tallHeader]
                    return section
                }

                let width = self.usesDirectionalReport ? 0.5 : 0.33
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(width), heightDimension: .fractionalHeight(1.0)))
                item.contentInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(self.sessionType == "SaccadicJumps" ? 220 : (self.usesDirectionalReport ? 170 : 100))), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 0, leading: 12, bottom: 20, trailing: 12)
                
 
                section.boundarySupplementaryItems = [tallHeader]
                return section
                
            } else {
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(300)))
                item.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(600)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.boundarySupplementaryItems = [smallHeader]
                return section
            }
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        finishAndReturnToMain()
    }

    @objc private func finishAndReturnToMain() {
        if let navigationController, let presenter = navigationController.presentingViewController {
            navigationController.dismiss(animated: true) {
                presenter.navigationController?.popToRootViewController(animated: true)
            }
        } else if let presenter = presentingViewController {
            dismiss(animated: true) {
                presenter.navigationController?.popToRootViewController(animated: true)
            }
        } else if let navigationController {
            navigationController.popToRootViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private var usesDirectionalReport: Bool {
        sessionType == "SmoothPursuit" || sessionType == "SaccadicJumps"
    }

    private var order: [String] {
        sessionType == "SaccadicJumps"
            ? ["top", "right", "bottom", "left"]
            : ["top", "topRight", "right", "bottomRight", "bottom", "bottomLeft", "left", "topLeft"]
    }

    private var sectionTitle: String {
        switch sessionType {
        case "Blink": return "Blink Performance"
        case "SaccadicJumps": return "Directional Response"
        default: return "Tracking Accuracy"
        }
    }

    private var sectionDescription: String {
        switch sessionType {
        case "Blink": return "Left and right blink strength are shown separately."
        case "SaccadicJumps": return "Each card shows how often you looked in the announced direction in time."
        default: return "Each card shows how smoothly you tracked that part of the path."
        }
    }

    private func displayName(for direction: String) -> String {
        [
            "top": "Top",
            "topRight": "Top Right",
            "right": "Right",
            "bottomRight": "Bottom Right",
            "bottom": "Bottom",
            "bottomLeft": "Bottom Left",
            "left": "Left",
            "topLeft": "Top Left"
        ][direction] ?? direction
    }

    private func directionalInsightText() -> String {
        let weakest = order.min { (directionErrors[$0] ?? 0) < (directionErrors[$1] ?? 0) }
        guard let weakest else { return "Higher bars mean stronger tracking accuracy." }
        return "Higher bars mean stronger accuracy. Your lowest direction today was \(displayName(for: weakest)); give that side a little extra attention next time."
    }

    static func randomCompletionMessage() -> String {
        [
            "Nicely done. Your eyes got the reset they needed.",
            "Session complete. Small daily reps build real visual stamina.",
            "Great work. You kept the habit alive today.",
            "Done and logged. Your eyes can take the win."
        ].randomElement() ?? "Exercise complete. Great work today."
    }
}

extension UIColor {
    static let exerciseResultOrange = UIColor(red: 1.0, green: 0.478, blue: 0.0, alpha: 1.0)
    static let exerciseResultCard = UIColor(white: 0.07, alpha: 1.0)
}
