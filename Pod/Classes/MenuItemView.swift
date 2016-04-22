//
//  MenuItemView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

public class MenuItemView: UIView {
    
    public let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .Center
        label.userInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    public internal(set) var selected: Bool = false {
        didSet {
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
    }
    lazy public private(set) var dividerImage: UIImageView? = {
        let image = UIImageView(image: self.options.menuItemDividerImage)
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    private var options: PagingMenuOptions!
    private var widthLabelConstraint: NSLayoutConstraint!
    private var labelSize: CGSize {
        guard let text = titleLabel.text else { return .zero }
        return NSString(string: text).boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: titleLabel.font], context: nil).size
    }
    private let labelWidth: (CGSize, PagingMenuOptions.MenuItemWidthMode) -> CGFloat = { size, widthMode in
        switch widthMode {
        case .Flexible: return ceil(size.width)
        case .Fixed(let width): return width
        }
    }
    private var horizontalMargin: CGFloat {
        switch options.menuDisplayMode {
        case .SegmentedControl: return 0.0
        default: return options.menuItemMargin
        }
    }
    
    // MARK: - Lifecycle
    
    internal init(title: String, options: PagingMenuOptions, addDivider: Bool) {
        super.init(frame: .zero)
        
        self.options = options
        
        setupView()
        setupLabel(title: title)
        layoutLabel()

        if let _ = options.menuItemDividerImage where addDivider {
            setupDivider()
            layoutDivider()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    // MARK: - Cleanup
    
    internal func cleanup() {
        titleLabel.removeFromSuperview()
    }
    
    // MARK: - Constraints manager
    
    internal func updateLabelConstraints(size size: CGSize) {
        // set width manually to support ratotaion
        if case .SegmentedControl = options.menuDisplayMode {
            let labelSize = calculateLableSize(size)
            widthLabelConstraint.constant = labelSize.width
        }
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
    
    private func setupLabel(title title: String) {
        titleLabel.text = title
        titleLabel.textColor = options.textColor
        titleLabel.font = options.font
        addSubview(titleLabel)
    }
    
    private func setupDivider() {
        guard let dividerImage = dividerImage else { return }
        
        addSubview(dividerImage)
    }

    private func layoutLabel() {
        let viewsDictionary = ["label": titleLabel]
        
        let labelSize = calculateLableSize()

        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[label]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[label]|", options: [], metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        
        widthLabelConstraint = NSLayoutConstraint(item: titleLabel, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: labelSize.width)
        widthLabelConstraint.active = true
    }
    
    private func layoutDivider() {
        guard let dividerImage = dividerImage else { return }
        
        let centerConstraint = NSLayoutConstraint(item: dividerImage, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 1.0)
        addConstraint(centerConstraint)
        let rightConstraint = NSLayoutConstraint(item: dividerImage, attribute: NSLayoutAttribute.Right, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.Right, multiplier: 1.0, constant: 0.0)
        addConstraint(rightConstraint)
    }

    // MARK: - Size calculator
    
    private func calculateLableSize(size: CGSize = UIApplication.sharedApplication().keyWindow!.bounds.size) -> CGSize {
        guard let _ = titleLabel.text else { return .zero }
        
        let itemWidth: CGFloat
        switch options.menuDisplayMode {
        case let .Standard(widthMode, _, _):
            itemWidth = labelWidth(labelSize, widthMode)
        case .SegmentedControl:
            itemWidth = size.width / CGFloat(options.menuItemCount)
        case let .Infinite(widthMode, _):
            itemWidth = labelWidth(labelSize, widthMode)
        }
        
        let itemHeight = floor(labelSize.height)
        return CGSizeMake(itemWidth + horizontalMargin * 2, itemHeight)
    }
}
