//
//  MenuItemView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import Foundation

class MenuItemView: UIView {
    
    private var options: PagingMenuOptions!
    private var titleLabel: UILabel!
    private var underlineView: UIView!
    
    // MARK: - Lifecycle
    
    internal init(title: String, options: PagingMenuOptions) {
        super.init(frame: CGRectZero)
        
        self.options = options
        self.backgroundColor = options.backgroundColor
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        self.constructLabel(title: title)
        self.layoutLabel()
        switch options.menuItemMode {
        case .Underline(let height, let color, let selectedColor):
            self.constructUnderlineView(color: color)
            self.layoutUnderlineView(height: height)
        case .RoundRect: fallthrough
        case .None:
            break;
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // set width and height manually to adjust anytime by property
        let labelSize = self.calculateLableSize()
        for constraint in constraints() as! [NSLayoutConstraint] {
            switch constraint.firstAttribute {
            case .Width:
                constraint.constant = labelSize.width
            case .Height: fallthrough
            default:
                break
            }
        }
    }
    
    // MARK: - Color changer
    
    internal func changeColor(#selected: Bool) {
        self.backgroundColor = selected ? options.selectedBackgroundColor : options.backgroundColor
        self.titleLabel.textColor = selected ? options.selectedTextColor : options.textColor
        switch options.menuItemMode {
        case .Underline(let height, let color, let selectedColor):
            self.underlineView.backgroundColor = selected ? selectedColor : color
        case .RoundRect: fallthrough
        case .None:
            break;
        }
    }
    
    // MARK: - Constructor
    
    private func constructLabel(#title: String) {
        titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = options.textColor
        titleLabel.font = options.font
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.userInteractionEnabled = true
        titleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(titleLabel)
    }
    
    private func layoutLabel() {
        let viewsDictionary = ["label": titleLabel]
        
        let labelSize = self.calculateLableSize()
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[label(width)]|", options: NSLayoutFormatOptions.allZeros, metrics: ["width": labelSize.width], views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[label(height)]", options: NSLayoutFormatOptions.allZeros, metrics: ["height": labelSize.height], views: viewsDictionary)
        
        self.addConstraints(horizontalConstraints)
        self.addConstraints(verticalConstraints)
    }
    
    private func constructUnderlineView(#color: UIColor) {
        underlineView = UIView()
        underlineView.backgroundColor = color
        underlineView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(underlineView)
    }
    
    private func layoutUnderlineView(#height: CGFloat) {
        let viewsDictionary = ["view": underlineView]
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view(width)]|", options: NSLayoutFormatOptions.allZeros, metrics: ["width": self.calculateLableSize().width], views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[view(height)]|", options: NSLayoutFormatOptions.allZeros, metrics: ["height": height], views: viewsDictionary)
        
        self.addConstraints(horizontalConstraints)
        self.addConstraints(verticalConstraints)
    }
    
    // MARK: - Calculator
    
    private func calculateLableSize() -> (width: CGFloat, height: CGFloat) {
        let labelSize = NSString(string: titleLabel.text!).boundingRectWithSize(CGSizeMake(1000, 1000), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: titleLabel.font], context: nil).size
        
        let itemWidth: CGFloat
        switch options.menuDisplayMode {
        case .FlexibleItemWidth(let centerItem, let scrollingMode):
            itemWidth = ceil(labelSize.width) + options.menuItemMargin * 2
        case .FixedItemWidth(let width, let centerItem, let scrollingMode):
            itemWidth = width + options.menuItemMargin * 2
        case .SegmentedControl:
            itemWidth = CGRectGetWidth(UIScreen.mainScreen().bounds) / CGFloat(options.menuItemCount)
        }
        
        let verticalMargin: CGFloat = ceil((options.menuHeight - ceil(labelSize.height)) / 2)
        let itemHeight = floor(labelSize.height) + verticalMargin * 2
        
        return (itemWidth, itemHeight)
    }
}
