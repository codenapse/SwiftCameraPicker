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
import CocoaLumberjack


class SCPMediaFile {
    var image: UIImage?
    var deleteToggle: Bool = false
    var phAsset: PHAsset!
    var avAsset: AVAsset? = nil
    var mediaPath: String!
    var selected: Bool = false
    static var imageManager: PHCachingImageManager = PHCachingImageManager()
    static let MediaTypes: Dictionary<String, Int> = [
        "photo": 1,
        "video": 2
    ]
    var mediaType: Int = SCPMediaFile.MediaTypes["photo"]!
    
    
    init(image: UIImage) {
        //        print("[SCPMediaFile] init")
        self.image = image
    }
    
    init(image: UIImage, phAsset: PHAsset!) {
        //        print("[SCPMediaFile] init")
        self.image = image
        self.phAsset = phAsset
    }
    
    init(phAsset: PHAsset, cellSize: CGSize = CGSize(width: 110.0, height: 147.0)) {
        self.phAsset = phAsset
        self.image = self.getImageFromPHAsset(cellSize)
    }
    
    init(mediaPath: String) {
        //        DDLogDebug("[SCPMediaFile] init(mediaPath: String)")
        var img = UIImage(contentsOfFile: mediaPath)
        img = SCPMediaFile.resizeImage(img!, size: 110.0)
        self.image = img
        self.mediaPath = mediaPath
    }
    
    init(avAsset: AVAsset) {
        DDLogDebug("[SCPMediaFile] init(avAsset: AVAsset) ")
        self.avAsset = avAsset
        self.mediaType = SCPMediaFile.MediaTypes["video"]!
        self.image = self.getThumbnailFromVideo()
    }
    
    deinit {
        
    }
    
    func cleanup() {
        self.image = nil
        self.phAsset = nil
    }
    
    func getImageFromPHAsset(targetSize: CGSize = PHImageManagerMaximumSize) -> UIImage {
        let options = PHImageRequestOptions()
        options.synchronous = true
        var img: UIImage!
        var contentMode: PHImageContentMode
        if targetSize == PHImageManagerMaximumSize {
            contentMode = .AspectFit
        } else {
            contentMode = .AspectFill
        }
        SCPMediaFile.imageManager.requestImageForAsset(self.phAsset,
                                                       targetSize: targetSize,
                                                       contentMode: contentMode,
                                                       options: options) { (result, _) in if result != nil { img = result! }
        }
        return img!
    }
    
    func getThumbnailFromVideo(size: Int = 110) -> UIImage? {
        
        if self.avAsset == nil {
            return nil
        }
        let imageGenerator = AVAssetImageGenerator(asset: self.avAsset!)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var time = self.avAsset!.duration
        //If possible - take not the first frame (it could be completely black or white on camara's videos)
        time.value = min(time.value, 2)
        
        do {
            let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            var img = UIImage(CGImage: imageRef)
            var image = SCPMediaFile.resizeImage(img, size: CGFloat(size))
            return image
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
    
    static func resizeImage(image: UIImage, size: CGFloat) -> UIImage {
        
        let newWidth: CGFloat
        let scale: CGFloat
        let newHeight: CGFloat
        if image.size.width > image.size.height {
            newWidth = size
            scale = newWidth / image.size.width
            newHeight = image.size.height * scale
        } else {
            newHeight = size
            scale = newHeight / image.size.height
            newWidth = image.size.width * scale
        }
        
        UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight))
        image.drawInRect(CGRectMake(0, 0, newWidth, newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
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
    
    static func delay(delay:Int, closure:()->()) -> dispatch_block_t {
        var block: dispatch_block_t = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS) {
            closure()
        }
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(Double(delay) * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), block)
        return block
    }
    
}