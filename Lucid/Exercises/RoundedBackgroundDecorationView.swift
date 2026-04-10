import UIKit

final class RoundedBackgroundDecorationView: UICollectionReusableView {
    static let elementKind = "RoundedBackgroundDecorationView"

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        layer.cornerRadius = 16
        layer.masksToBounds = true
    }
}
