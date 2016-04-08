//
//  String+Utility.swift
//  BeaconSearchApp
//
//  Created by Hafiz Usama on 2016-01-17.
//  Copyright © 2016 Ap1. All rights reserved.
//

import Foundation
import UIKit

public extension String {
    public var isEmail: Bool {
        do {
            let regex = try NSRegularExpression(pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$", options: .CaseInsensitive)
            return regex.firstMatchInString(self, options: NSMatchingOptions(rawValue: 1), range: NSMakeRange(0, self.characters.count)) != nil
        } catch {
            return false
        }
    }
}