//
//  ColorPickerViewController.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-01-21.
//  Copyright © 2016 Ap1. All rights reserved.
//

import UIKit

protocol ColorPickerDelegate : class {
    func updateDataField(indexPath: NSIndexPath, value: String)
}

class ColorPickerViewController: UIViewController {
    
    var colorPickerController: ColorPickerController?
    weak var delegate: ColorPickerDelegate?
    var currentIndexPath: NSIndexPath?
    var initialColor: UIColor?
    
    @IBOutlet var colorWell:ColorWell?
    @IBOutlet var colorPicker:ColorPicker?
    @IBOutlet var huePicker:HuePicker?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup
        colorPickerController = ColorPickerController(svPickerView: colorPicker!, huePickerView: huePicker!, colorWell: colorWell!)
        colorPickerController?.color = initialColor
        
        // get color updates:
        colorPickerController?.onColorChange = {(color, finished) in
            if finished {
                // reset background color to white
                if let indexPath = self.currentIndexPath {
                    self.delegate?.updateDataField(indexPath, value: color.toHexString())
                }
                
                //self.view.backgroundColor = UIColor.whiteColor()
            } else {
                // set background color to current selected color (finger is still down)
                //self.view.backgroundColor = color
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
