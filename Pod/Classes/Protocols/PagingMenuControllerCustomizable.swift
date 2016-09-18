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
    var animationDuration: TimeInterval { get }
    var isScrollEnabled: Bool { get }
    var backgroundColor: UIColor { get }
    var lazyLoadingPage: LazyLoadingPage { get }
    var menuControllerSet: MenuControllerSet { get }
    var componentType: ComponentType { get }
}

public extension PagingMenuControllerCustomizable {
    var defaultPage: Int {
        return 0
    }
    var animationDuration: TimeInterval {
        return 0.3
    }
    var isScrollEnabled: Bool {
        return true
    }
    var backgroundColor: UIColor {
        return UIColor.white
    }
    var lazyLoadingPage: LazyLoadingPage {
        return .three
    }
    var menuControllerSet: MenuControllerSet {
        return .multiple
    }
}

public enum LazyLoadingPage {
    case one
    case three
}

public enum MenuControllerSet {
    case single
    case multiple
}

public enum ComponentType {
    case menuView(menuOptions: MenuViewCustomizable)
    case pagingController(pagingControllers: [UIViewController])
    case all(menuOptions: MenuViewCustomizable, pagingControllers: [UIViewController])
}
