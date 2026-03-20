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
        self.contentView.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        self.contentView.layer.cornerRadius = 12
        self.contentView.clipsToBounds = true
    }
    
    func configure(title: String, data: [BlinkBarData], description: String) {
        
        descLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        descLabel.textColor = UIColor(white: 0.6, alpha: 1.0)
        descLabel.text = description
        resultChart.configureChart(title: title, data: data)
    }
}
