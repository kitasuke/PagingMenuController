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
    var displayMode: MenuItemDisplayMode { get }
}

public extension MenuItemViewCustomizable {
    var horizontalMargin: CGFloat {
        return 20
    }
    var displayMode: MenuItemDisplayMode {
        let title = MenuItemText()
        return .text(title: title)
    }
}

public enum MenuItemDisplayMode {
    case text(title: MenuItemText)
    case multilineText(title: MenuItemText, description: MenuItemText)
    case image(image: UIImage, selectedImage: UIImage?)
    case custom(view: UIView)
}

public struct MenuItemText {
    let text: String
    let color: UIColor
    let selectedColor: UIColor
    let font: UIFont
    let selectedFont: UIFont
    
    public init(text: String = "Menu",
                color: UIColor = UIColor.lightGray,
                selectedColor: UIColor = UIColor.black,
                font: UIFont = UIFont.systemFont(ofSize: 16),
                selectedFont: UIFont = UIFont.systemFont(ofSize: 16)) {
        self.text = text
        self.color = color
        self.selectedColor = selectedColor
        self.font = font
        self.selectedFont = selectedFont
    }
}
