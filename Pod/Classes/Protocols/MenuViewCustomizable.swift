//
//  MenuViewCustomizable.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/23/16.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import Foundation

public protocol MenuViewCustomizable {
    var backgroundColor: UIColor { get }
    var selectedBackgroundColor: UIColor { get }
    var height: CGFloat { get }
    var animationDuration: TimeInterval { get }
    var deceleratingRate: CGFloat { get }
    var selectedItemCenter: Bool { get }
    var displayMode: MenuDisplayMode { get }
    var focusMode: MenuFocusMode { get }
    var dummyItemViewsSet: Int { get }
    var menuPosition: MenuPosition { get }
    var dividerImage: UIImage? { get }
    var itemsOptions: [MenuItemViewCustomizable] { get }
}

public extension MenuViewCustomizable {
    var backgroundColor: UIColor {
        return UIColor.white
    }
    var selectedBackgroundColor: UIColor {
        return UIColor.white
    }
    var height: CGFloat {
        return 50
    }
    var animationDuration: TimeInterval {
        return 0.3
    }
    var deceleratingRate: CGFloat {
        return UIScrollView.DecelerationRate.fast.rawValue
    }
    var selectedItemCenter: Bool {
        return true
    }
    var displayMode: MenuDisplayMode {
        return .standard(widthMode: .flexible, centerItem: false, scrollingMode: .pagingEnabled)
    }
    var focusMode: MenuFocusMode {
        return .underline(height: 3, color: UIColor.blue, horizontalPadding: 0, verticalPadding: 0)
    }
    var dummyItemViewsSet: Int {
        return 3
    }
    var menuPosition: MenuPosition {
        return .top
    }
    var dividerImage: UIImage? {
        return nil
    }
}

public enum MenuDisplayMode {
    case standard(widthMode: MenuItemWidthMode, centerItem: Bool, scrollingMode: MenuScrollingMode)
    case segmentedControl
    case infinite(widthMode: MenuItemWidthMode, scrollingMode: MenuScrollingMode)
}

public enum MenuItemWidthMode {
    case flexible
    case fixed(width: CGFloat)
}

public enum MenuScrollingMode {
    case scrollEnabled
    case scrollEnabledAndBouces
    case pagingEnabled
}

public enum MenuFocusMode {
    case none
    case underline(height: CGFloat, color: UIColor, horizontalPadding: CGFloat, verticalPadding: CGFloat)
    case roundRect(radius: CGFloat, horizontalPadding: CGFloat, verticalPadding: CGFloat, selectedColor: UIColor)
}

public enum MenuPosition {
    case top
    case bottom
}
