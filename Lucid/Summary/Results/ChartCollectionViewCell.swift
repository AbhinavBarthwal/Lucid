//
//  ChartCollectionViewCell.swift
//  Lucid
//
//  Created by Kanishka Bansal on 16/03/26.
//

import UIKit

class ChartCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var resultChart: ResultChart!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        // Styling the cell container to match the screenshot
        self.contentView.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        self.contentView.layer.cornerRadius = 12
        self.contentView.clipsToBounds = true
    }
    
    func configure(with data: [BlinkBarData]) {
        resultChart.chartData = data
    }
}
