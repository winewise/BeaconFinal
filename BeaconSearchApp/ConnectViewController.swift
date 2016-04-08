//
//  ConnectViewController.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-02-02.
//  Copyright © 2016 Ap1. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ConnectViewController: UITableViewController {
    
    weak var chatViewController: ChatViewController!
    
    var hasConnectedPeers: Bool {
        return self.chatViewController.connectedPeers.count > 0
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return hasConnectedPeers ? 2 : 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if hasConnectedPeers && section == 0 {
            return self.chatViewController.connectedPeers.count
        }
        else {
            return self.chatViewController.foundPeers.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PeerCell", forIndexPath: indexPath)

        if let peerCell = cell as? PeerCell {
            peerCell.activityIndicator.stopAnimating()
            
            var peer: MCPeerID!
            if hasConnectedPeers && indexPath.section == 0 {
                peer = self.chatViewController.connectedPeers[indexPath.row]
                peerCell.selectionStyle = .None
            }
            else {
                peer = self.chatViewController.foundPeers[indexPath.row]
                peerCell.selectionStyle = .Default
            }
            
            peerCell.peerImageView?.image = nil
            peerCell.setNeedsLayout()
            if let objectId = self.chatViewController.peerObjectIds[peer] {
                let query = PFQuery(className: "_User")
                query.getObjectInBackgroundWithId(objectId) { (object, eroor) -> Void in
                    if let user = object as? PFUser {
                        if let pfFile = user.objectForKey("profile_picture") as? PFFile {
                            if let showPicture = user.objectForKey("show_picture") as? Bool where !showPicture {
                                if let image = UIImage(named: "profile-placeholder") {
                                    peerCell.peerImageView?.image = image
                                    peerCell.setNeedsLayout()
                                }
                            }
                            else {
                                do {
                                    let data = try pfFile.getData()
                                    dispatch_async(dispatch_get_main_queue(), {
                                        if let image = UIImage(data: data) {
                                            peerCell.peerImageView?.image = image
                                            peerCell.setNeedsLayout()
                                        }
                                    })
                                }
                                catch {
                                }
                            }
                        }
                        if let aboutMe = user.objectForKey("about_me") as? String {
                            peerCell.detailLabel.text = aboutMe
                        }
                        else {
                            peerCell.detailLabel.text = ""
                        }
                    }
                }
            }
            
            peerCell.titleLabel.text = peer.displayName
            peerCell.detailLabel.text = ""
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if hasConnectedPeers && indexPath.section == 0 {
        }
        else {
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? PeerCell {
                cell.activityIndicator.startAnimating()
            }
            
            let selectedPeer = self.chatViewController.foundPeers[indexPath.row]
            self.chatViewController.browser?.invitePeer(selectedPeer, toSession: self.chatViewController!.session!, withContext: nil, timeout: 20)
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if hasConnectedPeers && section == 0 {
            return "Connected Peers"
        }
        else {
            return "Other Peers"
        }
    }

    @IBAction func done(sender: AnyObject) {
        self.chatViewController?.connectViewController = nil
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func confirm(sender: AnyObject) {
    }
}