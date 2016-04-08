//
//  Util.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2015-11-11.
//  Copyright © 2015 Ap1. All rights reserved.
//

import Foundation

public class Util {
    public class func uniq<S: SequenceType, E: Hashable where E==S.Generator.Element>(source: S) -> [E] {
        var seen: [E:Bool] = [:]
        return source.filter { seen.updateValue(true, forKey: $0) == nil }
    }
    
    public class func getImageWithColor(color: UIColor, drawText: NSString, size: CGSize) -> UIImage {
        let rect = CGRectMake(0, 0, size.width, size.height)
        let fontRect = CGRectMake(0, 2, size.width, size.height)
        let textColor: UIColor = UIColor.whiteColor()
        let textFont: UIFont = UIFont.systemFontOfSize(23)
        
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.alignment = NSTextAlignment.Center
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
            NSParagraphStyleAttributeName: paraStyle
        ]
        
        color.setFill()
        UIRectFill(rect)
        
        drawText.drawInRect(fontRect, withAttributes: textFontAttributes)
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    
    
    public class func getRandomColor() -> UIColor {
        let randomRed: CGFloat = CGFloat(drand48())
        let randomGreen: CGFloat = CGFloat(drand48())
        let randomBlue: CGFloat = CGFloat(drand48())
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
    }
    
    public class func convertToBool(value : String) -> Bool {
        switch value {
        case "True", "true", "yes", "1":
            return true
        case "False", "false", "no", "0":
            return false
        default:
            return false
        }
    }
}

extension UIColor {
    public convenience init?(hexString: String) {
        let scanner = NSScanner(string: hexString)
        var color:UInt32 = 0;
        scanner.scanHexInt(&color)

        let mask = 0x000000FF
        let r = CGFloat(Float(Int(color >> 16) & mask)/255.0)
        let g = CGFloat(Float(Int(color >> 8) & mask)/255.0)
        let b = CGFloat(Float(Int(color) & mask)/255.0)
        
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
    
    public func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return NSString(format:"%06x", rgb) as String
    }
}

public extension UIViewController {
    
    public func showLoading() {
        let dx: CGFloat = 100.0
        let dy: CGFloat = 100.0
        let x = (self.view.frame.width - CGFloat(dx)) / 2
        let y = (self.view.frame.height - CGFloat(dy)) / 2
        
        let loadingView = SpinnerView(frame: CGRectMake(x, y, dx, dy))
        self.view.addSubview(loadingView)
        
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()
    }
    
    
    public func hideLoading() {
        for view in self.view.subviews {
            if ( view.isKindOfClass(SpinnerView) ) {
                view.removeFromSuperview()
            }
        }
        
        UIApplication.sharedApplication().endIgnoringInteractionEvents()
    }
}

public class SpinnerView: UIView {
    
    let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle:UIActivityIndicatorViewStyle.WhiteLarge)
    var indicatorBackgroundColor: UIColor = UIColor.blackColor()
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        self.backgroundColor = self.indicatorBackgroundColor
        self.alpha = 0.4
        self.layer.cornerRadius = 10.0
        
        self.addSubview(activityIndicator)
        activityIndicator.frame = CGRectMake(0, 0, self.frame.width, self.frame.height)
        activityIndicator.startAnimating()
    }
}