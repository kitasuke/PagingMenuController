//
//  PagingMenuOptions.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/17/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import Foundation

public class PagingMenuOptions {
    public var defaultPage = 0
    public var backgroundColor = UIColor.whiteColor()
    public var selectedBackgroundColor = UIColor.whiteColor()
    public var textColor = UIColor.lightGrayColor()
    public var selectedTextColor = UIColor.blackColor()
    public var font = UIFont.systemFontOfSize(16)
    public var menuHeight: CGFloat = 50
    public var menuItemMargin: CGFloat = 20
    public var animationDuration: NSTimeInterval = 0.5
    public var menuDisplayMode = MenuDisplayMode.FlexibleItemWidth(centerItem: false, scrollingMode: MenuScrollingMode.PagingEnabled)
    public var menuItemMode = MenuItemMode.Underline(height: 3, color: UIColor.whiteColor(), selectedColor: UIColor.blueColor())
    internal var menuItemCount = 0
    
    public enum MenuScrollingMode {
        case ScrollEnabled
        case ScrollEnabledAndBouces
        case PagingEnabled
    }
    
    public enum MenuDisplayMode {
        case FlexibleItemWidth(centerItem: Bool, scrollingMode: MenuScrollingMode)
        case FixedItemWidth(width: CGFloat, centerItem: Bool, scrollingMode: MenuScrollingMode)
        case SegmentedControl
    }
    
    public enum MenuItemMode {
        case None
        case Underline(height: CGFloat, color: UIColor, selectedColor: UIColor)
        case RoundRect
    }
    
    public init() {
        
    }
}