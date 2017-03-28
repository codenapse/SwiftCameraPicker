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



open class SCPAsset: NSObject {
    
    
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
                let chars = self.filePath!.replacingOccurrences(of: "_original" + self.fileExtension, with: "")
                return chars
            } else if self.mediaPath != nil {
                let chars = self.mediaPath!.replacingOccurrences(of: "_original" + self.fileExtension, with: "")
                return chars
            } else {
                return nil
            }
        }
    }
    var generateFileName: String {
        get {
            let uuid = NSUUID().uuidString.lowercased()
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
    var videoUrl: URL? = nil
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
    
    init(initWithTempVideoPath: URL) {
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
        let path = SCPAsset.getOrCreateMediaFilePath(self.fileName!, fileType: self.mediaType, inspectionId: self.inspectionUUID!) + self.fileName!
        
        if self.mediaType == SCPAsset.MediaTypes["photo"]! {
            if self.original == nil {
                self.original = self.getImageFromPHAsset()
            }
            let originalPath = (path + "_original") + self.fileExtension
            let thumbPath = (path + "_thumb") + self.fileExtension
            self.filePath = originalPath
            
            let imageData:Data = UIImageJPEGRepresentation(self.original!, 0.85)!
            try? imageData.write(to: URL(fileURLWithPath: originalPath), options: [.atomic])
            
            let thumb = SCPAsset.resizeImage(self.original!, size: 100)
            let thumbData: Data = UIImageJPEGRepresentation(thumb, 0.99)!
            try? thumbData.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
            
            self.image = thumb
            self.thumb = thumb
            self.original = nil
            DDLogDebug("[SCPAsset][writeFileToPath][photo] -> original \(originalPath)")
            DDLogDebug("[SCPAsset][writeFileToPath][photo] -> thumb \(thumbPath)")
        } else {
            DDLogDebug("[SCPAsset][writeFileToPath][video] -> \(path)")
            do {
                let videoPath = (path + "_original") + self.fileExtension
                let schema = "file://"
                try FileManager.default.copyItem(at: self.videoUrl!, to: URL(string: (schema + videoPath))!)
                DDLogDebug("[SwiftCameraPicker][SCPAsset] -> video file saved at: \(videoPath)")
                
                self.mediaPath = videoPath
                self.avAsset = AVURLAsset(url: URL(fileURLWithPath: self.mediaPath!))
                self.thumb = self.getThumbnailFromVideo(110)
                self.image = self.thumb!
                let thumbPath = path + "_thumb.jpg"
                let thumbData: Data = UIImageJPEGRepresentation(self.thumb!, 0.99)!
                try? thumbData.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
                
                let previewPath = path + "_preview.jpg"
                let preview = self.getThumbnailFromVideo(700)
                let previewData: Data = UIImageJPEGRepresentation(preview!, 0.85)!
                try? previewData.write(to: URL(fileURLWithPath: previewPath), options: [.atomic])
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
        let thumb = self.getThumbnailFromVideo(110)
        self.image = thumb
        self.thumb = thumb
        let path = ((SCPAsset.getOrCreateMediaFilePath(self.fileName!, fileType: self.mediaType, inspectionId: self.inspectionUUID!) + self.fileName!) + "_original") + self.fileExtension
        self.mediaPath = path
        let exportUrl: URL = URL(fileURLWithPath: path)
        let exporter = AVAssetExportSession(asset: self.avAsset!, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = exportUrl
        exporter?.outputFileType = AVFileTypeMPEG4
        exporter?.exportAsynchronously(completionHandler: {
            let thumbPath = path.replacingOccurrences(of: "_original.mp4", with: "_thumb.jpg")
            DDLogDebug("[SCPAsset][exportVideoFromPhotoLib] thumb: \(thumbPath)")
            let imgData: Data = UIImageJPEGRepresentation(thumb!, 0.85)!
            try? imgData.write(to: URL(fileURLWithPath: thumbPath), options: [.atomic])
            let previewPath = path.replacingOccurrences(of: "_original.mp4", with: "_preview.jpg")
            let preview = self.getThumbnailFromVideo(700)
            let previewData: Data = UIImageJPEGRepresentation(preview!, 0.85)!
            try? previewData.write(to: URL(fileURLWithPath: previewPath), options: [.atomic])
        })
        DDLogDebug("[SCPAsset][exportVideoFromPhotoLib] path: \(path)")
    }
    
    
    func getThumbnailFromVideo(_ size: Int = 110) -> UIImage? {
        
        if self.avAsset == nil {
            return nil
        }
        let imageGenerator = AVAssetImageGenerator(asset: self.avAsset!)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var time = self.avAsset!.duration
        //If possible - take not the first frame (it could be completely black or white on camara's videos)
        time.value = min(time.value, 3)
        
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let img = UIImage(cgImage: imageRef)
            let image = SCPAsset.resizeImage(img, size: CGFloat(size))
            return image
        }
        catch let error as NSError
        {
            DDLogDebug("Image generation failed with error \(error)")
            return nil
        }
    }
    
    
    func getImageFromPHAsset(_ targetSize: CGSize = PHImageManagerMaximumSize) -> UIImage {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        var img: UIImage!
        var contentMode: PHImageContentMode
        if targetSize == PHImageManagerMaximumSize {
            contentMode = .aspectFit
        } else {
            contentMode = .aspectFill
        }
        SCPAsset.imageManager.requestImage(for: self.phAsset!,
                                                       targetSize: targetSize,
                                                       contentMode: contentMode,
                                                       options: options) { (result, _) in if result != nil { img = result! }
        }
        return img!
    }
    //
    // MARK:- Static methods
    //
    static func resizeImage(_ image: UIImage, size: CGFloat) -> UIImage {
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
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
//    static func delay(_ delay:Int, closure:@escaping ()->()) -> ()->() {
//        let block: ()->() = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS) {
//            closure()
//        }
//        DispatchQueue.main.asyncAfter(
//            deadline: DispatchTime.now() + Double(Int64(Double(delay) * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: block)
//        return block
//    }
    
    static func delay(delay:Double, closure:@escaping ()->()) -> DispatchWorkItem {
        let delayTime = DispatchTime.now() + delay
        let dispatchWorkItem = DispatchWorkItem(block: closure);
        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: dispatchWorkItem)
        return dispatchWorkItem
    }
    
//    static func delay(delay:Int, closure:@escaping ()->()) -> DispatchWorkItem {
//        var block: DispatchWorkItem //= nil as DispatchWorkItem?
//        let delayTime = DispatchTime.now() + Double(delay)
//        DispatchQueue.main.asyncAfter(deadline: delayTime, execute: {
//            block = DispatchWorkItem{
//                closure()
//            }})
//        return block
//    }
    
    static func getOrCreateMediaFilePath(_ fileUuid: String!, fileType: Int, inspectionId: String) -> String! {
        return SCPAsset.getAndCreateMediaFolder(String(fileType) + "/", inspectionId: inspectionId)
    }
    
    
    static func getAndCreateMediaFolder(_ subfolder:String! = nil, inspectionId: String) -> String? {
        let mediaFolderName: String = "InspectionsMediaFiles/" + inspectionId
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory: AnyObject = paths[0] as AnyObject
        var mediaFolderPath: String! = documentsDirectory.appendingPathComponent(mediaFolderName)
        let fileManager = FileManager.default
        
        var isDir: ObjCBool = true
        if !fileManager.fileExists(atPath: mediaFolderPath, isDirectory: &isDir) {
            do {
                try fileManager.createDirectory(atPath: mediaFolderPath, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                DDLogError("[Inspectful][tools] FAILED to create folder `\(mediaFolderName)`:" + error.description)
                return nil
            }
        }
        if subfolder != nil {
            mediaFolderPath = mediaFolderPath + "/" + (subfolder)
            var isDir : ObjCBool = true
            if !fileManager.fileExists(atPath: mediaFolderPath, isDirectory: &isDir) {
                do {
                    try fileManager.createDirectory(atPath: mediaFolderPath, withIntermediateDirectories: true, attributes: nil)
                } catch let error as NSError {
                    DDLogError("[Inspectful][tools] FAILED to create folder `\(mediaFolderName)`:" + error.description)
                    return nil
                }
            }
        }
        return mediaFolderPath
    }
}





