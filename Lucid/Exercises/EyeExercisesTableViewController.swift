import UIKit
import SwiftData

struct ExerciseInfo {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let segueIdentifier: String
}

class ExerciseCollectionViewController: UICollectionViewController {
    
    var modelContext: ModelContext?
    var recommendedExerciseIDs: [String] = []
    
    let allExercises: [ExerciseInfo] = [
        ExerciseInfo(id: "SmoothPursuit", title: "Smooth Pursuits", description: "Slowly follow a moving object with your eyes to keep your vision steady and focused.", iconName: "SmoothPursuits", segueIdentifier: "ShowSmoothPursuits"),
        ExerciseInfo(id: "SaccadicJump", title: "Saccadic Jumps", description: "Practice jumping your gaze quickly between two spots to build speed and accuracy.", iconName: "SaccadicJumps", segueIdentifier: "ShowSaccadicJump"),
        ExerciseInfo(id: "PencilPushup", title: "Pencil Push-Ups", description: "Train your eyes to work together as a team so you can see close-up things without strain.", iconName: "PencilPushUps", segueIdentifier: "ShowPencilPushUps"),
        ExerciseInfo(id: "Figure8", title: "Figure Eight", description: "Trace a loopy path with your eyes to boost flexibility and make focusing feel easier.", iconName: "FigureEight", segueIdentifier: "ShowFigureEight"),
        ExerciseInfo(id: "Blink", title: "Blink Training", description: "Take a moment for full, slow blinks to refresh your eyes and keep them from getting dry.", iconName: "BlinkTraining", segueIdentifier: "ShowBlinkTraining"),
        ExerciseInfo(id: "PeripheralAwareness", title: "Peripheral Awareness", description: "Learn to notice what is happening around you without having to turn your head.", iconName: "PeripheralAwareness", segueIdentifier: "ShowPeripheralAwareness"),
        ExerciseInfo(id: "NearFar", title: "Near Far Focus", description: "Switch focus between close and distant objects to help your eyes adjust faster.", iconName: "NearFarFocus", segueIdentifier: "ShowNearFarFocus")
    ]
    
    var recommendedExercises: [ExerciseInfo] {
        return allExercises.filter { recommendedExerciseIDs.contains($0.id) }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackground()
        
        // Setup Compositional Layout
        collectionView.collectionViewLayout = createLayout()
        
        // Register the Header
        collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "HeaderView")
        
        // Register your custom XIB Cell
        let cellNib = UINib(nibName: "ExerciseCollectionViewCell", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "ExerciseCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Fetch recommendations dynamically whenever the screen appears
        let user = SwiftDataManager.shared.getOrCreateUser()
        self.recommendedExerciseIDs = user.recommendedExercises
        
        // Refresh layout and data every time the view appears
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }
    
    // MARK: - Setup
    private func setupBackground() {
        let bgImageView = UIImageView(image: UIImage(named: "BackgroundGradient"))
        bgImageView.contentMode = .scaleAspectFill
        collectionView.backgroundView = bgImageView
        collectionView.backgroundColor = .clear
    }
    
    // MARK: - Layout Configuration
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] (sectionIndex, environment) -> NSCollectionLayoutSection? in
            guard let self = self else { return nil }

            // Item
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(0.125)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsetsReference = .layoutMargins
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 24, trailing: 0)
            section.interGroupSpacing = 8
            

            // Header
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(40)
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )

            // Decide if this section should have a header
            let showingRecommendations = !self.recommendedExercises.isEmpty
            let isRecommendedSection = (sectionIndex == 0 && showingRecommendations)

            if isRecommendedSection {
                // Show header for the Recommended section
                section.boundarySupplementaryItems = [header]
            } else {
                // Show header for All Exercises; if recommendations are empty, this is section 0
                section.boundarySupplementaryItems = [header]
            }

            // If you truly want to hide specific headers, you can omit boundarySupplementaryItems
            // based on conditions. For example, to hide header when recommendations are empty:
            if !showingRecommendations && sectionIndex == 0 {
                section.boundarySupplementaryItems = []
            }

            return section
        }

        return layout
    }


    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return recommendedExercises.isEmpty ? 1 : 2
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if recommendedExercises.isEmpty {
            return allExercises.count
        } else {
            return section == 0 ? recommendedExercises.count : allExercises.count
        }
    }
    
    // Configure Header
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath)
        header.subviews.forEach { $0.removeFromSuperview() }
        
        // Hide header for the recommended section if there are no recommendations
        if recommendedExercises.isEmpty && indexPath.section == 0 {
            header.isHidden = true
            return header
        } else {
            header.isHidden = false
        }
        
        
        let label = UILabel(frame: CGRect(x: 0, y: 10, width: header.bounds.width, height: 30))
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        
        if indexPath.section == 0 {
            label.text = recommendedExercises.isEmpty ? "" : "Recommended for You"
        } else {
            label.text = "All Exercises"
        }
        
        header.addSubview(label)
        return header
    }

    // Configure Cell
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExerciseCell", for: indexPath) as? ExerciseCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let showingRecommendations = !recommendedExercises.isEmpty
        let isRecommended = showingRecommendations && (indexPath.section == 0)
        let exercise = isRecommended ? recommendedExercises[indexPath.item] : allExercises[indexPath.item]

        cell.configure(with: exercise, isRecommended: isRecommended)

        return cell
    }

    // MARK: - Navigation
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let showingRecommendations = !recommendedExercises.isEmpty
        let exercise = (showingRecommendations && indexPath.section == 0) ? recommendedExercises[indexPath.item] : allExercises[indexPath.item]
        performSegue(withIdentifier: exercise.segueIdentifier, sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? UIViewController {
            destinationVC.hidesBottomBarWhenPushed = true
        }
        
        if let destinationVC = segue.destination as? SmoothPursuitsViewController {
            destinationVC.modelContext = self.modelContext
        } else if let blinkVC = segue.destination as? blinkTrainingViewController {
            blinkVC.modelContext = self.modelContext
        }
    }
}
