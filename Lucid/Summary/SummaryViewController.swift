//
//  SummaryViewController.swift
//  Lucid
//
//  Created by Kanishka Bansal on 08/02/26.
//

import UIKit
import SwiftUI

class SummaryViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
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
                UINib(
                    nibName: "DigitalEyeStrainCollectionViewCell",
                    bundle: nil
                ),
                forCellWithReuseIdentifier: "EyeStrainCell"
            )
        collectionView
            .register(
                UINib(
                    nibName: "LowLightScreenUsageCollectionViewCell",
                    bundle: nil
                ),
                forCellWithReuseIdentifier: "LowLightCell"
            )
        collectionView
            .register(
                UINib(nibName: "TrandsCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "TrendCell"
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
        return UICollectionViewCompositionalLayout { (
            sectionIndex,
            layoutEnv
        ) -> NSCollectionLayoutSection? in
            
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(50)
            )
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            
            if sectionIndex == 0 {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(120)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 4,
                    leading: 8,
                    bottom: 4,
                    trailing: 8
                )
                
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: itemSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 8,
                    leading: 0,
                    bottom: 0,
                    trailing: 0
                )
                
                section.boundarySupplementaryItems = [sectionHeader]
                return section
            } else if sectionIndex == 1 {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(0.50),
                    heightDimension: .fractionalHeight(1.0)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 4,
                    leading: 4,
                    bottom: 4,
                    trailing: 4
                )
                
                let groupSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(200)
                )
                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: groupSize,
                    subitems: [item]
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 0,
                    leading: 4,
                    bottom: 4,
                    trailing: 4
                )
                
//                section.boundarySupplementaryItems = [sectionHeader]
                return section
            } else {
                let itemSize = NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .absolute(180)
                )
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(
                    top: 8,
                    leading: 8,
                    bottom: 8,
                    trailing: 8
                )
                
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: itemSize,
                    subitems: [item]
                )
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(
                    top: 8,
                    leading: 0,
                    bottom: 20,
                    trailing: 0
                )
                section.boundarySupplementaryItems = [sectionHeader]
                return section
            }
        }
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
                height: 30
            )
            label.text = "Trends"
            label.font = .systemFont(ofSize: 24, weight: .bold)
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
            return 2
        } else if section == 1 {
            return 4
        }
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            switch indexPath.item {
            case 0:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "AlertCell",
                    for: indexPath
                ) as! SummaryInsightCollectionViewCell
                cell
                    .configure(
                        name: "Excellent Work!!!",
                        description: "Your Overall Eye Health Score improved by 5 points this month, moving you closer to the ideal 100."
                    )
                return cell
            default:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "StreakCell",
                    for: indexPath
                ) as! StreakCollectionViewCell
                return cell
            }
            
            
        } else if indexPath.section == 1 {
                    switch indexPath.item {
                    case 0:
                        let cell = collectionView.dequeueReusableCell(
                            withReuseIdentifier: "DailyExerciseCell",
                            for: indexPath
                        ) as! DailyExerciseCollectionViewCell
                        
                        // 1. Fetch today's exact record from UserDefaults
                        let todayRecord = ExerciseDataManager.shared.fetchTodayRecord()
                        
                        // 2. Convert the stored seconds into minutes for the UI
                        let completedMins = todayRecord.completedSeconds / 60
                        let goalMins = todayRecord.goalSeconds / 60
                        
                        // 3. Pass the dynamic data to the cell
                        cell.configure(current: completedMins, goal: goalMins)
                        
                        return cell
            case 1:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "LowLightCell",
                    for: indexPath
                ) as! LowLightScreenUsageCollectionViewCell
                cell.configure(usage: "1h 20m", progress: 0.70)
                return cell
            case 2:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "EyeStrainCell",
                    for: indexPath
                ) as! DigitalEyeStrainCollectionViewCell
                cell.configure(with: [70, 22, 60, 42, 80, 75, 48])
                return cell
            default:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "AwardsCell",
                    for: indexPath
                ) as! AwardsCollectionViewCell
                cell.configure(name: "Focused Champ", date: "21/11/2025")
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TrendCell",
                for: indexPath
            )
            
            let months = ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov"]
            let values1 = [50, 58, 50, 70, 75, 85]
            let values2 = [70, 75, 72, 80, 85, 90]
            
            let chartData = (0..<6).map {
                TrendData(
                    month: months[$0],
                    value: Double(
                        indexPath.item == 0 ? values1[$0] : values2[$0]
                    )
                )
            }
            
            cell.contentConfiguration = UIHostingConfiguration {
                TrendCardView(
                    title: indexPath.item == 0 ? "Full checkup" : "Exercise Accuracy",
                    averageScore: indexPath.item == 0 ? "78" : "89",
                    data: chartData
                )
            }
            //.background(.clear)
            
            return cell
        }
    }
}
