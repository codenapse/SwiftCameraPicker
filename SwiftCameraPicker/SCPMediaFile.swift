//
//  MediaFile.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 27/07/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import Foundation
import UIKit
import Photos

class SCPMediaFile {
    var manager = PHImageManager.defaultManager()
    var image: UIImage?
    var deleteToggle: Bool = false
    var phAsset: PHAsset!
    
    
    init(image: UIImage) {
//        print("[SCPMediaFile] init")
        self.image = image
    }
    
    init(image: UIImage, phAsset: PHAsset!) {
//        print("[SCPMediaFile] init")
        self.image = image
        self.phAsset = phAsset
    }
    
    deinit {
        print("[SCPMediaFile] deinit")
//        self.image = nil
//        self.phAsset = nil
    }
    
    func cleanup() {
        self.image = nil
        self.phAsset = nil
    }
    
    func getImageFromPHAsset() -> UIImage {
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
        let options = PHImageRequestOptions()
        options.synchronous = true
        var img: UIImage!
        self.manager.requestImageForAsset(self.phAsset,
                                          targetSize: PHImageManagerMaximumSize,
                                          contentMode: .AspectFit,
                                          options: options) { (result, _) in
                                            if result != nil {
//                                                self.image = result!
                                                img = result!
                                            }
        }
        return img!
//        })
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