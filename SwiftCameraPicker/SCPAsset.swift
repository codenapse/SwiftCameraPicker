//
//  SCPAsset.swift
//  SwiftCameraPicker
//
//  Created by Alin Paulesc on 28/09/16.
//  Copyright © 2016 codenapse. All rights reserved.
//


import UIKit
import Photos
import CocoaLumberjack



public class SCPAsset: NSObject {
    
    
    static let MediaTypes: Dictionary<String, Int> = [
        "photo": 1,
        "video": 2
    ]
    static var imageManager: PHCachingImageManager = PHCachingImageManager()
    var fileExtension: String {
        get {
            if self.mediaType == SCPAsset.MediaTypes["video"] {
                return ".mp4"
            } else {
                return ".jpg"
            }
        }
    }
    var filePathNoExtension: String? {
        get {
            if self.filePath != nil {
                var chars = self.filePath!.stringByReplacingOccurrencesOfString("_original".stringByAppendingString(self.fileExtension), withString: "")
                return chars
            } else if self.mediaPath != nil {
                var chars = self.mediaPath!.stringByReplacingOccurrencesOfString("_original".stringByAppendingString(self.fileExtension), withString: "")
                return chars
            } else {
                return nil
            }
        }
    }
    var generateFileName: String {
        get {
            let uuid = NSUUID().UUIDString
            self.fileName = uuid
            return uuid
        }
    }
    var filePath: String?
    var mediaPath: String!
    var mediaType: Int = SCPAsset.MediaTypes["photo"]! // default value image
    var original: UIImage? = nil
    var image: UIImage? = nil
    var thumb: UIImage? = nil
    var preview: UIImage? = nil
    var fileName: String? = nil
    var inspectionUUID: String? = nil
    var videoUrl: NSURL? = nil
    var avAsset: AVAsset? = nil
    var phAsset: PHAsset? = nil
    var selected: Bool = false
    var deleteToggle: Bool = false
    //
    // MARK:- Init methods
    //
    init(initWithImage: UIImage) {
//        DDLogDebug("[SCPAsset] - initWithImage")
        self.original = initWithImage
        self.mediaType = SCPAsset.MediaTypes["photo"]!
        self.videoUrl = nil
    }
    
    init(initWithTempVideoPath: NSURL) {
//        DDLogDebug("[SCPAsset] - initWithTempVideoPath \(initWithTempVideoPath)")
        self.videoUrl = initWithTempVideoPath
        self.mediaType = SCPAsset.MediaTypes["video"]!
    }
    
    init(initWithPHAsset: PHAsset, videoFlag: Bool = false) {
//        DDLogDebug("[SCPAsset] - initWithPHAsset \(videoFlag)")
        self.phAsset = initWithPHAsset
        if videoFlag {
            self.mediaType = SCPAsset.MediaTypes["video"]!
        } else {
            self.mediaType = SCPAsset.MediaTypes["photo"]!
        }
    }
    
    //
    // MARK:- Public methods
    //
    func writeFileToPath() -> Bool {
        let path = SCPAsset.getOrCreateMediaFilePath(self.fileName!, fileType: self.mediaType, inspectionId: self.inspectionUUID!).stringByAppendingString(self.fileName!)
        
        if self.mediaType == SCPAsset.MediaTypes["photo"]! {
            if self.original == nil {
                self.original = self.getImageFromPHAsset()
            }
            let originalPath = path.stringByAppendingString("_original").stringByAppendingString(self.fileExtension)
            let thumbPath = path.stringByAppendingString("_thumb").stringByAppendingString(self.fileExtension)
            self.filePath = originalPath
            
            let imageData:NSData = UIImageJPEGRepresentation(self.original!, 0.85)!
            imageData.writeToFile(originalPath, atomically: true)
            
            var thumb = SCPAsset.resizeImage(self.original!, size: 100)
            let thumbData: NSData = UIImageJPEGRepresentation(thumb, 0.99)!
            thumbData.writeToFile(thumbPath, atomically: true)
            
            self.image = thumb
            self.thumb = thumb
            self.original = nil
            DDLogDebug("[SCPAsset][writeFileToPath][photo] -> original \(originalPath)")
            DDLogDebug("[SCPAsset][writeFileToPath][photo] -> thumb \(thumbPath)")
        } else {
            DDLogDebug("[SCPAsset][writeFileToPath][video] -> \(path)")
            do {
                var videoPath = path.stringByAppendingString("_original").stringByAppendingString(self.fileExtension)
                let schema = "file://"
                try NSFileManager.defaultManager().copyItemAtURL(self.videoUrl!, toURL: NSURL(string: (schema.stringByAppendingString(videoPath)))!)
                DDLogDebug("[SwiftCameraPicker][SCPAsset] -> video file saved at: \(videoPath)")
                
                self.mediaPath = videoPath
                self.avAsset = AVURLAsset(URL: NSURL(fileURLWithPath: self.mediaPath!))
                self.thumb = self.getThumbnailFromVideo(110)
                self.image = self.thumb!
                let thumbPath = path.stringByAppendingString("_thumb.jpg")
                let thumbData: NSData = UIImageJPEGRepresentation(self.thumb!, 0.99)!
                thumbData.writeToFile(thumbPath, atomically: true)
                
                var previewPath = path.stringByAppendingString("_preview.jpg")
                var preview = self.getThumbnailFromVideo(700)
                var previewData: NSData = UIImageJPEGRepresentation(preview!, 0.85)!
                previewData.writeToFile(previewPath, atomically: true)
            } catch let err as NSError {
                DDLogError("[SwiftCameraPicker][SCPAsset] -> failed to move video file to path: \(path) - err: \(err)")
            }
        }

//        self.original = nil
        return true
    }
    
    func exportVideoFromPhotoLib() {
        if self.avAsset == nil {
            DDLogDebug("[SCPAsset][exportVideoFromPhotoLib] avAsset nil")
            return
        }
        var thumb = self.getThumbnailFromVideo(110)
        self.image = thumb
        self.thumb = thumb
        let path = SCPAsset.getOrCreateMediaFilePath(self.fileName!, fileType: self.mediaType, inspectionId: self.inspectionUUID!).stringByAppendingString(self.fileName!).stringByAppendingString("_original").stringByAppendingString(self.fileExtension)
        self.mediaPath = path
        let exportUrl: NSURL = NSURL.fileURLWithPath(path)
        var exporter = AVAssetExportSession(asset: self.avAsset!, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = exportUrl
        exporter?.outputFileType = AVFileTypeMPEG4
        exporter?.exportAsynchronouslyWithCompletionHandler({
            var thumbPath = path.stringByReplacingOccurrencesOfString("_original.mp4", withString: "_thumb.jpg")
            DDLogDebug("[SCPAsset][exportVideoFromPhotoLib] thumb: \(thumbPath)")
            var imgData: NSData = UIImageJPEGRepresentation(thumb!, 0.85)!
            imgData.writeToFile(thumbPath, atomically: true)
            var previewPath = path.stringByReplacingOccurrencesOfString("_original.mp4", withString: "_preview.jpg")
            var preview = self.getThumbnailFromVideo(700)
            var previewData: NSData = UIImageJPEGRepresentation(preview!, 0.85)!
            previewData.writeToFile(previewPath, atomically: true)
        })
        DDLogDebug("[SCPAsset][exportVideoFromPhotoLib] path: \(path)")
    }
    
    
    func getThumbnailFromVideo(size: Int = 110) -> UIImage? {
        
        if self.avAsset == nil {
            return nil
        }
        let imageGenerator = AVAssetImageGenerator(asset: self.avAsset!)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var time = self.avAsset!.duration
        //If possible - take not the first frame (it could be completely black or white on camara's videos)
        time.value = min(time.value, 3)
        
        do {
            let imageRef = try imageGenerator.copyCGImageAtTime(time, actualTime: nil)
            var img = UIImage(CGImage: imageRef)
            var image = SCPAsset.resizeImage(img, size: CGFloat(size))
            return image
        }
        catch let error as NSError
        {
            DDLogDebug("Image generation failed with error \(error)")
            return nil
        }
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
        SCPAsset.imageManager.requestImageForAsset(self.phAsset!,
                                                       targetSize: targetSize,
                                                       contentMode: contentMode,
                                                       options: options) { (result, _) in if result != nil { img = result! }
        }
        return img!
    }
    //
    // MARK:- Static methods
    //
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
    
    
    static func getOrCreateMediaFilePath(fileUuid: String!, fileType: Int, inspectionId: String) -> String! {
        return SCPAsset.getAndCreateMediaFolder(String(fileType).stringByAppendingString("/"), inspectionId: inspectionId)
    }
    
    
    static func getAndCreateMediaFolder(subfolder:String! = nil, inspectionId: String) -> String? {
        let mediaFolderName: String = "InspectionsMediaFiles/".stringByAppendingString(inspectionId)
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject = paths[0]
        var mediaFolderPath: String! = documentsDirectory.stringByAppendingPathComponent(mediaFolderName)
        let fileManager = NSFileManager.defaultManager()
        
        var isDir: ObjCBool = true
        if !fileManager.fileExistsAtPath(mediaFolderPath, isDirectory: &isDir) {
            do {
                try fileManager.createDirectoryAtPath(mediaFolderPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                DDLogError("[Inspectful][tools] FAILED to create folder `\(mediaFolderName)`:" + error.description)
                return nil
            }
        }
        if subfolder != nil {
            mediaFolderPath = mediaFolderPath.stringByAppendingString("/\(subfolder)")
            var isDir : ObjCBool = true
            if !fileManager.fileExistsAtPath(mediaFolderPath, isDirectory: &isDir) {
                do {
                    try fileManager.createDirectoryAtPath(mediaFolderPath, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    DDLogError("[Inspectful][tools] FAILED to create folder `\(mediaFolderName)`:" + error.description)
                    return nil
                }
            }
        }
        return mediaFolderPath
    }
}





