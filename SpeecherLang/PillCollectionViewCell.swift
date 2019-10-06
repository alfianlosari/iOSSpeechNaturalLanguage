//
//  PillCollectionViewCell.swift
//  SpeecherLang
//
//  Created by Alfian Losari on 06/10/19.
//  Copyright © 2019 Alfian Losari. All rights reserved.
//

import UIKit

class PillCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var view:  UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.masksToBounds = true
        layer.cornerRadius = 8
        layer.borderColor = UIColor.systemBlue.cgColor
        layer.borderWidth = 1
    }
}
