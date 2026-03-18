//
//  AwardsViewController.swift
//  Lucid
//
//  Created by Kanishka Bansal on 09/03/26.
//

import UIKit
import SwiftUI

class AwardsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
    
    var allBadges: [Badge] = []
    
//    var currAwards = ["10th Test","40 Days Streak","40 Days Streak","40 Days Streak","40 Days Streak","40 Days Streak","40 Days Streak","40 Days Streak","40 Days Streak","40 Days Streak"]
//    var futureAwards = ["40 Days Streak","40 Days Streak","40 Days Streak","40 Days Streak","40 Days Streak","40 Days Streak"]
    
    var currAwards: [Badge] {
            return allBadges.filter { $0.isUnlocked == true }
        }
    
    var futureAwards: [Badge] {
            return allBadges.filter { $0.isUnlocked == false }
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        
        collectionView
            .register(
                UINib(nibName: "BadgesCollectionViewCell", bundle: nil),
                forCellWithReuseIdentifier: "BadgeCell"
            )
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = createLayout()
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 1. Load the latest data from device memory
        allBadges = ProgressManager.shared.loadBadges()
        let record = ProgressManager.shared.loadRecord()
        
        // 2. Check if the user hit any milestones
        checkMilestones(using: record)
    }
    
    private func setupBackground() {
        let bgImageView = UIImageView(
            image: UIImage(named: "BackgroundGradient")
        )
        bgImageView.contentMode = .scaleAspectFill
        self.collectionView.backgroundView = bgImageView
        self.collectionView.backgroundColor = .clear
    }
    
    func createLayout() -> UICollectionViewLayout { return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnv) -> NSCollectionLayoutSection? in
        
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
                widthDimension: .fractionalWidth(0.33),
                heightDimension: .fractionalHeight(0.7)
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
                heightDimension: .absolute(225)
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
            
            section.boundarySupplementaryItems = [sectionHeader]
            return section
        } else {
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.33),
                heightDimension: .fractionalHeight(0.7)
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
                heightDimension: .absolute(225)
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
        
        if indexPath.section == 0 {
            
            label.frame = CGRect(
                x: 16,
                y: 10,
                width: header.frame.width - 32,
                height: 30
            )
            label.text = "Current Awards"
            label.font = .systemFont(ofSize: 24, weight: .bold)
        } else {
            label.frame = CGRect(
                x: 16,
                y: 10,
                width: header.frame.width - 32,
                height: 30
            )
            label.text = "Future Goals"
            label.font = .systemFont(ofSize: 24, weight: .bold)
        }
        
        label.textColor = .white
        header.addSubview(label)
        return header
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    //CHANGE THIS
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return currAwards.count
        } else {
            return futureAwards.count
        }
    }
    
    //THIS AS WELL
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "BadgeCell",
            for: indexPath
        ) as! BadgesCollectionViewCell
        
        if indexPath.section == 0 {
            // 1. Get the Badge object
            let badge = currAwards[indexPath.item]
            
            // 2. Pass the specific properties to the configure method
            cell.configure(
                name: badge.title,
                date: badge.dateEarned ?? "No Date",
                image: badge.imageName
            )
            
            cell.alpha = 1.0
            cell.iconTime.isHidden = false
            
        } else {
            // 1. Get the Badge object
            let badge = futureAwards[indexPath.item]
            
            // 2. Pass the specific properties
            cell.configure(
                name: badge.title,
                date: "Locked",
                image: badge.imageName
            )
            
            cell.alpha = 0.5
            cell.iconTime.isHidden = false
        }
        
        return cell
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func checkMilestones(using record: ExerciseRecord) {
            var didUnlockSomething = false
            
            // Check "1st Exercise" Badge (using the counter)
            if record.counter >= 1 {
                if let index = allBadges.firstIndex(where: { $0.id == "exercise_1" }), !allBadges[index].isUnlocked {
                    unlockBadge(at: index)
                    didUnlockSomething = true
                }
            }
            
            // Check "1 Day Streak" Badge (using the streak)
            if record.currentStreak >= 1 {
                if let index = allBadges.firstIndex(where: { $0.id == "streak_1" }), !allBadges[index].isUnlocked {
                    unlockBadge(at: index)
                    didUnlockSomething = true
                }
            }
            
            // If they unlocked a badge, save the updated master list and reload the screen
            if didUnlockSomething {
                ProgressManager.shared.saveBadges(allBadges)
                collectionView.reloadData()
            } else {
                // Just reload to make sure the UI is fresh
                collectionView.reloadData()
            }
        }
    
    private func unlockBadge(at index: Int) {
            allBadges[index].isUnlocked = true
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            allBadges[index].dateEarned = formatter.string(from: Date())
        }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
