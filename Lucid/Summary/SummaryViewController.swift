//
//  SummaryViewController.swift
//  Lucid
//
//  Created by Kanishka Bansal on 08/02/26.
//

import UIKit
import SwiftUI

class SummaryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet var collectionView: UICollectionView!

    // MARK: - Biweekly Test Logic
    private var isTestDue: Bool {
        let defaults = UserDefaults.standard
        guard let lastTestDate = defaults.object(forKey: "lastEyeTestDate") as? Date else {
            return true
        }
        let daysSinceLast = Calendar.current.dateComponents([.day], from: lastTestDate, to: Date()).day ?? 0
        return daysSinceLast >= 14
    }

    // MARK: - Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        collectionView.reloadData()
        setupBackground()

        collectionView.register(
            UICollectionReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "HeaderView"
        )
        collectionView.register(UINib(nibName: "DailyExerciseCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "DailyExerciseCell")
        collectionView.register(UINib(nibName: "AwardsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "AwardsCell")
        collectionView.register(UINib(nibName: "DigitalEyeStrainCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "EyeStrainCell")
        collectionView.register(UINib(nibName: "LowLightScreenUsageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "LowLightCell")
        collectionView.register(UINib(nibName: "TrandsCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "TrendCell")
        collectionView.register(UINib(nibName: "SummaryInsightCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "AlertCell")
        collectionView.register(UINib(nibName: "StreakCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "StreakCell")

        collectionView.collectionViewLayout = createLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    // MARK: - Background
    private func setupBackground() {
        let bgImageView = UIImageView(image: UIImage(named: "BackgroundGradient"))
        bgImageView.contentMode = .scaleAspectFill
        self.collectionView.backgroundView = bgImageView
        self.collectionView.backgroundColor = .clear
    }

    // MARK: - Layout
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { (sectionIndex, layoutEnv) -> NSCollectionLayoutSection? in

            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )

            if sectionIndex == 0 {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(120))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0)
                section.boundarySupplementaryItems = [sectionHeader]
                return section

            } else if sectionIndex == 1 {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.50), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(200))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 4, trailing: 4)
                return section

            } else {
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(180))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
                let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 20, trailing: 0)
                section.boundarySupplementaryItems = [sectionHeader]
                return section
            }
        }
    }

    // MARK: - Supplementary Views
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath)
        header.subviews.forEach { $0.removeFromSuperview() }
        let label = UILabel()
        if indexPath.section == 2 {
            label.frame = CGRect(x: 16, y: 10, width: header.frame.width - 32, height: 30)
            label.text = "Trends"
            label.font = .systemFont(ofSize: 24, weight: .bold)
        }
        label.textColor = .white
        header.addSubview(label)
        return header
    }

    // MARK: - DataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int { return 3 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return 2 }
        else if section == 1 { return 4 }
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
                cell.delegate = self
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
                let todayRecord = ExerciseDataManager.shared.fetchTodayRecord()
                let completedMins = todayRecord.completedSeconds / 60
                let goalMins = todayRecord.goalSeconds / 60
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrendCell", for: indexPath)
            let months = ["Jun", "Jul", "Aug", "Sep", "Oct", "Nov"]
            let values1 = [50, 58, 50, 70, 75, 85]
            let values2 = [70, 75, 72, 80, 85, 90]
            let chartData = (0..<6).map {
                TrendData(month: months[$0], value: Double(indexPath.item == 0 ? values1[$0] : values2[$0]))
            }
            cell.contentConfiguration = UIHostingConfiguration {
                TrendCardView(
                    title: indexPath.item == 0 ? "Full checkup" : "Exercise Accuracy",
                    averageScore: indexPath.item == 0 ? "78" : "89",
                    data: chartData
                )
            }
            return cell
        }
    }

    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let insightCell = cell as? SummaryInsightCollectionViewCell {
            insightCell.startDisplaying(isTestDue: isTestDue)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let insightCell = cell as? SummaryInsightCollectionViewCell {
            insightCell.stopDisplaying()
        }
    }
}

// MARK: - SummaryInsightCellDelegate
extension SummaryViewController: SummaryInsightCellDelegate {

    func didTapInsightCard(nibName: String, cardType: InsightCardType) {
        switch cardType {

        case .exercise:
            switch nibName {
            case "blinkTrainingViewController":
                let vc = blinkTrainingViewController(nibName: "blinkTrainingViewController", bundle: nil)
                navigationController?.pushViewController(vc, animated: true)
            case "EyeExercisesTViewController":
                let storyboard = UIStoryboard(name: "EyeTests", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "EyeExercisesTViewController") as! ExerciseTableViewController
                navigationController?.pushViewController(vc, animated: true)
            case "nearFarFocusViewController":
                let vc = nearFarFocusViewController(nibName: "nearFarFocusViewController", bundle: nil)
                navigationController?.pushViewController(vc, animated: true)
            default:
                break
            }

        case .test:
            startEyeTestSequence()

        case .info:
            break
        }
    }

    // MARK: - Test Sequence
    private func startEyeTestSequence() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ExerciseTableViewController") as! ExerciseTableViewController
        vc.onTestComplete = { [weak self] in
            self?.startLandoltTest()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func startLandoltTest() {
        let storyboard = UIStoryboard(name: "EyeTests", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "LandoltCViewController") as! LandoltCViewController
        vc.onTestComplete = { [weak self] in
            self?.startOSDITest()
        }
        navigationController?.pushViewController(vc, animated: true)
    }

    private func startOSDITest() {
        let storyboard = UIStoryboard(name: "EyeTests", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "OSDISlideViewController") as! OSDIViewController
        vc.onTestComplete = { [weak self] in
            guard let self = self else { return }
            self.navigationController?.popToViewController(self, animated: true)
        }
        navigationController?.pushViewController(vc, animated: true)
    }
}
