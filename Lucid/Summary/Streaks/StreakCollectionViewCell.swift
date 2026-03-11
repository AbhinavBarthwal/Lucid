//
//  StreakCollectionViewCell.swift
//  LucidSummaryPage
//
//  Created by guest1 on 01/03/26.
//

import UIKit

class StreakCollectionViewCell: UICollectionViewCell {
    
    // Connect all 7 views to this one array by dragging from the dots in Storyboard
    @IBOutlet var streakDayWiseView : [UIView]!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Loop through the views to make them circles
    }
}

