import UIKit

struct ExerciseInfo {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let segueIdentifier: String
    let estimatedTimeSeconds: Int
}

class ExerciseCollectionViewController: UICollectionViewController {
    
    let allExercises: [ExerciseInfo] = [
            ExerciseInfo(id: "SmoothPursuit", title: "Smooth Pursuits", description: "It helps you track things better .", iconName: "SmoothPursuits", segueIdentifier: "ShowSmoothPursuits", estimatedTimeSeconds: 135),
            ExerciseInfo(id: "SaccadicJump", title: "Saccadic Jumps", description: "It boosts your eye's responsiveness.", iconName: "SaccadicJumps", segueIdentifier: "ShowSaccadicJump", estimatedTimeSeconds: 70),
            ExerciseInfo(id: "Blink", title: "Blink Training", description: "It helps in keeping eyes moist and fresh.", iconName: "BlinkTraining", segueIdentifier: "ShowBlinkTraining", estimatedTimeSeconds: 90),
            ExerciseInfo(id: "PencilPushup", title: "Pencil Push-Ups", description: "It strengthens your eye muscles.", iconName: "PencilPushUps", segueIdentifier: "ShowPencilPushUps", estimatedTimeSeconds: 60),
            ExerciseInfo(id: "Figure8", title: "Figure Eight", description: "It increases flexibility of eyes.", iconName: "FigureEight", segueIdentifier: "ShowFigureEight", estimatedTimeSeconds: 90),
//            ExerciseInfo(id: "PeripheralAwareness", title: "Peripheral Awareness", description: "Expands peripheral vision and awareness.", iconName: "PeripheralAwareness", segueIdentifier: "ShowPeripheralAwareness", estimatedTimeSeconds: 75),
            ExerciseInfo(id: "NearFar", title: "Near Far Focus", description: "It allows for better focus shift", iconName: "NearFarFocus", segueIdentifier: "ShowNearFarFocus", estimatedTimeSeconds: 110)
        ]

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

        // Recommendations are intentionally not shown here anymore.
        // Refresh layout and data every time the view appears.
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
    
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, environment) -> NSCollectionLayoutSection? in
            // Item
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            // Group
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(100)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            // Section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsetsReference = .layoutMargins
            section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 24, trailing: 0)
            section.interGroupSpacing = 8
            



            return section
        }

        return layout
    }


    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allExercises.count
    }
    

    // Configure Cell
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExerciseCell", for: indexPath) as? ExerciseCollectionViewCell else {
            return UICollectionViewCell()
        }
        let exercise = allExercises[indexPath.item]
        cell.configure(with: exercise, isRecommended: false)

        return cell
    }

    // MARK: - Navigation
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let exercise = allExercises[indexPath.item]
        performSegue(withIdentifier: exercise.segueIdentifier, sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination
        destinationVC.hidesBottomBarWhenPushed = true
    }
}
