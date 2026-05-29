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

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if sessionType == "Completion" { return 1 }
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if sessionType == "Completion" { return section == 0 ? 1 : 0 }
        if section == 0 {
            return avgReactionTimeSeconds != nil ? 2 : 1
        }
        if section == 1 {
            let baseCount = usesDirectionalReport ? order.count : 3
            return baseCount
        }
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
                if indexPath.item == 0 {
                    cell.configure(score: self.overallScore, sessionType: self.sessionType, errors: totalErrors)
                } else {
                    if let rt = avgReactionTimeSeconds {
                        let finalRt = self.overallScore == 0 ? 0.0 : rt
                        cell.configureResponsiveness(avgReactionTimeSeconds: finalRt)
                    }
                }
            }
            return cell
            
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MetricCell", for: indexPath) as! MetricCollectionViewCell
            if usesDirectionalReport {
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
            return UICollectionViewCell()
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
                descLabel.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -10)
            ])
        }
        
        return header
    }

    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnv) -> NSCollectionLayoutSection? in
            
            let tallHeaderSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(120))
            let tallHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: tallHeaderSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)

            if sectionIndex == 0 {
                let hasReaction = self.avgReactionTimeSeconds != nil && self.sessionType != "Completion"
                
                let singleCardHeight: CGFloat = self.sessionType == "Completion" ? 210 : 140
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(singleCardHeight)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = .init(top: 6, leading: 0, bottom: 6, trailing: 0)
                
                let numItems = hasReaction ? 2 : 1
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(singleCardHeight * CGFloat(numItems))
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: groupSize,
                    subitems: Array(repeating: item, count: numItems)
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
                return section
                
            } else {
                if self.sessionType == "SaccadicJumps" {
                    let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0)))
                    item.contentInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)

                    let row = NSCollectionLayoutGroup.horizontal(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.5)),
                        subitems: [item, item]
                    )
                    let group = NSCollectionLayoutGroup.vertical(
                        layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.20)), // 2 rows * 10% = 20% of screen height
                        subitems: [row, row]
                    )
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = .init(top: 0, leading: 12, bottom: 20, trailing: 12)
                    section.boundarySupplementaryItems = [tallHeader]
                    return section
                }

                let width = self.usesDirectionalReport ? 0.5 : 0.33
                let heightDimension: NSCollectionLayoutDimension
                if self.usesDirectionalReport {
                    heightDimension = .fractionalHeight(0.10) // 10% of screen height (increased by 25% from 8%)
                } else {
                    heightDimension = .absolute(100)
                }

                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(width), heightDimension: .fractionalHeight(1.0)))
                item.contentInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: heightDimension), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 0, leading: 12, bottom: 20, trailing: 12)
                
                section.boundarySupplementaryItems = [tallHeader]
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
