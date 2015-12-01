//
//  MenuItemView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

public class MenuItemView: UIView {
    
    public private(set) var titleLabel: UILabel!
    private var options: PagingMenuOptions!
    private var title: String!
    private var widthLabelConstraint: NSLayoutConstraint!
    
    // MARK: - Lifecycle
    
    internal init(title: String, options: PagingMenuOptions) {
        super.init(frame: CGRectZero)
        
        self.options = options
        self.title = title
        
        setupView()
        constructLabel()
        layoutLabel()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: - Constraints manager
    
    internal func updateLabelConstraints(size size: CGSize) {
        // set width manually to support ratotaion
        if case .SegmentedControl = options.menuDisplayMode {
            let labelSize = calculateLableSize(size)
            widthLabelConstraint.constant = labelSize.width
        }
    }
    
    // MARK: - Label changer
    
    internal func focusLabel(selected: Bool) {
        if case .RoundRect = options.menuItemMode {
            backgroundColor = UIColor.clearColor()
        } else {
            backgroundColor = selected ? options.selectedBackgroundColor : options.backgroundColor
        }
        titleLabel.textColor = selected ? options.selectedTextColor : options.textColor
        titleLabel.font = selected ? options.selectedFont : options.font

        // adjust label width if needed
        let labelSize = calculateLableSize()
        widthLabelConstraint.constant = labelSize.width
    }
    
    // MARK: - Constructor
    
    private func setupView() {
        if case .RoundRect = options.menuItemMode {
            backgroundColor = UIColor.clearColor()
        } else {
            backgroundColor = options.backgroundColor
        }
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func constructLabel() {
        titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = options.textColor
        titleLabel.font = options.font
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.userInteractionEnabled = true
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
    }
    
    private func layoutLabel() {
        let viewsDictionary = ["label": titleLabel]
        
        let labelSize = calculateLableSize()

        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[label]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[label]|", options: [], metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        
        widthLabelConstraint = NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: labelSize.width)
        widthLabelConstraint.active = true
    }
    
    // MARK: - Size calculator
    
    private func calculateLableSize(size: CGSize = UIScreen.mainScreen().bounds.size) -> CGSize {
        let labelSize = NSString(string: title).boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: titleLabel.font], context: nil).size

        let itemWidth: CGFloat
        switch options.menuDisplayMode {
        case let .Standard(widthMode, _, _):
            itemWidth = labelWidth(labelSize, widthMode: widthMode)
        case .SegmentedControl:
            itemWidth = size.width / CGFloat(options.menuItemCount)
        case let .Infinite(widthMode):
            itemWidth = labelWidth(labelSize, widthMode: widthMode)
        }
        
        let itemHeight = floor(labelSize.height)
        return CGSizeMake(itemWidth + calculateHorizontalMargin() * 2, itemHeight)
    }
    
    private func labelWidth(labelSize: CGSize, widthMode: PagingMenuOptions.MenuItemWidthMode) -> CGFloat {
        switch widthMode {
        case .Flexible: return ceil(labelSize.width)
        case let .Fixed(width): return width
        }
    }
    
    private func calculateHorizontalMargin() -> CGFloat {
        if case .SegmentedControl = options.menuDisplayMode {
            return 0.0
        }
        return options.menuItemMargin
    }
}
