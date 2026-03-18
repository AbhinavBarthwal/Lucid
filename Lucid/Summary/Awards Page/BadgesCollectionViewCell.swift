//
//  BadgesCollectionViewCell.swift
//  Lucid
//
//  Created by Kanishka Bansal on 09/03/26.
//

import UIKit

class BadgesCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var iconName: UILabel!
    @IBOutlet weak var iconTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure(name: String, date: String, image: String) {
        iconName.text = name
        iconTime.text = date
        icon.image = UIImage(named: image)
    }
    

}
