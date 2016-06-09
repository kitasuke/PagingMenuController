//
//  MenuItemViewCustomizable.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/23/16.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import Foundation

public protocol MenuItemViewCustomizable {
    var horizontalMargin: CGFloat { get }
    var dividerImage: UIImage? { get }
    var mode: MenuItemMode { get }
}

public extension MenuItemViewCustomizable {
    var horizontalMargin: CGFloat {
        return 20
    }
    var dividerImage: UIImage? {
        return nil
    }
    var mode: MenuItemMode {
        let title = MenuItemText()
        return .Text(title: title)
    }
}

public enum MenuItemMode {
    case Text(title: MenuItemText)
    case MultilineText(title: MenuItemText, description: MenuItemText)
    case Image(image: UIImage, selectedImage: UIImage?)
}

public struct MenuItemText {
    let text: String
    let color: UIColor
    let selectedColor: UIColor
    let font: UIFont
    let selectedFont: UIFont
    
    public init(text: String = "Menu",
                color: UIColor = UIColor.lightGrayColor(),
                selectedColor: UIColor = UIColor.blackColor(),
                font: UIFont = UIFont.systemFontOfSize(16),
                selectedFont: UIFont = UIFont.systemFontOfSize(16)) {
        self.text = text
        self.color = color
        self.selectedColor = selectedColor
        self.font = font
        self.selectedFont = selectedFont
    }
}