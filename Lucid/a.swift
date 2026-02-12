import UIKit

@IBDesignable
class ExpandedLabel: UILabel {
    @IBInspectable var isExpanded: Bool = true {
        didSet {
            updateFont()
        }
    }

    private func updateFont() {
        // iOS 16+ method for Expanded width
        self.font = .systemFont(ofSize: self.font.pointSize,
                                 weight: .medium,
                                 width: .expanded)
    }
    
    override func prepareForInterfaceBuilder() {
        updateFont()
    }
}
