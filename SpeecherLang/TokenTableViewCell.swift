//
//  TokenTableViewCell.swift
//  SpeecherLang
//
//  Created by Alfian Losari on 06/10/19.
//  Copyright © 2019 Alfian Losari. All rights reserved.
//

import UIKit

class TokenTableViewCell: UITableViewCell {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    
    private var texts = [String]()
    
    private var flowLayout: UICollectionViewFlowLayout {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    private let paddingVertical: CGFloat = 16
    private let paddingHorizontal: CGFloat = 16
    
    private var pillHeight: CGFloat {
        return 21 + (paddingVertical * 2)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        flowLayout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 8)
        flowLayout.minimumInteritemSpacing = 8
        flowLayout.minimumLineSpacing = 8
        
        
        collectionView.register(UINib(nibName: "PillCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "Cell")
    }
    
    func update(texts: [String], tableView: UITableView) {
        self.texts = texts
        self.frame = tableView.bounds
        self.layoutIfNeeded()
        self.collectionView.reloadData()
        self.collectionViewHeightConstraint.constant = self.collectionView.collectionViewLayout.collectionViewContentSize.height
    }
}


extension TokenTableViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        texts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PillCollectionViewCell
        let text = texts[indexPath.item]
        cell.textLabel.text = text
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = texts[indexPath.item]
        
        let textWidth = text.widthWithConstrainedHeight(height: pillHeight, font: UIFont.systemFont(ofSize: 17)) + (16.0 * 2) + 2
        let boundsWidth = UIScreen.main.bounds.width - (16.0 * 2)
        let width = textWidth >= boundsWidth ? boundsWidth : textWidth
        return CGSize(width: width , height: pillHeight)
    }
}

extension String {
    
    func widthWithConstrainedHeight(height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.width
    }
    
    func heightWithConstrainedWidth(width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox.height
    }
}
