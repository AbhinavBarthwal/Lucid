import UIKit
import SwiftUI

class ReportViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    
    var sessionType: String = "Blink"
    var overallScore: Int = 0
    var totalErrors: Int = 0
    var chartData: [String: [Float]] = [:]
    
    var directionErrors: [String: Double] = [:]
    var avgHeadMovement: Float = 0.0
    
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
        } else if sessionType == "SmoothPursuit" {
            let order = ["top", "topRight", "right", "bottomRight", "bottom", "bottomLeft", "left", "topLeft"]
            self.directionalChartData = order.enumerated().map { index, direction in
                let errorRate = directionErrors[direction] ?? 0.0
                return BlinkBarData(timeSecond: index + 1, performed: Int(100 - errorRate), total: 100)
            }
        }
    }
    
    private func setupBackground() {
        self.collectionView.backgroundColor = .black
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int { return 3 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        if section == 1 { return sessionType == "SmoothPursuit" ? 2 : 3 }
        if section == 2 { return sessionType == "SmoothPursuit" ? 1 : 2 }
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReportCell", for: indexPath) as! ReportCollectionViewCell
            cell.configure(score: self.overallScore)
            return cell
            
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MetricCell", for: indexPath) as! MetricCollectionViewCell
            if sessionType == "SmoothPursuit" {
                if indexPath.item == 0 {
                    cell.configure(title: "Avg Head Move", value: String(format: "%.1f°", avgHeadMovement))
                } else {
                    cell.configure(title: "Errors", value: "\(self.totalErrors)")
                }
            } else {
                if indexPath.item == 0 { cell.configure(title: "Left Eye", value: "\(self.leftEyeStrength)%") }
                else if indexPath.item == 1 { cell.configure(title: "Right Eye", value: "\(self.rightEyeStrength)%") }
                else { cell.configure(title: "Errors", value: "\(self.totalErrors)") }
            }
            return cell
            
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChartCell", for: indexPath) as! ChartCollectionViewCell
            if sessionType == "SmoothPursuit" {
                cell.configure(title: "Tracking Accuracy", data: directionalChartData, description: "Bars 1-8 represent tracking accuracy for directions: Top, Top-Right, Right, Bottom-Right, Bottom, Bottom-Left, Left, and Top-Left.")
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
            titleLabel.text = sessionType == "Blink" ? "Blink Performance" : "Tracking Metrics"
            titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
            titleLabel.textColor = .white
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            
            let descLabel = UILabel()
            descLabel.text = sessionType == "Blink" ? "Breakdown of eye intensity peaks." : "Accuracy of movement per direction."
            descLabel.font = .systemFont(ofSize: 14)
            descLabel.textColor = .lightGray
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
            label.text = sessionType == "SmoothPursuit" ? "Tracking Analysis" : "Intensity Charts"
            label.font = .systemFont(ofSize: 18, weight: .bold)
            label.textColor = .white
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
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(200)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
                return section
                
            } else if sectionIndex == 1 {
                let width = self.sessionType == "SmoothPursuit" ? 0.5 : 0.33
                let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(width), heightDimension: .fractionalHeight(1.0)))
                item.contentInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100)), subitems: [item])
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
        if let rootPresenter = self.presentingViewController?.presentingViewController {
            rootPresenter.dismiss(animated: true, completion: nil)
        } else if let exercisePresenter = self.presentingViewController {
            exercisePresenter.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
