//
//  MetricCollectionViewCell.swift
//  Lucid
//
//  Created by Kanishka Bansal on 15/03/26.
//

import UIKit

class MetricCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        // Dark card background with rounded corners
        self.contentView.backgroundColor = UIColor(white: 1.0, alpha: 0.05)
        self.contentView.layer.cornerRadius = 12
        
        // Label styling to match screenshot
        titleLabel.textColor = .gray
        valueLabel.textColor = UIColor.white
    }
    
    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value 
    }
}
