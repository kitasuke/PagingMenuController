//
//  UIViewController+MenuItemImage.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 4/29/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import Foundation

var MenuItemImageKey: UInt8 = 0
var MenuItemDescKey: UInt8 = 1
public extension UIViewController {
    var menuItemImage: UIImage? {
        get {
            guard let image = objc_getAssociatedObject(self, &MenuItemImageKey) as? UIImage else { return nil }
            return image
        }
        set {
            objc_setAssociatedObject(self, &MenuItemImageKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var menuItemDesc: String? {
        get {
            guard let desc = objc_getAssociatedObject(self, &MenuItemDescKey) as? String else { return nil }
            return desc
        }
        set {
            objc_setAssociatedObject(self, &MenuItemDescKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}