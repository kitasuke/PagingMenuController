//
//  MenuView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

class MenuView: UIScrollView {
    
    internal var menuItemViews = [MenuItemView]()
    private var options: PagingMenuOptions!
    private var contentView: UIView!
    private var underlineView: UIView!
    private var roundRectView: UIView!
    private var currentPage: Int = 0
    
    // MARK: - Lifecycle
    
    internal init(menuItemTitles: [String], options: PagingMenuOptions) {
        super.init(frame: CGRectZero)
        
        self.options = options
        
        setupScrollView()
        constructContentView()
        layoutContentView()
        constructRoundRectViewIfNeeded()
        constructMenuItemViews(titles: menuItemTitles)
        layoutMenuItemViews()
        constructUnderlineViewIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        adjustmentContentInsetIfNeeded()
    }
    
    // MARK: - Public method
    
    internal func moveToMenu(page page: Int, animated: Bool) {
        let duration = animated ? options.animationDuration : 0
        
        currentPage = page

        focusMenuItem()
        UIView.animateWithDuration(duration, animations: { [unowned self] () -> Void in
            self.contentOffset.x = self.targetContentOffsetX()

            self.animateUnderlineViewIfNeeded()
            self.animateRoundRectViewIfNeeded()
        })
    }
    
    internal func updateMenuItemConstraintsIfNeeded(size size: CGSize) {
        if case .SegmentedControl = options.menuDisplayMode {
            for menuItemView in menuItemViews {
                menuItemView.updateLabelConstraints(size: size)
            }
        }
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()

        self.animateUnderlineViewIfNeeded()
        self.animateRoundRectViewIfNeeded()
    }
    
    // MARK: - Private method
    
    private func setupScrollView() {
        if case .RoundRect(_, _, _, _) = options.menuItemMode {
            backgroundColor = UIColor.clearColor()
        } else {
            backgroundColor = options.backgroundColor
        }
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bounces = bounces()
        scrollEnabled = scrollEnabled()
        scrollsToTop = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func constructContentView() {
        contentView = UIView(frame: CGRectZero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
    }
    
    private func layoutContentView() {
        let viewsDictionary = ["contentView": contentView, "scrollView": self]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView(==scrollView)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
    
    private func constructMenuItemViews(titles titles: [String]) {
        for title in titles {
            let menuItemView = MenuItemView(title: title, options: options)
            menuItemView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(menuItemView)
            
            menuItemViews.append(menuItemView)
        }
    }
    
    private func layoutMenuItemViews() {
        for (index, menuItemView) in menuItemViews.enumerate() {
            let visualFormat: String;
            var viewsDicrionary = ["menuItemView": menuItemView]
            if index == 0 {
                visualFormat = "H:|[menuItemView]"
            } else {
                viewsDicrionary["previousMenuItemView"] = menuItemViews[index - 1]
                if index == menuItemViews.count - 1 {
                    visualFormat = "H:[previousMenuItemView][menuItemView]|"
                } else {
                    visualFormat = "H:[previousMenuItemView][menuItemView]"
                }
            }
            
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(visualFormat, options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDicrionary)
            
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[menuItemView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDicrionary)
            
            NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        }
    }
    
    private func constructUnderlineViewIfNeeded() {
        if case .Underline(let height, let color, let horizontalPadding, let verticalPadding) = options.menuItemMode {
            let width = menuItemViews.first!.bounds.width - horizontalPadding * 2
            underlineView = UIView(frame: CGRectMake(horizontalPadding, options.menuHeight - (height + verticalPadding), width, height))
            underlineView.backgroundColor = color
            contentView.addSubview(underlineView)
        }
    }
    
    private func constructRoundRectViewIfNeeded() {
        switch options.menuItemMode {
        case .RoundRect(let radius, _, let verticalPadding, let selectedColor):
            let height = options.menuHeight - verticalPadding * 2
            roundRectView = UIView(frame: CGRectMake(0, verticalPadding, 0, height))
            roundRectView.frame.origin.y = verticalPadding
            roundRectView.userInteractionEnabled = true
            roundRectView.layer.cornerRadius = radius
            roundRectView.backgroundColor = selectedColor
            contentView.addSubview(roundRectView)
        default: break
        }
    }
    
    private func animateUnderlineViewIfNeeded() {
        switch self.options.menuItemMode {
        case .Underline(_, _, let horizontalPadding, _):
            if let underlineView = self.underlineView {
                let targetFrame = self.menuItemViews[self.currentPage].frame
                underlineView.frame.origin.x = targetFrame.origin.x + horizontalPadding
                underlineView.frame.size.width = targetFrame.width - horizontalPadding * 2
            }
        default: break
        }
    }
    
    private func animateRoundRectViewIfNeeded() {
        switch self.options.menuItemMode {
        case .RoundRect(_, let horizontalPadding, _, _):
            if let roundRectView = self.roundRectView {
                let targetFrame = self.menuItemViews[self.currentPage].frame
                roundRectView.frame.origin.x = targetFrame.origin.x + horizontalPadding
                roundRectView.frame.size.width = targetFrame.width - horizontalPadding * 2
            }
        default: break
        }
    }
    
    private func bounces() -> Bool {
        switch options.menuDisplayMode {
        case .Normal(_, _, let scrollingMode):
            if case .ScrollEnabledAndBouces = scrollingMode {
                return true
            }
        case .SegmentedControl:
            return false
        case .Infinite(_):
            return false
        }
        return false
    }
    
    private func scrollEnabled() -> Bool {
        switch options.menuDisplayMode {
        case .Normal(_, _, let scrollingMode):
            if case .PagingEnabled = scrollingMode {
                return false
            }
        default:
            return false
        }
        return true
    }
    
    private func adjustmentContentInsetIfNeeded() {
        switch options.menuDisplayMode {
        case .Normal(_, let centerItem, _) where centerItem != true: return
        case .SegmentedControl: return
        case .Infinite(_): return
        default: break
        }
        
        let firstMenuView = menuItemViews.first! as MenuItemView
        let lastMenuView = menuItemViews.last! as MenuItemView
        
        var inset = contentInset
        let halfWidth = frame.width / 2
        inset.left = halfWidth - firstMenuView.frame.width / 2
        inset.right = halfWidth - lastMenuView.frame.width / 2
        contentInset = inset
    }
    
    private func targetContentOffsetX() -> CGFloat {
        switch options.menuDisplayMode {
        case .Normal(_, let centerItem, _) where centerItem:
            return centerOfScreenWidth()
        case .SegmentedControl:
            return contentOffset.x
        default:
            return contentOffsetXForCurrentPage()
        }
    }
    
    private func centerOfScreenWidth() -> CGFloat {
        return menuItemViews[currentPage].frame.origin.x + menuItemViews[currentPage].frame.width / 2 - frame.width / 2
    }
    
    private func contentOffsetXForCurrentPage() -> CGFloat {
        if menuItemViews.count == options.minumumSupportedViewCount {
            return 0.0
        }
        let ratio = CGFloat(currentPage) / CGFloat(menuItemViews.count - 1)
        return (contentSize.width - frame.width) * ratio
    }
    
    private func focusMenuItem() {
        for (index, menuItemView) in menuItemViews.enumerate() {
            menuItemView.focusLabel(index == currentPage)
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
}
