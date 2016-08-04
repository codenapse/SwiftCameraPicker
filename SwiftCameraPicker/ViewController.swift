//
//  ViewController.swift
//  SwiftCameraPicker
//
//  Created by Radu Cugut on 22/Jul/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import UIKit
import CocoaLumberjack


class ViewController: UIViewController, SCPViewControllerCaptureDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showBtnPressed(sender: UIButton) {
        let cameraPicker = SCPViewController()
        cameraPicker.delegate = self
        dispatch_async(dispatch_get_main_queue(), { [weak self] in
            self?.presentViewController(cameraPicker, animated: true, completion: nil)
        })
    }
    func capturedMediaFilesFromSession(mediaFiles: [UIImage]) {
        for media in mediaFiles {
            print(media)
        }
        DDLogDebug("capturedMediaFilesFromSession() -> \(mediaFiles.count)")
    }
}

extension UINavigationController {
    public override func shouldAutorotate() -> Bool {
        return false
    }
}