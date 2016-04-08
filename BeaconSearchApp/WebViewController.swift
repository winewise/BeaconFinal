//
//  WebViewController.swift
//  FindBeaconTest
//
//  Created by Developer 1 on 2015-09-17.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit
import BeaconSearch

class WebViewController: UIViewController {
    var beacon: Beacon?
    var closestBeacon = false
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadWebView()
        if let beacon = self.beacon {
            self.findBeaconContext?.updateBeaconSeenState(beacon, near: closestBeacon, far: !closestBeacon)
        }
    }
    
    func loadWebView() {
        if self.webView != nil {
            if closestBeacon {
                if let htmlData = beacon?.urlNearContent?.html, urlString = beacon?.urlNear, webUrl = NSURL(string: urlString) {
                    self.webView.loadData(htmlData, MIMEType: "text/html", textEncodingName: "UTF-8", baseURL: webUrl)
                }
                else {
                    if beacon?.urlNear == nil || (beacon?.urlNear != nil && beacon!.urlNear!.isEmpty) {
                        // do nothing
                    }
                    else if let errorCode = beacon?.urlNearContent?.errorCode, errorDescription = beacon?.urlNearContent?.errorDescription {
                        let alertController = UIAlertController(title: "Error \(errorCode)", message: errorDescription, preferredStyle: .Alert)
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                        alertController.addAction(OKAction)
                        self.presentViewController(alertController, animated: true) { }
                    }
                }
            }
            else {
                if let htmlData = beacon?.urlFarContent?.html, urlString = beacon?.urlFar, webUrl = NSURL(string: urlString) {
                    self.webView.loadData(htmlData, MIMEType: "text/html", textEncodingName: "UTF-8", baseURL: webUrl)
                }
                else {
                    if beacon?.urlFar == nil || (beacon?.urlFar != nil && beacon!.urlFar!.isEmpty) {
                        // do nothing
                    }
                    else if let errorCode = beacon?.urlFarContent?.errorCode, errorDescription = beacon?.urlFarContent?.errorDescription {
                        let alertController = UIAlertController(title: "Error \(errorCode)", message: errorDescription, preferredStyle: .Alert)
                        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in }
                        alertController.addAction(OKAction)
                        self.presentViewController(alertController, animated: true) { }
                    }
                }
            }
        }
    }
    
    @IBAction func refreshTapped(sender: UIBarButtonItem) {
        if let beacon = self.beacon {
            self.showLoading()
            self.findBeaconContext?.updateUrlContent(beacon)
            self.loadWebView()
            self.hideLoading()
        }
    }
}