//
//  MenuItemView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

open class MenuItemView: UIView {
    lazy open var titleLabel: UILabel = self.initLabel()
    lazy open var descriptionLabel: UILabel = self.initLabel()
    lazy open var menuImageView: UIImageView = {
        $0.isUserInteractionEnabled = true
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIImageView(frame: .zero))
    open fileprivate(set) var customView: UIView? {
        didSet {
            guard let customView = customView else { return }
            
            addSubview(customView)
        }
    }
    open internal(set) var isSelected: Bool = false {
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
    lazy open fileprivate(set) var dividerImageView: UIImageView? = { [unowned self] in
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
        let titleLabelSize = calculateLabelSize(titleLabel, maxWidth: maxWindowSize)
        let descriptionLabelSize = calculateLabelSize(descriptionLabel, maxWidth: maxWindowSize)
        let verticalMargin = max(menuOptions.height - (titleLabelSize.height + descriptionLabelSize.height), 0) / 2
        let metrics = ["margin": verticalMargin]
        let viewsDictionary = ["titleLabel": titleLabel, "descriptionLabel": descriptionLabel]
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[titleLabel]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-margin-[titleLabel][descriptionLabel]-margin-|", options: [], metrics: metrics, views: viewsDictionary)

        let descriptionHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[descriptionLabel]|", options: [], metrics: nil, views: viewsDictionary)
        widthConstraint = NSLayoutConstraint(item: titleLabel, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .width, multiplier: 1.0, constant: titleLabelSize.width)
        descriptionWidthConstraint = NSLayoutConstraint(item: descriptionLabel, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .width, multiplier: 1.0, constant: descriptionLabelSize.width)
        
        NSLayoutConstraint.activate(horizontalConstraints + verticalConstraints + descriptionHorizontalConstraints + [widthConstraint, descriptionWidthConstraint])
    }

    fileprivate func layoutLabel() {
        let viewsDictionary = ["label": titleLabel]
        let labelSize = calculateLabelSize(titleLabel, maxWidth: maxWindowSize)

        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[label]|", options: [], metrics: nil, views: viewsDictionary)
        widthConstraint = NSLayoutConstraint(item: titleLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: labelSize.width)
        
        NSLayoutConstraint.activate(horizontalConstraints + verticalConstraints + [widthConstraint])

    }
    
    fileprivate func layoutImageView() {
        guard let image = menuImageView.image else { return }
        
        let width: CGFloat
        switch menuOptions.displayMode {
        case .segmentedControl:
            width = UIApplication.shared.keyWindow!.bounds.size.width / CGFloat(menuOptions.itemsOptions.count)
        default:
            width = image.size.width + horizontalMargin * 2
        }
        
        widthConstraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: width)
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: menuImageView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: menuImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: menuImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: image.size.width),
            NSLayoutConstraint(item: menuImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: image.size.height),
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
        
        let centerYConstraint = NSLayoutConstraint(item: dividerImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 1.0)
        let rightConstraint = NSLayoutConstraint(item: dividerImageView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1.0, constant: 0.0)
        NSLayoutConstraint.activate([centerYConstraint, rightConstraint])
    }
}

extension MenuItemView: ViewCleanable {
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

extension MenuItemView: LabelSizeCalculatable {
    func labelWidth(_ widthMode: MenuItemWidthMode, estimatedSize: CGSize) -> CGFloat {
        switch widthMode {
        case .flexible: return ceil(estimatedSize.width)
        case .fixed(let width): return width
        }
    }
    
    func estimatedLabelSize(_ label: UILabel) -> CGSize {
        guard let text = label.text else { return .zero }
        return NSString(string: text).boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: label.font], context: nil).size
    }
    
    func calculateLabelSize(_ label: UILabel, maxWidth: CGFloat) -> CGSize {
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
