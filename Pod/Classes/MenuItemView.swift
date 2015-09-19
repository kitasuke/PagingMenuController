//
//  MenuItemView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

class MenuItemView: UIView {
    
    private var options: PagingMenuOptions!
    private var title: String!
    private var titleLabel: UILabel!
    private var widthViewConstraint: NSLayoutConstraint!
    private var widthLabelConstraint: NSLayoutConstraint!
    private var horizontalViewScale: CGFloat!
    private var verticalViewScale: CGFloat!
    
    // MARK: - Lifecycle
    
    internal init(title: String, options: PagingMenuOptions) {
        super.init(frame: CGRectZero)
        
        self.options = options
        self.title = title
        
        // scale for title view
        calculateViewScale()
        
        setupView()
        constructLabel()
        layoutLabel()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: - Constraints manager
    
    internal func updateLabelConstraints(#size: CGSize) {
        // set width manually to support ratotaion
        switch options.menuDisplayMode {
        case .SegmentedControl:
            let labelSize = calculateLableSize(size: size)
            widthLabelConstraint.constant = labelSize.width
            widthViewConstraint.constant = labelSize.width
        default: break
        }
    }
    
    // MARK: - Color changer
    
    internal func changeColor(#selected: Bool) {
        switch options.menuItemMode {
        case .RoundRect(_, _, _, _):
        backgroundColor = UIColor.clearColor()
        default:
        backgroundColor = selected ? options.selectedBackgroundColor : options.backgroundColor
        }
        titleLabel.textColor = selected ? options.selectedTextColor : options.textColor
    }
    
    // MARK: - Constructor
    
    private func setupView() {
        switch options.menuItemMode {
        case .RoundRect(_, _, _, _):
            backgroundColor = UIColor.clearColor()
        default:
            backgroundColor = options.backgroundColor
        }
        setTranslatesAutoresizingMaskIntoConstraints(false)
    }
    
    private func constructLabel() {
        titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = options.textColor
        titleLabel.font = options.font
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.userInteractionEnabled = true
        titleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(titleLabel)
    }
    
    private func layoutLabel() {
        let viewsDictionary = ["label": titleLabel]
        
        let labelSize = calculateLableSize()
        let margin = calculateMargin(labelHeight: labelSize.height)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-margin-[label]-margin-|", options: .allZeros, metrics: ["margin": margin.horizontal], views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-margin@250-[label(height)]-margin@250-|", options: .allZeros, metrics: ["height": labelSize.height, "margin": margin.vertical], views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        
        widthLabelConstraint = NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: labelSize.width)
        widthLabelConstraint.priority = 250 // label's width should be calculated by its view's width
        widthLabelConstraint.active = true
    }
    
    // MARK: - Size calculator
    
    private func calculateLableSize(size: CGSize = UIScreen.mainScreen().bounds.size) -> CGSize {
        let labelSize = NSString(string: title).boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: options.font], context: nil).size
        
        let itemWidth: CGFloat
        switch options.menuDisplayMode {
        case .FlexibleItemWidth(_, _):
            itemWidth = ceil(labelSize.width)
        case .FixedItemWidth(let width, _, _):
            itemWidth = width - options.menuItemMargin * 2
        case .SegmentedControl:
            itemWidth = size.width / CGFloat(options.menuItemCount)
        }
        
        let itemHeight = floor(labelSize.height)
        return CGSizeMake(itemWidth, itemHeight)
    }
    
    private func calculateMargin(#labelHeight: CGFloat) -> (horizontal: CGFloat, vertical: CGFloat) {
        let horizontalMargin: CGFloat
        let verticalMargin = ceil((options.menuHeight - ceil(labelHeight)) / 2)
        
        switch options.menuDisplayMode {
        case .SegmentedControl:
            horizontalMargin = 0.0
            return (horizontalMargin, verticalMargin)
        default:
            horizontalMargin = options.menuItemMargin
            return (horizontalMargin, verticalMargin)
        }
    }
    
    private func calculateViewScale() {
        switch options.menuItemMode {
        case .RoundRect(_, let horizontalScale, let verticalScale, _):
            self.horizontalViewScale = horizontalScale
            self.verticalViewScale = verticalScale
        default:
            horizontalViewScale = 0
            verticalViewScale = 0
        }
    }
}
