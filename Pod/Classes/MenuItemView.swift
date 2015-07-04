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
    private var title: String!
    private var titleView: UIView!
    private var titleLabel: UILabel!
    private var underlineView: UIView!
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
        constructTitleView()
        constructLabel()
        layoutTitleView()
        layoutLabel()
        
        switch options.menuItemMode {
        case .Underline(let height, let color, _):
            constructUnderlineView(color: color)
            layoutUnderlineView(height: height)
        default: break
        }
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
        backgroundColor = selected ? options.selectedBackgroundColor : options.backgroundColor
        titleLabel.textColor = selected ? options.selectedTextColor : options.textColor
        switch options.menuItemMode {
        case .Underline(_, let color, let selectedColor):
            underlineView.backgroundColor = selected ? selectedColor : color
        case .RoundRect(_, _, _, let selectedColor):
            titleView.backgroundColor = selected ? selectedColor : UIColor.clearColor()
        case .None: break
        }
    }
    
    // MARK: - Constructor
    
    private func setupView() {
        backgroundColor = options.backgroundColor
        setTranslatesAutoresizingMaskIntoConstraints(false)
    }
    
    private func constructTitleView() {
        titleView = UIView()
        titleView.userInteractionEnabled = true
        titleView.setTranslatesAutoresizingMaskIntoConstraints(false)
        switch options.menuItemMode {
        case .RoundRect(let radius, _, _, _):
            titleView.layer.cornerRadius = radius
        default: break
        }
        titleView.backgroundColor = UIColor.clearColor()
        addSubview(titleView)
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
        titleView.addSubview(titleLabel)
    }
    
    private func layoutTitleView() {
        let viewsDictionary = ["view": titleView]
        
        let labelSize = calculateLableSize()
        let margin = calculateMargin(labelHeight: labelSize.height)
        let viewSize = calculateTitleViewSize(labelSize, margin: margin)
        let viewMargin = calculateTitleViewMargin(margin)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-margin-[view]-margin-|", options: NSLayoutFormatOptions.allZeros, metrics: ["margin": viewMargin.horizontal], views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-margin@250-[view(height)]-margin@250-|", options: NSLayoutFormatOptions.allZeros, metrics: ["height": viewSize.height, "margin": viewMargin.vertical], views: viewsDictionary)
        
        addConstraints(horizontalConstraints)
        addConstraints(verticalConstraints)
        
        // use property to change constant value anytime
        widthViewConstraint = NSLayoutConstraint(item: titleView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: viewSize.width)
        addConstraint(widthViewConstraint)
    }
    
    private func layoutLabel() {
        let viewsDictionary = ["label": titleLabel]
        
        let labelSize = calculateLableSize()
        let margin = calculateMargin(labelHeight: labelSize.height)
        let labelMargin = calculateLabelMargin(margin)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-margin-[label]-margin-|", options: NSLayoutFormatOptions.allZeros, metrics: ["margin": labelMargin.horizontal], views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-margin@250-[label(height)]-margin@250-|", options: NSLayoutFormatOptions.allZeros, metrics: ["height": labelSize.height, "margin": labelMargin.vertical], views: viewsDictionary)
        
        titleView.addConstraints(horizontalConstraints)
        titleView.addConstraints(verticalConstraints)
        
        widthLabelConstraint = NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: labelSize.width)
        widthLabelConstraint.priority = 250 // label's width should be calculated by its view's width
        titleView.addConstraint(widthLabelConstraint)
    }
    
    private func constructUnderlineView(#color: UIColor) {
        underlineView = UIView()
        underlineView.backgroundColor = color
        underlineView.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(underlineView)
    }
    
    private func layoutUnderlineView(#height: CGFloat) {
        let viewsDictionary = ["view": underlineView]
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[view(height)]|", options: NSLayoutFormatOptions.allZeros, metrics: ["height": height], views: viewsDictionary)
        
        addConstraints(horizontalConstraints)
        addConstraints(verticalConstraints)
    }
    
    // MARK: - Size calculator
    
    private func calculateLableSize(size: CGSize = UIScreen.mainScreen().bounds.size) -> CGSize {
        let labelSize = NSString(string: title).boundingRectWithSize(CGSizeMake(1000, 1000), options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: options.font], context: nil).size
        
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
    
    private func calculateLabelMargin(margin: (horizontal: CGFloat, vertical: CGFloat)) -> (horizontal: CGFloat, vertical: CGFloat) {
        let horizontalMargin = margin.horizontal * horizontalViewScale
        let verticalMargin = margin.vertical * verticalViewScale
        return (horizontalMargin, verticalMargin)
    }
    
    private func calculateTitleViewSize(labelSize: CGSize, margin: (horizontal: CGFloat, vertical: CGFloat)) -> CGSize {
        let width = labelSize.width + margin.horizontal * horizontalViewScale * 2
        let height = labelSize.height + margin.vertical * verticalViewScale * 2
        return CGSizeMake(width, height)
    }
    
    private func calculateTitleViewMargin(margin: (horizontal: CGFloat, vertical: CGFloat)) -> (horizontal: CGFloat, vertical: CGFloat) {
        let horizontalMargin = margin.horizontal * (1.0 - horizontalViewScale)
        let verticalMargin = margin.vertical * (1.0 - verticalViewScale)
        return (horizontalMargin, verticalMargin)
    }
}
