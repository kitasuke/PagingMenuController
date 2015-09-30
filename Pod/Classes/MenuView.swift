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
    private var sortedMenuItemViews = [MenuItemView]()
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
        
        UIView.animateWithDuration(duration, animations: { [unowned self] () -> Void in
            self.focusMenuItem()
            self.positionMenuItemViews()
        }) { [unowned self] (_) in
            // relayout menu item views dynamically
            if case .Infinite(_) = self.options.menuDisplayMode {
                self.relayoutMenuItemViews()
            }
            self.positionMenuItemViews()
        }
    }
    
    internal func updateMenuViewConstraints(size size: CGSize) {
        if case .SegmentedControl = options.menuDisplayMode {
            menuItemViews.forEach { $0.updateLabelConstraints(size: size) }
        }
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()

        animateUnderlineViewIfNeeded()
        animateRoundRectViewIfNeeded()
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
        for i in 0..<options.menuItemCount {
            let menuItemView = MenuItemView(title: titles[i], options: options)
            menuItemView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(menuItemView)
            
            menuItemViews.append(menuItemView)
        }
        
        sortMenuItemViews()
    }
    
    private func sortMenuItemViews() {
        if sortedMenuItemViews.count > 0 {
            sortedMenuItemViews.removeAll()
        }
        
        if case .Infinite(_) = options.menuDisplayMode {
            for i in 0..<options.menuItemCount {
                let index = rawIndex(i)
                sortedMenuItemViews.append(menuItemViews[index])
            }
        } else {
            sortedMenuItemViews = menuItemViews
        }
    }
    
    private func layoutMenuItemViews() {
        NSLayoutConstraint.deactivateConstraints(contentView.constraints)
        
        for (index, menuItemView) in sortedMenuItemViews.enumerate() {
            let visualFormat: String;
            var viewsDicrionary = ["menuItemView": menuItemView]
            if index == 0 {
                visualFormat = "H:|[menuItemView]"
            } else  {
                viewsDicrionary["previousMenuItemView"] = sortedMenuItemViews[index - 1]
                if index == sortedMenuItemViews.count - 1 {
                    visualFormat = "H:[previousMenuItemView][menuItemView]|"
                } else {
                    visualFormat = "H:[previousMenuItemView][menuItemView]"
                }
            }
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(visualFormat, options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDicrionary)
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[menuItemView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDicrionary)
            
            NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func constructUnderlineViewIfNeeded() {
        if case .Underline(let height, let color, let horizontalPadding, let verticalPadding) = options.menuItemMode {
            let width = menuItemViews[currentPage].bounds.width - horizontalPadding * 2
            underlineView = UIView(frame: CGRectMake(horizontalPadding, options.menuHeight - (height + verticalPadding), width, height))
            underlineView.backgroundColor = color
            contentView.addSubview(underlineView)
        }
    }
    
    private func constructRoundRectViewIfNeeded() {
        if case .RoundRect(let radius, _, let verticalPadding, let selectedColor) = options.menuItemMode {
            let height = options.menuHeight - verticalPadding * 2
            roundRectView = UIView(frame: CGRectMake(0, verticalPadding, 0, height))
            roundRectView.frame.origin.y = verticalPadding
            roundRectView.userInteractionEnabled = true
            roundRectView.layer.cornerRadius = radius
            roundRectView.backgroundColor = selectedColor
            contentView.addSubview(roundRectView)
        }
    }
    
    private func animateUnderlineViewIfNeeded() {
        if case .Underline(_, _, let horizontalPadding, _) = options.menuItemMode {
            if let underlineView = underlineView {
                let targetFrame = menuItemViews[currentPage].frame
                underlineView.frame.origin.x = targetFrame.minX + horizontalPadding
                underlineView.frame.size.width = targetFrame.width - horizontalPadding * 2
            }
        }
    }
    
    private func animateRoundRectViewIfNeeded() {
        if case .RoundRect(_, let horizontalPadding, _, _) = options.menuItemMode {
            if let roundRectView = roundRectView {
                let targetFrame = menuItemViews[currentPage].frame
                roundRectView.frame.origin.x = targetFrame.minX + horizontalPadding
                roundRectView.frame.size.width = targetFrame.width - horizontalPadding * 2
            }
        }
    }

    private func relayoutMenuItemViews() {
        sortMenuItemViews()
        layoutMenuItemViews()
    }

    private func positionMenuItemViews() {
        contentOffset.x = targetContentOffsetX()
        animateUnderlineViewIfNeeded()
        animateRoundRectViewIfNeeded()
    }
    
    private func bounces() -> Bool {
        if case .Standard(_, _, let scrollingMode) = options.menuDisplayMode {
            if case .ScrollEnabledAndBouces = scrollingMode {
                return true
            }
        }
        return false
    }
    
    private func scrollEnabled() -> Bool {
        if case .Standard(_, _, let scrollingMode) = options.menuDisplayMode {
            switch scrollingMode {
            case .ScrollEnabled, .ScrollEnabledAndBouces: return true
            case .PagingEnabled: return false
            }
        }
        return false
    }
    
    private func adjustmentContentInsetIfNeeded() {
        switch options.menuDisplayMode {
        case .Standard(_, let centerItem, _) where centerItem: break
        default: return
        }
        
        let firstMenuView = menuItemViews.first!
        let lastMenuView = menuItemViews.last!
        
        var inset = contentInset
        let halfWidth = frame.width / 2
        inset.left = halfWidth - firstMenuView.frame.width / 2
        inset.right = halfWidth - lastMenuView.frame.width / 2
        contentInset = inset
    }
    
    private func targetContentOffsetX() -> CGFloat {
        switch options.menuDisplayMode {
        case .Standard(_, let centerItem, _) where centerItem:
            return centerOfScreenWidth()
        case .SegmentedControl:
            return contentOffset.x
        case .Infinite(_):
            return centerOfScreenWidth()
        default:
            return contentOffsetXForCurrentPage()
        }
    }
    
    private func centerOfScreenWidth() -> CGFloat {
        return menuItemViews[currentPage].frame.midX - UIScreen.mainScreen().bounds.width / 2
    }
    
    private func contentOffsetXForCurrentPage() -> CGFloat {
        if menuItemViews.count == options.minumumSupportedViewCount {
            return 0.0
        }
        let ratio = CGFloat(currentPage) / CGFloat(menuItemViews.count - 1)
        return (contentSize.width - frame.width) * ratio
    }
    
    private func focusMenuItem() {
        // make selected item focused
        menuItemViews.forEach { $0.focusLabel(menuItemViews.indexOf($0) == currentPage) }

        // make selected item foreground
        sortedMenuItemViews.forEach { $0.layer.zPosition = menuItemViews.indexOf($0) == currentPage ? 0 : -1 }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func rawIndex(sortedIndex: Int) -> Int {
        let count = options.menuItemCount
        let startIndex = currentPage - count / 2
        return (startIndex + sortedIndex + count) % count
    }
}
