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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        
        collectionView.register(UICollectionReusableView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: "HeaderView")
        
        collectionView.register(UINib(nibName: "DailyExerciseCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "DailyExerciseCell")
        collectionView.register(UINib(nibName: "AwardsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "AwardsCell")
        collectionView.register(UINib(nibName: "DigitalEyeStrainCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "EyeStrainCell")
        collectionView.register(UINib(nibName: "LowLightScreenUsageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "LowLightCell")
        collectionView.register(UINib(nibName: "TrandsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TrendCell")
        
        collectionView.collectionViewLayout = createLayout()
        collectionView.dataSource = self
    }
    
    private func setupBackground() {
        let bgImageView = UIImageView(image: UIImage(named: "BackgroundGradient"))
        bgImageView.contentMode = .scaleAspectFill
        self.collectionView.backgroundView = bgImageView
        self.collectionView.backgroundColor = .clear
        
    }
    
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnv) -> NSCollectionLayoutSection? in
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))//(sectionIndex == 0 ? 80 : 50))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            
            if sectionIndex == 0 {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(210))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
                
                section.boundarySupplementaryItems = [sectionHeader]
                return section
            } else {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(180))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
                
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 20, trailing: 0)
                section.boundarySupplementaryItems = [sectionHeader] // Attach header
                return section
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath)
        header.subviews.forEach { $0.removeFromSuperview() }
        
        let label = UILabel()
        
        if indexPath.section == 1 {

            label.frame = CGRect(x: 16, y: 10, width: header.frame.width - 32, height: 30)
            label.text = "Trends"
            label.font = .systemFont(ofSize: 24, weight: .bold)
        }
        
        label.textColor = .white
        header.addSubview(label)
        return header
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? 4 : 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            switch indexPath.item {
            case 0:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DailyExerciseCell", for: indexPath) as! DailyExerciseCollectionViewCell
                cell.configure(current: 9, goal: 20)
                return cell
            case 1:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AwardsCell", for: indexPath) as! AwardsCollectionViewCell
                cell.configure(name: "Focused Champ", date: "21/11/2025")
                return cell
            case 2:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EyeStrainCell", for: indexPath) as! DigitalEyeStrainCollectionViewCell
                cell.configure(with: [70, 22, 60, 42, 80, 75, 48])
                return cell
            default:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "LowLightCell", for: indexPath) as! LowLightScreenUsageCollectionViewCell
                cell.configure(usage: "1h 20m", progress: 0.70)
                return cell
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrendCell", for: indexPath)
                
            // Create the 6 months of data
            let months = ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov"]
            let values1 = [50, 58, 50, 70, 75, 85]
            let values2 = [70, 75, 72, 80, 85, 90]
            
            let chartData = (0..<6).map { TrendData(month: months[$0], value: Double(indexPath.item == 0 ? values1[$0] : values2[$0])) }

            cell.contentConfiguration = UIHostingConfiguration {
                TrendCardView(
                    title: indexPath.item == 0 ? "Full checkup" : "Exercise Accuracy",
                    averageScore: indexPath.item == 0 ? "78" : "89",
                    data: chartData
                )
            }
            .background(.clear)
            
            return cell
        }
    }
}
