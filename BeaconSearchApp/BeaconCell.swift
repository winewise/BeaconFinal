//
//  BeaconCell.swift
//  BeaconSearchApp
//
//  Created by Developer 1 on 2015-12-16.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit

class BeaconCell: UITableViewCell {
    
    var indexPath: NSIndexPath?
    weak var viewController: ViewController?
    weak var closestBeaconsViewController: ClosestBeaconsViewController?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var imageViewDisclosure: UIImageView!
    @IBOutlet weak var imageViewDisclosureLeft: UIImageView?
    @IBOutlet weak var infoButton: UIButton?
    @IBOutlet weak var colorImageView: UIImageView?
    @IBOutlet weak var keenButton: UIButton?
    
    var disclosureHidden: Bool {
        get {
            return imageViewDisclosure.hidden
        }
        set {
            imageViewDisclosure.hidden = newValue
            imageViewDisclosureLeft?.hidden = newValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(BeaconCell.imageTapped(_:)))
        gesture.numberOfTapsRequired = 1
        self.colorImageView?.addGestureRecognizer(gesture)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func imageTapped(sender: AnyObject) {
        if let indexPath = self.indexPath {
            self.closestBeaconsViewController?.openUrl(indexPath)
        }
    }
    
    @IBAction func infoButtonTapped(sender: UIBarButtonItem) {
        if let indexPath = self.indexPath {
            self.viewController?.accessoryButtonTapped(indexPath)
        }
    }
    
    @IBAction func keenButtonTapped(sender: UIButton) {
        if let indexPath = self.indexPath {
            self.viewController?.postToKeenWithMockBeaconExit(indexPath)
        }
    }
}