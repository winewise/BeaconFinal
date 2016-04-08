//
//  ColorPickerCell.swift
//  BeaconSearchApp
//
//  Created by Developer 1 on 2015-12-17.
//  Copyright © 2015 Ap1. All rights reserved.
//

import UIKit

class ColorPickerCell: UITableViewCell, UIPickerViewDataSource,UIPickerViewDelegate {
    
    var currentIndexPath: NSIndexPath?
    weak var addCompanyViewController: AddCompanyViewController?
    var pickerColors: [UIColor] = []
    var pickerColorNames: [String] = []
    
    @IBOutlet weak var pickerView: UIPickerView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.pickerColors.removeAll()
        self.pickerColorNames.removeAll()
        
        let colors = [0, 51, 102, 153, 204, 255]
        
        for red in colors{
            let cgred = CGFloat(red) / 255
            for green in colors{
                let cggreen = CGFloat(green) / 255
                for blue in colors{
                    let cgblue = CGFloat(blue) / 255
                    let color = UIColor(red: cgred, green: cggreen, blue: cgblue, alpha: 1)
                    pickerColors.append(color)
                    pickerColorNames.append(color.toHexString())
                }
            }
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    //MARK: - Delegates and data sources
    //MARK: Data Sources
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerColorNames.count
    }
    //MARK: Delegates
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerColorNames[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let indexPath = currentIndexPath {
            self.addCompanyViewController?.updateDataField(indexPath, value: pickerColors[row].toHexString())
        }
        
        //myLabel.text = pickerData[row]
    }
    
    func pickerView(pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let titleData = pickerColorNames[row]
        let myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont(name: "Georgia", size: 26.0)!,NSForegroundColorAttributeName:UIColor.blueColor()])
        return myTitle
    }
    
    /* better memory management version */
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        var pickerLabel = view as! UILabel!
       
        let titleData = pickerColorNames[row]
        if view == nil {  //if no label there yet
            pickerLabel = UILabel()
            pickerLabel.backgroundColor = pickerColors[row]
        }
        
        let myTitle = NSAttributedString(string: titleData, attributes: [NSFontAttributeName:UIFont(name: "Georgia", size: 26.0)!,NSForegroundColorAttributeName:UIColor.whiteColor()])
        pickerLabel!.attributedText = myTitle
        pickerLabel!.textAlignment = .Center
        
        return pickerLabel
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 36.0
    }
    // for best use with multitasking , dont use a constant here.
    //this is for demonstration purposes only.
    func pickerView(pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 200
    }
}

infix operator >>= {}
func >>=<A, B>(xs: [A], f: A -> [B]) -> [B] {
    return xs.map(f).reduce([], combine: +)
}

func between<T>(x: T, ys: [T]) -> [[T]] {
    if let (head, tail) = ys.decompose {
        return [[x] + ys] + between(x, ys: tail).map { [head] + $0 }
    } else {
        return [[x]]
    }
}

func permutations<T>(xs: [T]) -> [[T]] {
    if let (head, tail) = xs.decompose {
        return permutations(tail) >>= { permTail in
            between(head, ys: permTail)
        }
    } else {
        return [[]]
    }
}

extension Array {
    var decompose : (head: Element, tail: [Element])? {
        return (count > 0) ? (self[0], Array(self[1..<count])) : nil
    }
}