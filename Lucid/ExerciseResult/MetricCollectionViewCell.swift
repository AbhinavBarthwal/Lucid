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
        contentView.backgroundColor = .exerciseResultCard
        contentView.layer.cornerRadius = 18
        contentView.layer.cornerCurve = .continuous
        contentView.layer.borderWidth = 1
        contentView.layer.borderColor = UIColor.white.withAlphaComponent(0.05).cgColor
        
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.58)
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.75
        valueLabel.textColor = .white
        valueLabel.font = .systemFont(ofSize: 24, weight: .bold)
    }
    
    func configure(title: String, value: String) {
        titleLabel.text = title
        valueLabel.text = value 
    }
}
