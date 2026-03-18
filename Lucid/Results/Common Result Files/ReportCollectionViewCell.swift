//
//  ReportCollectionViewCell.swift
//  Lucid
//
//  Created by Kanishka Bansal on 15/03/26.
//

import UIKit

class ReportCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var ringGauge: FullRingGauge!
    @IBOutlet weak var scoreLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        self.backgroundColor = .clear
        
        scoreLabel.textColor = .white
        scoreLabel.font = UIFont(name: "SFPro-ExpandedMedium", size: 32)
    }
    
    func configure(score: Int) {
        scoreLabel.text = "\(score)" 
        let progress = CGFloat(score) / 100.0
        ringGauge.setProgress(progress) 
    }
}
