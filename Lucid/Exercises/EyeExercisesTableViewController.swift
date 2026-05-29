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
            ExerciseInfo(id: "SmoothPursuit", title: "Smooth Pursuits", description: "Improves eye tracking and visual stability.", iconName: "SmoothPursuits", segueIdentifier: "ShowSmoothPursuits", estimatedTimeSeconds: 135),
            ExerciseInfo(id: "SaccadicJump", title: "Saccadic Jumps", description: "Boosts rapid eye movement and reading speed.", iconName: "SaccadicJumps", segueIdentifier: "ShowSaccadicJump", estimatedTimeSeconds: 70),
            ExerciseInfo(id: "PencilPushup", title: "Pencil Push-Ups", description: "Strengthens near focus and eye teaming.", iconName: "PencilPushUps", segueIdentifier: "ShowPencilPushUps", estimatedTimeSeconds: 60),
            ExerciseInfo(id: "Figure8", title: "Figure Eight", description: "Enhances eye flexibility and coordination.", iconName: "FigureEight", segueIdentifier: "ShowFigureEight", estimatedTimeSeconds: 90),
            ExerciseInfo(id: "Blink", title: "Blink Training", description: "Reduces dryness and refreshes eye comfort.", iconName: "BlinkTraining", segueIdentifier: "ShowBlinkTraining", estimatedTimeSeconds: 90),
            ExerciseInfo(id: "PeripheralAwareness", title: "Peripheral Awareness", description: "Expands peripheral vision and awareness.", iconName: "PeripheralAwareness", segueIdentifier: "ShowPeripheralAwareness", estimatedTimeSeconds: 75),
            ExerciseInfo(id: "NearFar", title: "Near Far Focus", description: "Improves focusing ability at different distances.", iconName: "NearFarFocus", segueIdentifier: "ShowNearFarFocus", estimatedTimeSeconds: 110)
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
    
    // MARK: - Layout Configuration
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

            section.boundarySupplementaryItems = [header]

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
    
    // Configure Header
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath)
        header.subviews.forEach { $0.removeFromSuperview() }
        header.isHidden = false
        
        let label = UILabel(frame: CGRect(x: 0, y: 10, width: header.bounds.width, height: 30))
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .white
        label.text = "All Exercises"
        
        header.addSubview(label)
        return header
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
        if let destinationVC = segue.destination as? UIViewController {
            destinationVC.hidesBottomBarWhenPushed = true
        }
    }
}
