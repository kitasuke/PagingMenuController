//
//  MenuView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import Foundation

class MenuView: UIScrollView {
    
    internal var menuItemViews = [MenuItemView]()
    private var options: PagingMenuOptions!
    private var contentView: UIView!
    private var currentPage: Int = 0
    
    // MARK: - Lifecycle
    
    internal init(menuItemTitles: [String], options: PagingMenuOptions) {
        super.init(frame: CGRectZero)
        
        self.options = options
        
        self.setupScrollView()
        self.constructContentView()
        self.layoutContentView()
        self.constructMenuItemViews(titles: menuItemTitles)
        self.layoutMenuItemViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.adjustmentContentInsetIfNeeded()
    }
    
    // MARK: - Public method
    
    internal func moveToMenu(#page: Int, animated: Bool) {
        let duration = animated ? options.animationDuration : 0
        let contentOffsetX = self.targetContentOffsetX(nextIndex: page)

        currentPage = page

        UIView.animateWithDuration(duration, animations: { [unowned self] () -> Void in
            self.contentOffset.x = contentOffsetX
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.changeMenuItemColor()
            })
        })
    }
    
    // MARK: - Private method
    
    private func setupScrollView() {
        self.backgroundColor = options.backgroundColor
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.bounces = self.bounces()
        self.scrollEnabled = true
        self.scrollsToTop = false
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
    }
    
    private func constructContentView() {
        contentView = UIView(frame: CGRectZero)
        contentView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.addSubview(contentView)
    }
    
    private func layoutContentView() {
        let viewsDictionary = ["contentView": contentView, "scrollView": self]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView(==scrollView)]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDictionary)
        
        self.addConstraints(horizontalConstraints)
        self.addConstraints(verticalConstraints)
    }
    
    private func constructMenuItemViews(#titles: [String]) {
        for title in titles {
            let menuView = MenuItemView(title: title, options: options)
            menuView.setTranslatesAutoresizingMaskIntoConstraints(false)
            contentView.addSubview(menuView)
            
            menuItemViews.append(menuView)
        }
    }
    
    private func layoutMenuItemViews() {
        for (index, menuItemView) in enumerate(menuItemViews) {
            let visualFormat: String;
            var viewsDicrionary = ["menuItemView": menuItemView]
            if index == 0 {
                visualFormat = "H:|[menuItemView]"
            } else if index == menuItemViews.count - 1 {
                visualFormat = "H:[menuItemView]|"
            } else {
                visualFormat = "H:[previousMenuItemView][menuItemView][nextMenuItemView]"
                viewsDicrionary["nextMenuItemView"] = menuItemViews[index + 1]
                viewsDicrionary["previousMenuItemView"] = menuItemViews[index - 1]
            }
            
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(visualFormat, options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDicrionary)
            
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[menuItemView]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDicrionary)
            
            contentView.addConstraints(horizontalConstraints)
            contentView.addConstraints(verticalConstraints)
        }
    }
    
    private func bounces() -> Bool {
        switch options.menuDisplayMode {
        case .FlexibleItemWidth(let centerItem, let scrollingMode):
            switch scrollingMode {
            case .ScrollEnabledAndBouces:
                return true
            default:
                return false
            }
        case .FixedItemWidth(let width, let centerItem, let scrollingMode):
            switch scrollingMode {
            case .ScrollEnabledAndBouces:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
    
    private func adjustmentContentInsetIfNeeded() {
        switch options.menuDisplayMode {
        case .FlexibleItemWidth(let centerItem, let scrollingMode):
            if !centerItem {
                return
            }
        case .FixedItemWidth(let width, let centerItem, let scrollingMode):
            if !centerItem {
                return
            }
        case .SegmentedControl:
            return
        }
        
        let firstMenuView = menuItemViews.first! as MenuItemView
        let lastMenuView = menuItemViews.last! as MenuItemView
        
        var inset = self.contentInset
        let halfWidth = CGRectGetWidth(self.frame) / 2
        inset.left = halfWidth - CGRectGetWidth(firstMenuView.frame) / 2
        inset.right = halfWidth - CGRectGetWidth(lastMenuView.frame) / 2
        self.contentInset = inset
    }
    
    private func targetContentOffsetX(#nextIndex: Int) -> CGFloat {
        switch options.menuDisplayMode {
        case .FlexibleItemWidth(let centerItem, let scrollingMode):
            if centerItem {
                return self.centerOfScreenWidth(nextIndex: nextIndex)
            }
            return self.contentOffsetXForCurrentPage(nextIndex: nextIndex)
        case .FixedItemWidth(let width, let centerItem, let scrollingMode):
            if centerItem {
                return self.centerOfScreenWidth(nextIndex: nextIndex)
            }
            return self.contentOffsetXForCurrentPage(nextIndex: nextIndex)
        case .SegmentedControl:
            return contentOffset.x
        }
    }
    
    private func centerOfScreenWidth(#nextIndex: Int) -> CGFloat {
        return CGRectGetMinX(self.menuItemViews[nextIndex].frame) + CGRectGetWidth(self.menuItemViews[nextIndex].frame) / 2 - CGRectGetWidth(self.frame) / 2
    }
    
    private func contentOffsetXForCurrentPage(#nextIndex: Int) -> CGFloat {
        let ratio = CGFloat(nextIndex) / CGFloat(menuItemViews.count - 1)
        let previousMenuItem = menuItemViews[currentPage]
        return (self.contentSize.width - CGRectGetWidth(self.frame)) * ratio
    }
    
    private func changeMenuItemColor() {
        for (index, menuItemView) in enumerate(menuItemViews) {
            menuItemView.changeColor(selected: index == currentPage)
        }
    }
}
