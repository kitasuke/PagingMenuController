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
    var animationDuration: NSTimeInterval { get }
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
        return UIColor.whiteColor()
    }
    var selectedBackgroundColor: UIColor {
        return UIColor.whiteColor()
    }
    var height: CGFloat {
        return 50
    }
    var animationDuration: NSTimeInterval {
        return 0.3
    }
    var deceleratingRate: CGFloat {
        return UIScrollViewDecelerationRateFast
    }
    var selectedItemCenter: Bool {
        return true
    }
    var displayMode: MenuDisplayMode {
        return .Standard(widthMode: .Flexible, centerItem: false, scrollingMode: .PagingEnabled)
    }
    var focusMode: MenuFocusMode {
        return .Underline(height: 3, color: UIColor.blueColor(), horizontalPadding: 0, verticalPadding: 0)
    }
    var dummyItemViewsSet: Int {
        return 3
    }
    var menuPosition: MenuPosition {
        return .Top
    }
    var dividerImage: UIImage? {
        return nil
    }
}

public enum MenuDisplayMode {
    case Standard(widthMode: MenuItemWidthMode, centerItem: Bool, scrollingMode: MenuScrollingMode)
    case SegmentedControl
    case Infinite(widthMode: MenuItemWidthMode, scrollingMode: MenuScrollingMode)
}

public enum MenuItemWidthMode {
    case Flexible
    case Fixed(width: CGFloat)
}

public enum MenuScrollingMode {
    case ScrollEnabled
    case ScrollEnabledAndBouces
    case PagingEnabled
}

public enum MenuFocusMode {
    case None
    case Underline(height: CGFloat, color: UIColor, horizontalPadding: CGFloat, verticalPadding: CGFloat)
    case RoundRect(radius: CGFloat, horizontalPadding: CGFloat, verticalPadding: CGFloat, selectedColor: UIColor)
}

public enum MenuPosition {
    case Top
    case Bottom
}