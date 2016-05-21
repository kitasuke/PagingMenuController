//
//  MenuItemView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

public class MenuItemView: UIView {
    lazy public var titleLabel: UILabel = self.initLabel()
    lazy public var descriptionLabel: UILabel = self.initLabel()

    lazy public var menuImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.userInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    public internal(set) var selected: Bool = false {
        didSet {
            if case .RoundRect = options.menuItemMode {
                backgroundColor = UIColor.clearColor()
            } else {
                backgroundColor = selected ? options.selectedBackgroundColor : options.backgroundColor
            }
            
            switch options.menuItemViewContent {
            case .Text:
                titleLabel.textColor = selected ? options.selectedTextColor : options.textColor
                titleLabel.font = selected ? options.selectedFont : options.font
                
                // adjust label width if needed
                let labelSize = calculateLabelSize(titleLabel)
                widthConstraint.constant = labelSize.width
            case .MultilineText:
                titleLabel.textColor = selected ? options.selectedTextColor : options.textColor
                titleLabel.font = selected ? options.selectedFont : options.font

                descriptionLabel.textColor = selected ? options.selectedTextColor : options.descTextColor
                descriptionLabel.font = options.descFont

                // adjust label width if needed
                widthConstraint.constant = calculateLabelSize(titleLabel).width
                descriptionWidthConstraint.constant = calculateLabelSize(descriptionLabel).width
            case .Image: break
            }
        }
    }
    lazy public private(set) var dividerImageView: UIImageView? = {
        let imageView = UIImageView(image: self.options.menuItemDividerImage)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    private var options: PagingMenuOptions!
    private var widthConstraint: NSLayoutConstraint!
    private var descriptionWidthConstraint: NSLayoutConstraint!
    private let labelSize: (UILabel) -> CGSize = { label in
        guard let text = label.text else { return .zero }
        return NSString(string: text).boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: label.font], context: nil).size
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

    internal init(title: String, desc: String, options: PagingMenuOptions, addDivider: Bool) {
        super.init(frame: .zero)
        self.options = options
        
        commonInit(addDivider) {
            self.setupDescriptionLabel(title, desc: desc)
            self.layoutMultiLineLabel()
        }
    }
    
    internal init(title: String, options: PagingMenuOptions, addDivider: Bool) {
        super.init(frame: .zero)
        self.options = options
        
        commonInit(addDivider) {
            self.setupTitleLabel(title)
            self.layoutLabel()
        }
    }
    
    internal init(image: UIImage, options: PagingMenuOptions, addDivider: Bool) {
        super.init(frame: .zero)
        self.options = options
        
        commonInit(addDivider) {
            self.setupImageView(image)
            self.layoutImageView()
        }
    }
    
    private func initLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 1
        label.textAlignment = .Center
        label.userInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    private func commonInit(addDivider: Bool, setup: () -> Void) {
        setupView()
        
        setup()
        
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
        switch options.menuItemViewContent {
        case .Text: titleLabel.removeFromSuperview()
        case .MultilineText:
            titleLabel.removeFromSuperview()
            descriptionLabel.removeFromSuperview()
        case .Image: menuImageView.removeFromSuperview()
        }
        
        dividerImageView?.removeFromSuperview()
    }
    
    // MARK: - Constraints manager
    
    internal func updateConstraints(size: CGSize) {
        // set width manually to support ratotaion
        switch (options.menuDisplayMode, options.menuItemViewContent) {
        case (.SegmentedControl, .Text):
            let labelSize = calculateLabelSize(titleLabel, windowSize: size)
            widthConstraint.constant = labelSize.width
        case (.SegmentedControl, .MultilineText):
            widthConstraint.constant = calculateLabelSize(titleLabel, windowSize: size).width
            descriptionWidthConstraint.constant = calculateLabelSize(descriptionLabel, windowSize: size).width
        case (.SegmentedControl, .Image):
            widthConstraint.constant = size.width / CGFloat(options.menuItemCount)
        default: break
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
    
    private func setupDescriptionLabel(title: String, desc: String) {
        setupTitleLabel(title)
        descriptionLabel.text = desc
        descriptionLabel.textColor = options.descTextColor
        descriptionLabel.font = options.descFont
        addSubview(descriptionLabel)
    }
    
    private func setupTitleLabel(title: String) {
        titleLabel.text = title
        titleLabel.textColor = options.textColor
        titleLabel.font = options.font
        addSubview(titleLabel)
    }
    
    private func setupImageView(image: UIImage) {
        menuImageView.image = image
        addSubview(menuImageView)
    }
    
    private func setupDivider() {
        guard let dividerImageView = dividerImageView else { return }
        
        addSubview(dividerImageView)
    }
    
    private func layoutMultiLineLabel() {
        let viewsDictionary = ["titleLabel": titleLabel, "descriptionLabel": descriptionLabel]
        let metrics = ["margin": options.menuItemMargin, "titleHeight": options.menuTitleHeight, "descriptionHeight": options.menuDescriptionHeight]
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[titleLabel]|", options: [], metrics: metrics, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[titleLabel(titleHeight)][descriptionLabel(descriptionHeight)]", options: [], metrics: metrics, views: viewsDictionary)
        let descriptionHorizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[descriptionLabel]|", options: [], metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints + descriptionHorizontalConstraints)
        
        widthConstraint = NSLayoutConstraint(item: titleLabel, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .Width, multiplier: 1.0, constant: calculateLabelSize(titleLabel).width)
        widthConstraint.active = true
        descriptionWidthConstraint = NSLayoutConstraint(item: descriptionLabel, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .Width, multiplier: 1.0, constant: calculateLabelSize(descriptionLabel).width)
        descriptionWidthConstraint.active = true
    }

    private func layoutLabel() {
        let viewsDictionary = ["label": titleLabel]
        
        let labelSize = calculateLabelSize(titleLabel)

        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[label]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[label]|", options: [], metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        
        widthConstraint = NSLayoutConstraint(item: titleLabel, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: labelSize.width)
        widthConstraint.active = true
    }
    
    private func layoutImageView() {
        guard let image = menuImageView.image else { return }
        
        let viewsDictionary = ["imageView": menuImageView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: [], metrics: nil, views: viewsDictionary)
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        
        let width: CGFloat
        switch options.menuDisplayMode {
        case .SegmentedControl: width = UIApplication.sharedApplication().keyWindow!.bounds.size.width / CGFloat(options.menuItemCount)
        default: width = image.size.width
        }
        widthConstraint = NSLayoutConstraint(item: menuImageView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: width)
        widthConstraint.active = true
    }
    
    private func layoutDivider() {
        guard let dividerImageView = dividerImageView else { return }
        
        let centerYConstraint = NSLayoutConstraint(item: dividerImageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 1.0)
        let rightConstraint = NSLayoutConstraint(item: dividerImageView, attribute: .Right, relatedBy: .Equal, toItem: self, attribute: .Right, multiplier: 1.0, constant: 0.0)
        NSLayoutConstraint.activateConstraints([centerYConstraint, rightConstraint])
    }

    // MARK: - Size calculator
    
    private func calculateLabelSize(label: UILabel, windowSize: CGSize = UIApplication.sharedApplication().keyWindow!.bounds.size) -> CGSize {
        guard let _ = label.text else { return .zero }
        
        let itemWidth: CGFloat
        switch options.menuDisplayMode {
        case let .Standard(widthMode, _, _):
            itemWidth = labelWidth(labelSize(label), widthMode)
        case .SegmentedControl:
            itemWidth = windowSize.width / CGFloat(options.menuItemCount)
        case let .Infinite(widthMode, _):
            itemWidth = labelWidth(labelSize(label), widthMode)
        }
        
        let itemHeight = floor(labelSize(label).height)
        return CGSizeMake(itemWidth + horizontalMargin * 2, itemHeight)
    }
}
