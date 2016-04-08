//
//  UploadImageCell.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-02-11.
//  Copyright © 2016 Ap1. All rights reserved.
//

import UIKit

class UploadImageCell: UITableViewCell {
    
    let tapRecognizer = UITapGestureRecognizer()
    
    weak var settingsViewController: SettingsViewController?
    
    @IBOutlet weak var uploadImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tapRecognizer.addTarget(self, action: #selector(UploadImageCell.uploadImageViewTapped(_:)))
        tapRecognizer.delegate = self
        uploadImageView.addGestureRecognizer(tapRecognizer)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func uploadImageViewTapped(sender: AnyObject) {
        self.settingsViewController?.loadImagePicker()
    }
}