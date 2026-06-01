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
        nameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        nameLabel.textColor = .white
    }
    
    func configure( Name : String){
        nameLabel.text = Name
    }

}
