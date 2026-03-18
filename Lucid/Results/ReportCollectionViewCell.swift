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
    @IBOutlet weak var detailLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        self.backgroundColor = .clear
        
        // Large "0" score styling
        scoreLabel.textColor = .white
        scoreLabel.font = UIFont(name: "SFPro-ExpandedMedium", size: 48) // Enlarged for impact [cite: 22]
        
        // "OVERALL" label styling
        detailLabel.textColor = .lightGray
    }
    
    func configure(score: Int) {
        scoreLabel.text = "\(score)" 
        let progress = CGFloat(score) / 100.0
        ringGauge.setProgress(progress) // Updates the SwiftUI Ring [cite: 19]
    }
}
