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
    }
    
    func configureEmptyState(text: String) {
        
        icon.isHidden = true
        iconTime.isHidden = true
        
        iconName.text = text
        iconName.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        iconName.textAlignment = .center
        iconName.numberOfLines = 0
        iconName.textColor = .white
    }
    
    func configure(name: String, date: String, image: String?) {
        
        icon.isHidden = false
        iconTime.isHidden = false
        
        iconName.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        iconName.numberOfLines = 1
        iconName.text = name
        iconTime.text = date
        
        if let imageName = image, !imageName.isEmpty {
            icon.image = UIImage(systemName: imageName)
        } else {
            icon.image = nil
        }
    }
    

}
