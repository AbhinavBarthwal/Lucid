//
//  ReportViewController.swift
//  Lucid
//
//  Created by Kanishka Bansal on 16/03/26.
//

import UIKit
import SwiftUI


class ReportViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    
    // MARK: - Variables Received From Caller
    var overallScore: Int = 0
    var totalErrors: Int = 0
    var chartData: [String: [Float]] = [:] // Matches the dictionary sent from Blink VC
    
    // MARK: - Processed UI Variables
    private var displayChartData: [BlinkBarData] = []
    private var leftEyeStrength: Int = 0
    private var rightEyeStrength: Int = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Performance Report"
        
        setupBackground()
        processIncomingData() // Parse the arrays into UI metrics
        
        // Registering Cells
        collectionView.register(UINib(nibName: "ReportCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ReportCell")
        collectionView.register(UINib(nibName: "MetricCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "MetricCell")
        collectionView.register(UINib(nibName: "ChartCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "ChartCell")
        
        collectionView.collectionViewLayout = createLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 1. Unhide the bar
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        
        // 2. Force the Navigation Bar to be visible with white text (iOS 15+ fix)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black // Match your theme
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        // Apply the appearance
        self.navigationController?.navigationBar.standardAppearance = appearance
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.compactAppearance = appearance
        
        // Force the back button arrow to be white
        self.navigationController?.navigationBar.tintColor = .white
    }
    
    // MARK: - Data Processing
    private func processIncomingData() {
        // Extract raw arrays
        let leftPeaks = chartData["Left"] ?? []
        let rightPeaks = chartData["Right"] ?? []
        
        // 1. Calculate Average Strength (Intensity) for Metric Cards
        let lAvg = leftPeaks.isEmpty ? 0 : leftPeaks.reduce(0, +) / Float(leftPeaks.count)
        let rAvg = rightPeaks.isEmpty ? 0 : rightPeaks.reduce(0, +) / Float(rightPeaks.count)
        
        self.leftEyeStrength = Int(lAvg * 100)
        self.rightEyeStrength = Int(rAvg * 100)
        
        // 2. Build Chart Data
        // Since we don't have the explicit "expected totals", we add errors to 'performed'
        // to approximate the total required attempts for the chart bars.
        let leftCount = leftPeaks.count
        let rightCount = rightPeaks.count
        let errorPadding = max(1, totalErrors / 2) // distribute errors visually
        
        self.displayChartData = [
            BlinkBarData(category: "Left", performed: leftCount, total: leftCount > 0 ? leftCount + errorPadding : 5),
            BlinkBarData(category: "Right", performed: rightCount, total: rightCount > 0 ? rightCount + errorPadding : 5)
        ]
        
        // If they did the double blink phase (both), let's calculate an average combined
        if leftCount > 0 && rightCount > 0 {
            let bothCount = min(leftCount, rightCount)
            self.displayChartData.append(BlinkBarData(category: "Both", performed: bothCount, total: bothCount + (totalErrors % 2)))
        }
    }
    
    private func setupBackground() {
        self.collectionView.backgroundColor = .black
    }
    
    // MARK: - Layout Configuration
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnv) -> NSCollectionLayoutSection? in
            
            if sectionIndex == 0 {
                // Large Ring Gauge Section
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(200))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 16, bottom: 10, trailing: 16)
                return section
                
            } else if sectionIndex == 1 {
                // Three Metric Cards (Left Eye, Right Eye, Errors)
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.33), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 20, trailing: 12)
                return section
                
            } else {
                // Blink Intensity Chart Section
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(280))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
                
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 8, bottom: 30, trailing: 8)
                return section
            }
        }
    }
    
    // MARK: - Data Source
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 1 { return 3 } // Three metric boxes
        return 1 // One ring, one chart
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReportCell", for: indexPath) as! ReportCollectionViewCell
            // 👉 Fed directly from the score passed over
            cell.configure(score: self.overallScore)
            return cell
            
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MetricCell", for: indexPath) as! MetricCollectionViewCell
            if indexPath.item == 0 {
                // 👉 Processed left eye intensity
                cell.configure(title: "Left Eye", value: "\(self.leftEyeStrength)%")
            } else if indexPath.item == 1 {
                // 👉 Processed right eye intensity
                cell.configure(title: "Right Eye", value: "\(self.rightEyeStrength)%")
            } else {
                // 👉 Direct error count
                cell.configure(title: "Errors", value: "\(self.totalErrors)")
            }
            return cell
            
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChartCell", for: indexPath) as! ChartCollectionViewCell
            // 👉 Converted chart data mapped to your BlinkBarData
            cell.configure(with: self.displayChartData)
            return cell
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
