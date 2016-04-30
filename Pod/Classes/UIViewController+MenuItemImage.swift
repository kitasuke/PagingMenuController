//
//  UIViewController+MenuItemImage.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 4/29/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import Foundation

var MenuItemImageKey: UInt8 = 0
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
}