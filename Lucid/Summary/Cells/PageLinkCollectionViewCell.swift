//
//  PageLinkCollectionViewCell.swift
//  Lucid
//
//  Created by Abhinav Barthwal on 4/23/26.
//

import UIKit

class PageLinkCollectionViewCell: UICollectionViewCell {

    @IBOutlet var nameLabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configure( Name : String){
        nameLabel.text = Name
    }

}
