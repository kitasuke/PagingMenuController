//
//  MenuItemView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

open class MenuItemView: UIView {
    lazy public var titleLabel: UILabel = self.initLabel()
    lazy public var descriptionLabel: UILabel = self.initLabel()
    lazy public var menuImageView: UIImageView = {
        $0.isUserInteractionEnabled = true
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIImageView(frame: .zero))
    public fileprivate(set) var customView: UIView? {
        didSet {
            guard let customView = customView else { return }
            
            addSubview(customView)
        }
    }
    public internal(set) var isSelected: Bool = false {
        didSet {
            if case .roundRect = menuOptions.focusMode {
                backgroundColor = UIColor.clear
            } else {
                backgroundColor = isSelected ? menuOptions.selectedBackgroundColor : menuOptions.backgroundColor
            }
            
            switch menuItemOptions.displayMode {
            case .text(let title):
                updateLabel(titleLabel, text: title)
                
                // adjust label width if needed
                let labelSize = calculateLabelSize(titleLabel, maxWidth: maxWindowSize)
                widthConstraint.constant = labelSize.width
            case let .multilineText(title, description):
                updateLabel(titleLabel, text: title)
                updateLabel(descriptionLabel, text: description)
                
                // adjust label width if needed
                widthConstraint.constant = calculateLabelSize(titleLabel, maxWidth: maxWindowSize).width
                descriptionWidthConstraint.constant = calculateLabelSize(descriptionLabel, maxWidth: maxWindowSize).width
            case let .image(image, selectedImage):
                menuImageView.image = isSelected ? (selectedImage ?? image) : image
            case .custom: break
            }
        }
    }
    lazy public fileprivate(set) var dividerImageView: UIImageView? = { [unowned self] in
        guard let image = self.menuOptions.dividerImage else { return nil }
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    fileprivate var menuOptions: MenuViewCustomizable!
    fileprivate var menuItemOptions: MenuItemViewCustomizable!
    fileprivate var widthConstraint: NSLayoutConstraint!
    fileprivate var descriptionWidthConstraint: NSLayoutConstraint!
    fileprivate var horizontalMargin: CGFloat {
        switch menuOptions.displayMode {
        case .segmentedControl: return 0.0
        default: return menuItemOptions.horizontalMargin
        }
    }
    
    // MARK: - Lifecycle
    
    internal init(menuOptions: MenuViewCustomizable, menuItemOptions: MenuItemViewCustomizable, addDiveder: Bool) {
        super.init(frame: .zero)
        
        self.menuOptions = menuOptions
        self.menuItemOptions = menuItemOptions
        
        switch menuItemOptions.displayMode {
        case .text(let title):
            commonInit({
                self.setupTitleLabel(title)
                self.layoutLabel()
            })
        case let .multilineText(title, description):
            commonInit({
                self.setupMultilineLabel(title, description: description)
                self.layoutMultiLineLabel()
            })
        case .image(let image, _):
            commonInit({
                self.setupImageView(image)
                self.layoutImageView()
            })
        case .custom(let view):
            commonInit({
                self.setupCustomView(view)
                self.layoutCustomView()
            })
        }
    }
    
    fileprivate func commonInit(_ setupContentView: () -> Void) {
        setupView()
        setupContentView()
        
        setupDivider()
        layoutDivider()
    }
    
    fileprivate func initLabel() -> UILabel {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 1
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Constraints manager
    
    internal func updateConstraints(_ size: CGSize) {
        // set width manually to support ratotaion
        guard case .segmentedControl = menuOptions.displayMode else { return }
        
        switch menuItemOptions.displayMode {
        case .text:
            let labelSize = calculateLabelSize(titleLabel, maxWidth: size.width)
            widthConstraint.constant = labelSize.width
        case .multilineText:
            widthConstraint.constant = calculateLabelSize(titleLabel, maxWidth: size.width).width
            descriptionWidthConstraint.constant = calculateLabelSize(descriptionLabel, maxWidth: size.width).width
        case .image, .custom:
            widthConstraint.constant = size.width / CGFloat(menuOptions.itemsOptions.count)
        }
    }
    
    // MARK: - Constructor
    
    fileprivate func setupView() {
        if case .roundRect = menuOptions.focusMode {
            backgroundColor = UIColor.clear
        } else {
            backgroundColor = menuOptions.backgroundColor
        }
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    fileprivate func setupTitleLabel(_ text: MenuItemText) {
        setupLabel(titleLabel, text: text)
    }
    
    fileprivate func setupMultilineLabel(_ text: MenuItemText, description: MenuItemText) {
        setupLabel(titleLabel, text: text)
        setupLabel(descriptionLabel, text: description)
    }
    
    fileprivate func setupLabel(_ label: UILabel, text: MenuItemText) {
        label.text = text.text
        updateLabel(label, text: text)
        addSubview(label)
    }
    
    fileprivate func updateLabel(_ label: UILabel, text: MenuItemText) {
        label.textColor = isSelected ? text.selectedColor : text.color
        label.font = isSelected ? text.selectedFont : text.font
    }
    
    fileprivate func setupImageView(_ image: UIImage) {
        menuImageView.image = image
        addSubview(menuImageView)
    }
    
    fileprivate func setupCustomView(_ view: UIView) {
        customView = view
    }
    
    fileprivate func setupDivider() {
        guard let dividerImageView = dividerImageView else { return }
        
        addSubview(dividerImageView)
    }
    
    fileprivate func layoutMultiLineLabel() {
        // H:|[titleLabel(==labelSize.width)]|
        // H:|[descriptionLabel(==labelSize.width)]|
        // V:|-margin-[titleLabel][descriptionLabel]-margin|
        let titleLabelSize = calculateLabelSize(titleLabel, maxWidth: maxWindowSize)
        let descriptionLabelSize = calculateLabelSize(descriptionLabel, maxWidth: maxWindowSize)
        let verticalMargin = max(menuOptions.height - (titleLabelSize.height + descriptionLabelSize.height), 0) / 2
        widthConstraint = titleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: titleLabelSize.width)
        descriptionWidthConstraint = descriptionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: descriptionLabelSize.width)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            widthConstraint,
            descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            descriptionWidthConstraint,
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: verticalMargin),
            titleLabel.bottomAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: 0),
            descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: verticalMargin),
            titleLabel.heightAnchor.constraint(equalToConstant: titleLabelSize.height),
            ])
    }

    fileprivate func layoutLabel() {
        // H:|[titleLabel](==labelSize.width)|
        // V:|[titleLabel]|
        let titleLabelSize = calculateLabelSize(titleLabel, maxWidth: maxWindowSize)
        widthConstraint = titleLabel.widthAnchor.constraint(equalToConstant: titleLabelSize.width)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            widthConstraint,
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
    }
    
    fileprivate func layoutImageView() {
        guard let image = menuImageView.image else { return }
        
        let width: CGFloat
        switch menuOptions.displayMode {
        case .segmentedControl:
            if let windowWidth = UIApplication.shared.keyWindow?.bounds.size.width {
                width = windowWidth / CGFloat(menuOptions.itemsOptions.count)
            } else {
                width = UIScreen.main.bounds.width / CGFloat(menuOptions.itemsOptions.count)
            }
        default:
            width = image.size.width + horizontalMargin * 2
        }
        
        widthConstraint = widthAnchor.constraint(equalToConstant: width)
        
        NSLayoutConstraint.activate([
            menuImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            menuImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            menuImageView.widthAnchor.constraint(equalToConstant: image.size.width),
            menuImageView.heightAnchor.constraint(equalToConstant: image.size.height),
            widthConstraint
            ])
    }
    
    fileprivate func layoutCustomView() {
        guard let customView = customView else { return }
        
        widthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: customView.frame.width)
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: customView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: customView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: customView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: customView.frame.width),
            NSLayoutConstraint(item: customView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: customView.frame.height),
            widthConstraint
            ])
    }
    
    fileprivate func layoutDivider() {
        guard let dividerImageView = dividerImageView else { return }
        
        NSLayoutConstraint.activate([
            dividerImageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 1.0),
            dividerImageView.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
    }
}

extension MenuItemView {
    func cleanup() {
        switch menuItemOptions.displayMode {
        case .text:
            titleLabel.removeFromSuperview()
        case .multilineText:
            titleLabel.removeFromSuperview()
            descriptionLabel.removeFromSuperview()
        case .image:
            menuImageView.removeFromSuperview()
        case .custom:
            customView?.removeFromSuperview()
        }
        
        dividerImageView?.removeFromSuperview()
    }
}

// MARK: Lable Size

extension MenuItemView {
    fileprivate func labelWidth(_ widthMode: MenuItemWidthMode, estimatedSize: CGSize) -> CGFloat {
        switch widthMode {
        case .flexible: return ceil(estimatedSize.width)
        case .fixed(let width): return width
        }
    }
    
    fileprivate func estimatedLabelSize(_ label: UILabel) -> CGSize {
        guard let text = label.text else { return .zero }
        return NSString(string: text).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: label.font], context: nil).size
    }
    
    fileprivate func calculateLabelSize(_ label: UILabel, maxWidth: CGFloat) -> CGSize {
        guard let _ = label.text else { return .zero }
        
        let itemWidth: CGFloat
        switch menuOptions.displayMode {
        case .standard(let widthMode, _, _):
            itemWidth = labelWidth(widthMode, estimatedSize: estimatedLabelSize(label))
        case .segmentedControl:
            itemWidth = maxWidth / CGFloat(menuOptions.itemsOptions.count)
        case .infinite(let widthMode, _):
            itemWidth = labelWidth(widthMode, estimatedSize: estimatedLabelSize(label))
        }
        
        let itemHeight = floor(estimatedLabelSize(label).height)
        return CGSize(width: itemWidth + horizontalMargin * 2, height: itemHeight)
    }
    
    fileprivate var maxWindowSize: CGFloat {
        return UIApplication.shared.keyWindow?.bounds.width ?? UIScreen.main.bounds.width
    }
}
