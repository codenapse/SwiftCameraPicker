//
//  SCPCollectionViewCell.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 26/07/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import UIKit

class SCPCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var visualEffect: UIVisualEffectView!
    @IBOutlet var imageView: UIImageView!
    
    private var deletedToggle: Bool = false
    private var mediaFile: SCPMediaFile!
    
    
    var image: UIImage! {
        didSet {
            imageView.image = image
        }
    }
    
    
    func toggle() {
//        print("SCPCollectionViewCell -> toggle()")
        if self.deletedToggle == false {
            self.deletedToggle = true
            self.selected = true
            self.visualEffect.hidden = false
            self.mediaFile.deletedToggle = true
        } else {
            self.deletedToggle = false
            self.selected = false
            self.visualEffect.hidden = true
            self.mediaFile.deletedToggle = false
        }
        self.layoutSubviews()
    }
    
    func setup(media: SCPMediaFile) {
        self.layer.cornerRadius = 8.0
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor(red:0.27, green:0.27, blue:0.27, alpha:1.0).CGColor
        self.mediaFile = media
        self.visualEffect.hidden = true
        self.image = media.image
    }
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
