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
        $0.userInteractionEnabled = true
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIImageView(frame: .zero))
    public internal(set) var selected: Bool = false {
        didSet {
            if case .RoundRect = menuOptions.focusMode {
                backgroundColor = UIColor.clearColor()
            } else {
                backgroundColor = selected ? menuOptions.selectedBackgroundColor : menuOptions.backgroundColor
            }
            
            switch menuItemOptions.mode {
            case .Text(let title):
                titleLabel.textColor = selected ? title.selectedColor : title.color
                titleLabel.font = selected ? title.selectedFont : title.font
                
                // adjust label width if needed
                let labelSize = calculateLabelSize(titleLabel)
                widthConstraint.constant = labelSize.width
            case .MultilineText(let title, let description):
                titleLabel.textColor = selected ? title.selectedColor : title.color
                titleLabel.font = selected ? title.selectedFont : title.font

                descriptionLabel.textColor = selected ? description.selectedColor : description.color
                descriptionLabel.font = selected ? description.selectedFont : description.font

                // adjust label width if needed
                widthConstraint.constant = calculateLabelSize(titleLabel).width
                descriptionWidthConstraint.constant = calculateLabelSize(descriptionLabel).width
            case .Image(let image, let selectedImage):
                menuImageView.image = selected ? (selectedImage ?? image) : image
            }
        }
    }
    lazy public private(set) var dividerImageView: UIImageView? = { [weak self] in
        guard let image = self?.menuItemOptions.dividerImage else { return nil }
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var menuOptions: MenuViewCustomizable!
    private var menuItemOptions: MenuItemViewCustomizable!
    private var widthConstraint: NSLayoutConstraint!
    private var descriptionWidthConstraint: NSLayoutConstraint!
    private let labelSize: (UILabel) -> CGSize = { label in
        guard let text = label.text else { return .zero }
        return NSString(string: text).boundingRectWithSize(CGSizeMake(CGFloat.max, CGFloat.max), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: label.font], context: nil).size
    }
    private let labelWidth: (CGSize, MenuItemWidthMode) -> CGFloat = { size, widthMode in
        switch widthMode {
        case .Flexible: return ceil(size.width)
        case .Fixed(let width): return width
        }
    }
    private var horizontalMargin: CGFloat {
        switch menuOptions.mode {
        case .SegmentedControl: return 0.0
        default: return menuItemOptions.horizontalMargin
        }
    }
    
    // MARK: - Lifecycle
    
    internal init(menuOptions: MenuViewCustomizable, menuItemOptions: MenuItemViewCustomizable, addDiveder: Bool) {
        super.init(frame: .zero)
        
        self.menuOptions = menuOptions
        self.menuItemOptions = menuItemOptions
        
        switch menuItemOptions.mode {
        case .Text(let title):
            commonInit({
                self.setupLabel(title, label: self.titleLabel)
                self.layoutLabel()
            })
        case .MultilineText(let title, let description):
            commonInit({
                self.setupLabel(title, label: self.titleLabel)
                self.setupLabel(description, label: self.descriptionLabel)
                self.layoutMultiLineLabel()
            })
        case .Image(let image, _):
            commonInit({
                self.setupImageView(image)
                self.layoutImageView()
            })
        }
    }
    
    private func commonInit(setupContentView: () -> Void) {
        setupView()
        setupContentView()
        
        setupDivider()
        layoutDivider()
    }
    
    private func initLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 1
        label.textAlignment = .Center
        label.userInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Cleanup
    
    internal func cleanup() {
        switch menuItemOptions.mode {
        case .Text:
            titleLabel.removeFromSuperview()
        case .MultilineText:
            titleLabel.removeFromSuperview()
            descriptionLabel.removeFromSuperview()
        case .Image:
            menuImageView.removeFromSuperview()
        }
        
        dividerImageView?.removeFromSuperview()
    }
    
    // MARK: - Constraints manager
    
    internal func updateConstraints(size: CGSize) {
        // set width manually to support ratotaion
        guard case .SegmentedControl = menuOptions.mode else { return }
        
        switch menuItemOptions.mode {
        case .Text:
            let labelSize = calculateLabelSize(titleLabel, windowSize: size)
            widthConstraint.constant = labelSize.width
        case .MultilineText:
            widthConstraint.constant = calculateLabelSize(titleLabel, windowSize: size).width
            descriptionWidthConstraint.constant = calculateLabelSize(descriptionLabel, windowSize: size).width
        case .Image:
            widthConstraint.constant = size.width / CGFloat(menuOptions.itemsOptions.count)
        }
    }
    
    // MARK: - Constructor
    
    private func setupView() {
        if case .RoundRect = menuOptions.focusMode {
            backgroundColor = UIColor.clearColor()
        } else {
            backgroundColor = menuOptions.backgroundColor
        }
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupDescriptionLabel(title: MenuItemText, description: MenuItemText) {
        setupLabel(title, label: titleLabel)
        setupLabel(description, label: descriptionLabel)
    }
    
    private func setupTitleLabel(title: MenuItemText) {
        setupLabel(title, label: titleLabel)
    }
    
    private func setupLabel(text: MenuItemText, label: UILabel) {
        label.text = text.text
        label.textColor = text.color
        label.font = text.font
        addSubview(label)
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
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[titleLabel]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[titleLabel][descriptionLabel]", options: [], metrics: nil, views: viewsDictionary)

        let descriptionHorizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[descriptionLabel]|", options: [], metrics: nil, views: viewsDictionary)
        widthConstraint = NSLayoutConstraint(item: titleLabel, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .Width, multiplier: 1.0, constant: calculateLabelSize(titleLabel).width)
        descriptionWidthConstraint = NSLayoutConstraint(item: descriptionLabel, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .Width, multiplier: 1.0, constant: calculateLabelSize(descriptionLabel).width)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints + descriptionHorizontalConstraints + [widthConstraint, descriptionWidthConstraint])
    }

    private func layoutLabel() {
        let viewsDictionary = ["label": titleLabel]
        let labelSize = calculateLabelSize(titleLabel)

        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[label]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[label]|", options: [], metrics: nil, views: viewsDictionary)
        widthConstraint = NSLayoutConstraint(item: titleLabel, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: labelSize.width)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints + [widthConstraint])

    }
    
    private func layoutImageView() {
        guard let image = menuImageView.image else { return }
        
        let width: CGFloat
        switch menuOptions.mode {
        case .SegmentedControl:
            width = UIApplication.sharedApplication().keyWindow!.bounds.size.width / CGFloat(menuOptions.itemsOptions.count)
        default:
            width = image.size.width + horizontalMargin * 2
        }
        
        widthConstraint = NSLayoutConstraint(item: self, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: width)
        
        NSLayoutConstraint.activateConstraints([
            NSLayoutConstraint(item: menuImageView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: menuImageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: menuImageView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: image.size.width),
            NSLayoutConstraint(item: menuImageView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1.0, constant: image.size.height),
            widthConstraint
            ])
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
        switch menuOptions.mode {
        case let .Standard(widthMode, _, _):
            itemWidth = labelWidth(labelSize(label), widthMode)
        case .SegmentedControl:
            itemWidth = windowSize.width / CGFloat(menuOptions.itemsOptions.count)
        case let .Infinite(widthMode, _):
            itemWidth = labelWidth(labelSize(label), widthMode)
        }
        
        let itemHeight = floor(labelSize(label).height)
        return CGSizeMake(itemWidth + horizontalMargin * 2, itemHeight)
    }
}
