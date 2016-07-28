//
//  MediaFile.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 27/07/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import Foundation
import UIKit

class SCPMediaFile {
    var image: UIImage
    var deletedToggle: Bool = false
    
    init(image: UIImage) {
        self.image = image
    }
    
    static func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}