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
    
    var overallScore: Int = 0
    var totalErrors: Int = 0
    
    // Mock Data for the chart
    var chartData: [BlinkBarData] = [
        BlinkBarData(category: "Left", performed: 4, total: 5),
        BlinkBarData(category: "Right", performed: 5, total: 5),
        BlinkBarData(category: "Both", performed: 2, total: 3)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Performance Report"
        
        setupBackground()
        
        // Registering Cells following your format
        collectionView
            .register(
                UINib(nibName: "ReportCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "ReportCell"
            )
        collectionView
            .register(
                UINib(nibName: "MetricCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "MetricCell"
            )
        collectionView
            .register(
                UINib(nibName: "ChartCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "ChartCell"
            )
        
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
    
    private func setupBackground() {
//        let bgImageView = UIImageView(image: UIImage(named: "BackgroundGradient"))
////        bgImageView.contentMode = .scaleAspectFill
//        self.collectionView.backgroundView = bgImageView
        self.collectionView.backgroundColor = .black
    }
    
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnv) -> NSCollectionLayoutSection? in
            
            if sectionIndex == 0 {
                // Large Ring Gauge Section
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(200)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 16, bottom: 10, trailing: 16)
                return section
                
            } else if sectionIndex == 1 {
                // Three Metric Cards (Left Eye, Right Eye, Errors)
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.33),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(100)
                )
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 20, trailing: 12)
                return section
                
            } else {
                // Blink Intensity Chart Section
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(280)
                )
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
            cell.configure(score: 85) // Example overall score
            return cell
            
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MetricCell", for: indexPath) as! MetricCollectionViewCell
            if indexPath.item == 0 { cell.configure(title: "Left Eye", value: "0%") }
            else if indexPath.item == 1 { cell.configure(title: "Right Eye", value: "0%") }
            else { cell.configure(title: "Errors", value: "0") }
            return cell
            
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChartCell", for: indexPath) as! ChartCollectionViewCell
            cell.configure(with: chartData) 
            return cell
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
