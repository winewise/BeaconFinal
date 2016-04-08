//
//  CompanyBeaconCell.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2015-11-13.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit
import BeaconSearch

class CompanyBeaconCell: UITableViewCell {
    var beacon: Beacon?
    weak var companyBeaconsViewController: CompanyBeaconsViewController?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var imageViewDisclosure: UIImageView!
    @IBOutlet weak var colorImageView: UIImageView!
    
    var disclosureHidden: Bool {
        get {
            return imageViewDisclosure.hidden
        }
        set {
            imageViewDisclosure.hidden = newValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(CompanyBeaconCell.imageTapped(_:)))
        gesture.numberOfTapsRequired = 1
        self.colorImageView?.addGestureRecognizer(gesture)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func imageTapped(sender: AnyObject) {
        if let beacon = self.beacon {
            self.companyBeaconsViewController?.openUrl(beacon, closestBeacon: false)
        }
    }
}
