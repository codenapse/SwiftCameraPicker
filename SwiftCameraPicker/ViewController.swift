//
//  ViewController.swift
//  SwiftCameraPicker
//
//  Created by Radu Cugut on 22/Jul/16.
//  Copyright © 2016 codenapse. All rights reserved.
//

import UIKit


class ViewController: UIViewController, SCPViewControllerCaptureDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(animated: Bool) {
        let cameraPicker = SCPViewController()
        cameraPicker.delegate = self
        self.presentViewController(cameraPicker, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func capturedMediaFilesFromSession(mediaFiles: [UIImage]) {
        for media in mediaFiles {
            print(media)
        }
    }
}

extension UINavigationController {
    public override func shouldAutorotate() -> Bool {
        return false
    }
}