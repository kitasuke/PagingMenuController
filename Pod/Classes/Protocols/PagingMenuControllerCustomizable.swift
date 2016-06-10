//
//  PagingMenuControllerCustomizable.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/23/16.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import Foundation

public protocol PagingMenuControllerCustomizable {
    var defaultPage: Int { get }
    var animationDuration: NSTimeInterval { get }
    var scrollEnabled: Bool { get }
    var backgroundColor: UIColor { get }
    var lazyLoadingPage: LazyLoadingPage { get }
    var menuControllerSet: MenuControllerSet { get }
    var componentType: ComponentType { get }
}

public extension PagingMenuControllerCustomizable {
    var defaultPage: Int {
        return 0
    }
    var animationDuration: NSTimeInterval {
        return 0.3
    }
    var scrollEnabled: Bool {
        return true
    }
    var backgroundColor: UIColor {
        return UIColor.whiteColor()
    }
    var lazyLoadingPage: LazyLoadingPage {
        return .Three
    }
    var menuControllerSet: MenuControllerSet {
        return .Multiple
    }
}

public enum LazyLoadingPage {
    case One
    case Three
}

public enum MenuControllerSet {
    case Single
    case Multiple
}

public enum ComponentType {
    case MenuView(menuOptions: MenuViewCustomizable)
    case PagingController(pagingControllers: [UIViewController])
    case All(menuOptions: MenuViewCustomizable, pagingControllers: [UIViewController])
}