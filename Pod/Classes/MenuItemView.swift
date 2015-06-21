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
        self.calculateViewScale()
        
        self.setupView()
        self.constructTitleView()
        self.constructLabel()
        self.layoutTitleView()
        self.layoutLabel()
        
        if case .Underline(let height, let color, _) = options.menuItemMode {
            self.constructUnderlineView(color: color)
            self.layoutUnderlineView(height: height)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: - Constraints manager
    
    internal func updateLabelConstraints(size size: CGSize) {
        // set width manually to support ratotaion
        if case .SegmentedControl = options.menuDisplayMode {
            let labelSize = self.calculateLableSize(size)
            widthLabelConstraint.constant = labelSize.width
            widthViewConstraint.constant = labelSize.width
        }
    }
    
    // MARK: - Color changer
    
    internal func changeColor(selected selected: Bool) {
        self.backgroundColor = selected ? options.selectedBackgroundColor : options.backgroundColor
        self.titleLabel.textColor = selected ? options.selectedTextColor : options.textColor
        switch options.menuItemMode {
        case .Underline(_, let color, let selectedColor):
            self.underlineView.backgroundColor = selected ? selectedColor : color
        case .RoundRect(_, _, _, let selectedColor):
            self.titleView.backgroundColor = selected ? selectedColor : UIColor.clearColor()
        case .None: break
        }
    }
    
    // MARK: - Constructor
    
    private func setupView() {
        self.backgroundColor = options.backgroundColor
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func constructTitleView() {
        titleView = UIView()
        titleView.userInteractionEnabled = true
        titleView.translatesAutoresizingMaskIntoConstraints = false
        if case .RoundRect(let radius, _, _, _) = options.menuItemMode {
            titleView.layer.cornerRadius = radius
        }
        titleView.backgroundColor = UIColor.clearColor()
        self.addSubview(titleView)
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
        titleView.addSubview(titleLabel)
    }
    
    private func layoutTitleView() {
        let viewsDictionary = ["view": titleView]
        
        let labelSize = self.calculateLableSize()
        let margin = self.calculateMargin(labelHeight: labelSize.height)
        let viewSize = self.calculateTitleViewSize(labelSize, margin: margin)
        let viewMargin = self.calculateTitleViewMargin(margin)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-margin-[view]-margin-|", options: NSLayoutFormatOptions(), metrics: ["margin": viewMargin.horizontal], views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-margin@250-[view(height)]-margin@250-|", options: NSLayoutFormatOptions(), metrics: ["height": viewSize.height, "margin": viewMargin.vertical], views: viewsDictionary)
        
        self.addConstraints(horizontalConstraints)
        self.addConstraints(verticalConstraints)
        
        // use property to change constant value anytime
        widthViewConstraint = NSLayoutConstraint(item: titleView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: viewSize.width)
        self.addConstraint(widthViewConstraint)
    }
    
    private func layoutLabel() {
        let viewsDictionary = ["label": titleLabel]
        
        let labelSize = self.calculateLableSize()
        let margin = self.calculateMargin(labelHeight: labelSize.height)
        let labelMargin = self.calculateLabelMargin(margin)
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|-margin-[label]-margin-|", options: NSLayoutFormatOptions(), metrics: ["margin": labelMargin.horizontal], views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-margin@250-[label(height)]-margin@250-|", options: NSLayoutFormatOptions(), metrics: ["height": labelSize.height, "margin": labelMargin.vertical], views: viewsDictionary)
        
        titleView.addConstraints(horizontalConstraints)
        titleView.addConstraints(verticalConstraints)
        
        widthLabelConstraint = NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: labelSize.width)
        widthLabelConstraint.priority = 250 // label's width should be calculated by its view's width
        titleView.addConstraint(widthLabelConstraint)
    }
    
    private func constructUnderlineView(color color: UIColor) {
        underlineView = UIView()
        underlineView.backgroundColor = color
        underlineView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(underlineView)
    }
    
    private func layoutUnderlineView(height height: CGFloat) {
        let viewsDictionary = ["view": underlineView]
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: NSLayoutFormatOptions(), metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[view(height)]|", options: NSLayoutFormatOptions(), metrics: ["height": height], views: viewsDictionary)
        
        self.addConstraints(horizontalConstraints)
        self.addConstraints(verticalConstraints)
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
    
    private func calculateMargin(labelHeight labelHeight: CGFloat) -> (horizontal: CGFloat, vertical: CGFloat) {
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
            self.horizontalViewScale = 0
            self.verticalViewScale = 0
        }
    }
    
    private func calculateLabelMargin(margin: (horizontal: CGFloat, vertical: CGFloat)) -> (horizontal: CGFloat, vertical: CGFloat) {
        let horizontalMargin = margin.horizontal * self.horizontalViewScale
        let verticalMargin = margin.vertical * self.verticalViewScale
        return (horizontalMargin, verticalMargin)
    }
    
    private func calculateTitleViewSize(labelSize: CGSize, margin: (horizontal: CGFloat, vertical: CGFloat)) -> CGSize {
        let width = labelSize.width + margin.horizontal * self.horizontalViewScale * 2
        let height = labelSize.height + margin.vertical * self.verticalViewScale * 2
        return CGSizeMake(width, height)
    }
    
    private func calculateTitleViewMargin(margin: (horizontal: CGFloat, vertical: CGFloat)) -> (horizontal: CGFloat, vertical: CGFloat) {
        let horizontalMargin = margin.horizontal * (1.0 - self.horizontalViewScale)
        let verticalMargin = margin.vertical * (1.0 - self.verticalViewScale)
        return (horizontalMargin, verticalMargin)
    }
}
