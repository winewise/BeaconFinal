//
//  ChatViewController.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-01-20.
//  Copyright © 2016 Ap1. All rights reserved.
//

import UIKit
import MultipeerConnectivity

typealias Message = (peerID: MCPeerID, message: String, time: String)

let ServiceType = "Ap1-Chat"
let kMessageCell = "MessageCell"
let kMessageCellRightSettings = "MessageCellRightSettings"

class ChatViewController: UIViewController, MCSessionDelegate, MCNearbyServiceBrowserDelegate, UITextViewDelegate {

    weak var mainTabBarController: MainTabBarController?
    
    var assistant: MCAdvertiserAssistant?
    var browser: MCNearbyServiceBrowser?
    var session: MCSession?
    var peerID: MCPeerID?
    var peerImageData: NSData?
    var connectedPeers: [MCPeerID] = []
    var foundPeers: [MCPeerID] = []
    var peerObjectIds: [MCPeerID: String] = [:]
    var peerImages: [MCPeerID: UIImage] = [:]
    var peerColors: [MCPeerID: UIColor] = [:]
    var connectViewController: ConnectViewController?
    var messages: [Message] = []
    let formatter = NSDateFormatter()
    
    @IBOutlet weak var tableView: UITableView!
    //@IBOutlet weak var chatView: UITextView!
    @IBOutlet weak var messageField: UITextView!
    @IBOutlet weak var footerFieldBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 66.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        self.messageField.layer.cornerRadius = 4
         self.messageField.layer.borderWidth = 0.2
        self.messageField.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        formatter.dateFormat = "hh:mm a"
        self.messageField.delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissKeyboard(_:)))
        self.tableView.addGestureRecognizer(tap)
        
        var displayName = UIDevice.currentDevice().name
        if let nickname = PFUser.currentUser()?.objectForKey("nickname") as? String where !nickname.isEmpty {
            displayName = nickname
        }
        else if let user = PFUser.currentUser(), firstName = user.objectForKey("first_name") as? String, lastName = user.objectForKey("last_name") as? String where !firstName.isEmpty {
            displayName = "\(firstName) \(lastName)"
        }
        
        self.peerID = MCPeerID(displayName: displayName)
        self.session = MCSession(peer: peerID!)
        self.session?.delegate = self
        
        self.browser = MCNearbyServiceBrowser(peer: self.peerID!, serviceType: ServiceType)
        self.browser?.delegate = self
        self.browser?.startBrowsingForPeers()
        
        let info: [String : String] = PFUser.currentUser()?.objectId != nil ? ["ObjectId" : PFUser.currentUser()!.objectId!] : ["":""]
        self.assistant = MCAdvertiserAssistant(serviceType: ServiceType, discoveryInfo: info, session: self.session!)
        
        if let visible = PFUser.currentUser()?.objectForKey("visible") as? Bool where !visible {
        }
        else {
            self.assistant?.start()
        }
    }
    
    deinit {
        self.stop()
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var requiredCell: UITableViewCell!
        var identifier = kMessageCell
        let message = self.messages[indexPath.row]
        if let peer = self.peerID where peer == message.peerID {
            identifier = kMessageCellRightSettings
        }
        
        if let cell = tableView.dequeueReusableCellWithIdentifier(identifier, forIndexPath: indexPath) as? MessageCell {
            cell.nameLabel.text = message.peerID.displayName
            cell.messageLabel.text = message.message
            cell.timeLabel.text = message.time
            
            if let color = self.peerColors[message.peerID] {
                cell.colorView.backgroundColor = color
                cell.nameLabel.textColor = color
            }
            else {
                if let user = PFUser.currentUser(), peer = self.peerID where peer == message.peerID {
                    self.updateCellColor(user, cell: cell, peerID: message.peerID)
                }
                else if let objectId = self.peerObjectIds[message.peerID] {
                    let query = PFQuery(className: "_User")
                    query.getObjectInBackgroundWithId(objectId) { (object, eroor) -> Void in
                        if let user = object as? PFUser {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.updateCellColor(user, cell: cell, peerID: message.peerID)
                            })
                        }
                    }
                }
            }
            
            if indexPath.row > 0 && message.peerID == self.messages[indexPath.row-1].peerID {
                cell.userImageView?.hidden = true
                cell.nameLabel.text = ""
                cell.nameLabel.hidden = true
                cell.nameLabelHeight.constant = 0
                
                if message.time == self.messages[indexPath.row-1].time {
                    cell.timeLabel.text = ""
                }
            }
            else if let image = self.peerImages[message.peerID] {
                cell.nameLabelHeight.constant = 21
                cell.nameLabel.hidden = false
                cell.userImageView?.hidden = false
                cell.userImageView?.image = image
                cell.setNeedsLayout()
            }
            else {
                cell.nameLabelHeight.constant = 21
                cell.nameLabel.hidden = false
                cell.userImageView?.hidden = false
                if let user = PFUser.currentUser(), peer = self.peerID where peer == message.peerID {
                    self.updateCellImage(user, cell: cell, peerID: message.peerID)
                }
                else if let objectId = self.peerObjectIds[message.peerID] {
                    let query = PFQuery(className: "_User")
                    query.getObjectInBackgroundWithId(objectId) { (object, eroor) -> Void in
                        if let user = object as? PFUser {
                            dispatch_async(dispatch_get_main_queue(), {
                                self.updateCellImage(user, cell: cell, peerID: message.peerID)
                            })
                        }
                    }
                }
            }
            
            requiredCell = cell
        }
        
        return requiredCell
    }
    
    func updateCellImage(user: PFUser, cell: MessageCell, peerID: MCPeerID) {
        if let pfFile = user.objectForKey("profile_picture") as? PFFile {
            if let showPicture = user.objectForKey("show_picture") as? Bool, peer = self.peerID where peer != peerID && !showPicture {
                if let image = UIImage(named: "profile-placeholder") {
                    self.peerImages[peerID] = image
                    cell.userImageView?.image = image
                    cell.setNeedsLayout()
                }
            }
            else {
                do {
                    let data = try pfFile.getData()
                    if let image = UIImage(data: data) {
                        self.peerImages[peerID] = image
                        cell.userImageView?.image = image
                        cell.setNeedsLayout()
                    }
                }
                catch {
                }
            }
        }
    }
    
    func updateCellColor(user: PFUser, cell: MessageCell, peerID: MCPeerID) {
        if let colorValue = user.objectForKey("color") as? String, color = UIColor(hexString: colorValue) {
            cell.colorView.backgroundColor = color
            cell.nameLabel.textColor = color
            self.peerColors[peerID] = color
        }
    }
    
    func stop() {
        self.foundPeers.removeAll()
        self.connectedPeers.removeAll()
        self.session?.disconnect()
        self.browser?.stopBrowsingForPeers()
        self.assistant?.stop()
    }

    func resetForUserRefresh() {
        self.peerImages.removeAll()
        self.peerColors.removeAll()
        
        if let visible = PFUser.currentUser()?.objectForKey("visible") as? Bool where !visible {
            self.assistant?.stop()
        }
        else {
            self.assistant?.start()
        }
        
        if self.tableView != nil {
            self.tableView.reloadData()
        }
    }
    
    func scrollToLastCell() {
        if self.messages.count > 0 {
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.messages.count-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
    }
    
    func dismissKeyboard(sender: AnyObject) {
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        delay(0.3) { () -> () in
            self.scrollToLastCell()
        }

        if let info = notification.userInfo, value = info[UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardFrame: CGRect = (value).CGRectValue()
            self.footerFieldBottomConstraint.constant = keyboardFrame.size.height + 10 - 49 //tab bar height
            UIView.animateWithDuration(0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        self.footerFieldBottomConstraint.constant = 10
        UIView.animateWithDuration(0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField.returnKeyType==UIReturnKeyType.Send)
        {
            self.sendChat(self)
        }
        
        return true
    }
    
    func updateChat(text : String, fromPeer peerID: MCPeerID) {
        self.messages.append((peerID: peerID, message: text, time: self.formatter.stringFromDate(NSDate())))
        self.tableView.reloadData()
        delay(0.1) { () -> () in
            self.scrollToLastCell()
        }
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID)  {
        // Called when a peer sends an NSData to us
        
        // This needs to run on the main queue
        dispatch_async(dispatch_get_main_queue()) {
            
            let msg = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
            
            self.updateChat(msg  , fromPeer: peerID)
        }
    }
    
    // The following methods do nothing, but the MCSessionDelegate protocol
    // requires that we implement them.
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String,
        fromPeer peerID: MCPeerID, withProgress progress: NSProgress)  {
            
            // Called when a peer starts sending a file to us
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID,
        atURL localURL: NSURL, withError error: NSError?)  {
            // Called when a file has finished transferring from another peer
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream,
        withName streamName: String, fromPeer peerID: MCPeerID)  {
            // Called when a peer establishes a stream with us
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState)  {
        switch state {
        case MCSessionState.Connected:
            if !self.connectedPeers.contains(peerID) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.connectViewController?.tableView.beginUpdates()
                    
                    if self.foundPeers.contains(peerID) {
                        if let index = self.foundPeers.indexOf(peerID) {
                            self.foundPeers.removeObject(peerID)
                            self.connectViewController?.tableView.deleteRowsAtIndexPaths([NSIndexPath(forItem: index, inSection: self.connectedPeers.count > 0 ? 1 : 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                        }
                    }
                    
                    if self.connectedPeers.count == 0 {
                        self.connectViewController?.tableView.insertSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
                    }
                    
                    self.connectedPeers.append(peerID)
                    self.connectViewController?.tableView.insertRowsAtIndexPaths([NSIndexPath(forItem: self.connectedPeers.count-1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)

                    self.connectViewController?.tableView.endUpdates()
                })
            }
            
        case MCSessionState.Connecting:
            break
            
        default:

            dispatch_async(dispatch_get_main_queue(), {
                self.connectViewController?.tableView.beginUpdates()

                if self.connectedPeers.contains(peerID) {
                    self.peerObjectIds.removeValueForKey(peerID)
                    if let index = self.connectedPeers.indexOf(peerID) {
                        self.connectedPeers.removeObject(peerID)
                        self.connectViewController?.tableView.deleteRowsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                        
                        if self.connectedPeers.count == 0 {
                            self.connectViewController?.tableView.deleteSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
                        }
                    }
                }
                else {
                    if self.foundPeers.contains(peerID) {
                        if let index = self.foundPeers.indexOf(peerID), peerCell = self.connectViewController?.tableView.cellForRowAtIndexPath(NSIndexPath(forItem: index, inSection: self.connectedPeers.count > 0 ? 1 : 0)) as? PeerCell {
                            peerCell.activityIndicator.stopAnimating()
                        }
                    }
                }
                
                self.connectViewController?.tableView.endUpdates()
            })
        }
    }
    
    // MARK: MCNearbyServiceBrowserDelegate method implementation
    
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if !foundPeers.contains(peerID) && !connectedPeers.contains(peerID) {
            if let info = info, objectId = info["ObjectId"] {
                self.peerObjectIds[peerID] = objectId
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                self.connectViewController?.tableView.beginUpdates()
                self.foundPeers.append(peerID)
                self.connectViewController?.tableView.insertRowsAtIndexPaths([NSIndexPath(forItem: self.foundPeers.count-1, inSection: self.connectedPeers.count > 0 ? 1 : 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                self.connectViewController?.tableView.endUpdates()
            })
        }
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        dispatch_async(dispatch_get_main_queue(), {
            self.connectViewController?.tableView.beginUpdates()
            
            self.peerObjectIds.removeValueForKey(peerID)
            
            if self.foundPeers.contains(peerID) {
                if let index = self.foundPeers.indexOf(peerID) {
                    self.foundPeers.removeObject(peerID)
                    self.connectViewController?.tableView.deleteRowsAtIndexPaths([NSIndexPath(forItem: index, inSection: self.connectedPeers.count > 0 ? 1 : 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }
            
            if self.connectedPeers.contains(peerID) {
                if let index = self.connectedPeers.indexOf(peerID) {
                    self.connectedPeers.removeObject(peerID)
                    self.connectViewController?.tableView.deleteRowsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                }
            }

            self.connectViewController?.tableView.endUpdates()
        })
    }
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print(error.localizedDescription)
    }
    
    @IBAction func showBrowser(sender: AnyObject) {
        if let navigationController = UIStoryboard(name: "Chat", bundle: nil).instantiateInitialViewController() as? UINavigationController, connectViewController = navigationController.topViewController as? ConnectViewController {
            self.connectViewController = connectViewController
            connectViewController.chatViewController = self
            self.presentViewController(navigationController, animated: true, completion: nil)
        }
    }
    
    @IBAction func sendChat(sender: AnyObject) {
        if let text = self.messageField.text where !text.isEmpty {
            let msg = self.messageField.text!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            
            do {
                try self.session?.sendData(msg! , toPeers: self.session!.connectedPeers , withMode: MCSessionSendDataMode.Unreliable )
            }
            catch {
                print("Send data failed!")
            }
            
            self.updateChat(self.messageField.text!, fromPeer: self.peerID!)
            self.messageField.text = ""
        }
    }
}