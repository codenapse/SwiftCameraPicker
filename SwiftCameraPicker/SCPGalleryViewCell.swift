//
//  SCPGalleryViewCell.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 02/08/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import UIKit

class SCPGalleryViewCell: UICollectionViewCell {
    
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var selectedFlagView: UIImageView!
    var selectedFlag: Bool = false {
        didSet {
//            imageView.alpha = 0.5
//            selectedFlagView.hidden = false
        }
    }
    
    func toggle() {
        if self.selectedFlag == false {
            self.selectedFlag = true
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectedFlagView.hidden = true
    }

}
