//
//  ChartCollectionViewCell.swift
//  Lucid
//
//  Created by Kanishka Bansal on 16/03/26.
//

import UIKit

class ChartCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var resultChart: ResultChart!
    @IBOutlet weak var descLabel: UILabel!

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
        contentView.clipsToBounds = true
    }
    
    func configure(title: String, data: [BlinkBarData], description: String) {
        
        descLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        descLabel.textColor = UIColor.white.withAlphaComponent(0.68)
        descLabel.text = description
        resultChart.configureChart(title: title, data: data)
    }
}
