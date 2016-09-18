//
//  MenuView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

open class MenuView: UIScrollView {
    open fileprivate(set) var currentMenuItemView: MenuItemView!
    
    weak internal var viewDelegate: PagingMenuControllerDelegate?
    internal fileprivate(set) var menuItemViews = [MenuItemView]()
    
    fileprivate var menuOptions: MenuViewCustomizable!
    fileprivate var sortedMenuItemViews = [MenuItemView]()
    fileprivate let contentView: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIView(frame: .zero))
    lazy fileprivate var underlineView: UIView = {
        return UIView(frame: .zero)
    }()
    lazy fileprivate var roundRectView: UIView = {
        $0.isUserInteractionEnabled = true
        return $0
    }(UIView(frame: .zero))
    fileprivate var menuViewBounces: Bool {
        switch menuOptions.displayMode {
        case .standard(_, _, .scrollEnabledAndBouces),
             .infinite(_, .scrollEnabledAndBouces): return true
        default: return false
        }
    }
    fileprivate var menuViewScrollEnabled: Bool {
        switch menuOptions.displayMode {
        case .standard(_, _, .scrollEnabledAndBouces),
             .standard(_, _, .scrollEnabled),
             .infinite(_, .scrollEnabledAndBouces),
             .infinite(_, .scrollEnabled): return true
        default: return false
        }
    }
    fileprivate var contentOffsetX: CGFloat {
        switch menuOptions.displayMode {
        case .standard(_, let centerItem, _) where centerItem:
            return centerOfScreenWidth
        case .segmentedControl:
            return contentOffset.x
        case .infinite:
            return centerOfScreenWidth
        default:
            return contentOffsetXForCurrentPage
        }
    }
    fileprivate var centerOfScreenWidth: CGFloat {
        return menuItemViews[currentPage].frame.midX - UIApplication.shared.keyWindow!.bounds.width / 2
    }
    fileprivate var contentOffsetXForCurrentPage: CGFloat {
        guard menuItemCount > MinimumSupportedViewCount else { return 0.0 }
        let ratio = CGFloat(currentPage) / CGFloat(menuItemCount - 1)
        return (contentSize.width - frame.width) * ratio
    }
    fileprivate var currentIndex: Int = 0
    
    // MARK: - Lifecycle
    internal init(menuOptions: MenuViewCustomizable) {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: menuOptions.height))
        
        self.menuOptions = menuOptions
        
        commonInit({ self.constructMenuItemViews(menuOptions) })
    }
    
    fileprivate func commonInit(_ constructor: () -> Void) {
        setupScrollView()
        layoutScrollView()
        setupContentView()
        layoutContentView()
        setupRoundRectViewIfNeeded()
        constructor()
        layoutMenuItemViews()
        setupUnderlineViewIfNeeded()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        adjustmentContentInsetIfNeeded()
    }
    
    // MARK: - Internal method
    
    internal func move(toPage page: Int, animated: Bool = true) {
        // hide menu view when constructing itself
        if !animated {
            alpha = 0
        }
        
        let menuItemView = menuItemViews[page]
        let previousPage = currentPage
        let previousMenuItemView = currentMenuItemView
        
        if let previousMenuItemView = previousMenuItemView,
            page != previousPage {
            viewDelegate?.willMove(toMenuItem: menuItemView, fromMenuItem: previousMenuItemView)
        }
        
        update(currentPage: page)
        
        let duration = animated ? menuOptions.animationDuration : 0
        UIView.animate(withDuration: duration, animations: { [unowned self] () -> Void in
            self.focusMenuItem()
            if self.menuOptions.selectedItemCenter {
                self.positionMenuItemViews()
            }
        }) { [weak self] (_) in
            guard let _ = self else { return }
            
            // relayout menu item views dynamically
            if case .infinite = self!.menuOptions.displayMode {
                self!.relayoutMenuItemViews()
            }
            if self!.menuOptions.selectedItemCenter {
                self!.positionMenuItemViews()
            }
            self!.setNeedsLayout()
            self!.layoutIfNeeded()
            
            // show menu view when constructing is done
            if !animated {
                self!.alpha = 1
            }
            
            if let previousMenuItemView = previousMenuItemView,
                page != previousPage {
                self!.viewDelegate?.didMove(toMenuItem: self!.currentMenuItemView, fromMenuItem: previousMenuItemView)
            }
        }
    }
    
    internal func updateMenuViewConstraints(_ size: CGSize) {
        if case .segmentedControl = menuOptions.displayMode {
            menuItemViews.forEach { $0.updateConstraints(size) }
        }
        setNeedsLayout()
        layoutIfNeeded()

        animateUnderlineViewIfNeeded()
        animateRoundRectViewIfNeeded()
    }
    
    // MARK: - Private method
    
    fileprivate func setupScrollView() {
        backgroundColor = menuOptions.backgroundColor
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bounces = menuViewBounces
        isScrollEnabled = menuViewScrollEnabled
        decelerationRate = menuOptions.deceleratingRate
        scrollsToTop = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    fileprivate func layoutScrollView() {
        let viewsDictionary = ["menuView": self]
        let metrics = ["height": menuOptions.height]
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:[menuView(height)]", options: [], metrics: metrics, views: viewsDictionary)
        )
    }
    
    fileprivate func setupContentView() {
        addSubview(contentView)
    }
    
    fileprivate func layoutContentView() {
        let viewsDictionary = ["contentView": contentView, "scrollView": self]
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[contentView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[contentView(==scrollView)]|", options: [], metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activate(horizontalConstraints + verticalConstraints)
    }

    fileprivate func constructMenuItemViews(_ menuOptions: MenuViewCustomizable) {
        constructMenuItemViews({
            return MenuItemView(menuOptions: menuOptions, menuItemOptions: menuOptions.itemsOptions[$0], addDiveder: $1)
        })
    }
    
    fileprivate func constructMenuItemViews(_ constructor: (Int, Bool) -> MenuItemView) {
        for index in 0..<menuItemCount {
            let addDivider = index < menuItemCount - 1
            let menuItemView = constructor(index % menuOptions.itemsOptions.count, addDivider)
            menuItemView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(menuItemView)
            
            menuItemViews.append(menuItemView)
        }
        
        sortMenuItemViews()
    }
    
    fileprivate func sortMenuItemViews() {
        if !sortedMenuItemViews.isEmpty {
            sortedMenuItemViews.removeAll()
        }
        
        if case .infinite = menuOptions.displayMode {
            for i in 0..<menuItemCount {
                let page = rawPage(i)
                sortedMenuItemViews.append(menuItemViews[page])
            }
        } else {
            sortedMenuItemViews = menuItemViews
        }
    }
    
    fileprivate func layoutMenuItemViews() {
        NSLayoutConstraint.deactivate(contentView.constraints)
        
        for (index, menuItemView) in sortedMenuItemViews.enumerated() {
            let visualFormat: String;
            var viewsDicrionary = ["menuItemView": menuItemView]
            if index == 0 {
                visualFormat = "H:|[menuItemView]"
            } else  {
                viewsDicrionary["previousMenuItemView"] = sortedMenuItemViews[index - 1]
                if index == menuItemCount - 1 {
                    visualFormat = "H:[previousMenuItemView][menuItemView]|"
                } else {
                    visualFormat = "H:[previousMenuItemView][menuItemView]"
                }
            }
            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: visualFormat, options: [], metrics: nil, views: viewsDicrionary)
            let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[menuItemView]|", options: [], metrics: nil, views: viewsDicrionary)
            
            NSLayoutConstraint.activate(horizontalConstraints + verticalConstraints)
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    fileprivate func setupUnderlineViewIfNeeded() {
        guard case let .underline(height, color, horizontalPadding, verticalPadding) = menuOptions.focusMode else { return }
        
        let width = menuItemViews[currentPage].bounds.width - horizontalPadding * 2
        underlineView.frame = CGRect(x: horizontalPadding, y: menuOptions.height - (height + verticalPadding), width: width, height: height)
        underlineView.backgroundColor = color
        contentView.addSubview(underlineView)
    }
    
    fileprivate func setupRoundRectViewIfNeeded() {
        guard case let .roundRect(radius, _, verticalPadding, selectedColor) = menuOptions.focusMode else { return }
        
        let height = menuOptions.height - verticalPadding * 2
        roundRectView.frame = CGRect(x: 0, y: verticalPadding, width: 0, height: height)
        roundRectView.layer.cornerRadius = radius
        roundRectView.backgroundColor = selectedColor
        contentView.addSubview(roundRectView)
    }
    
    fileprivate func animateUnderlineViewIfNeeded() {
        guard case .underline(_, _, let horizontalPadding, _) = menuOptions.focusMode else { return }
        
        let targetFrame = menuItemViews[currentPage].frame
        underlineView.frame.origin.x = targetFrame.minX + horizontalPadding
        underlineView.frame.size.width = targetFrame.width - horizontalPadding * 2
    }
    
    fileprivate func animateRoundRectViewIfNeeded() {
        guard case .roundRect(_, let horizontalPadding, _, _) = menuOptions.focusMode else { return }
        
        let targetFrame = menuItemViews[currentPage].frame
        roundRectView.frame.origin.x = targetFrame.minX + horizontalPadding
        roundRectView.frame.size.width = targetFrame.width - horizontalPadding * 2
    }

    fileprivate func relayoutMenuItemViews() {
        sortMenuItemViews()
        layoutMenuItemViews()
    }

    fileprivate func positionMenuItemViews() {
        contentOffset.x = contentOffsetX
        animateUnderlineViewIfNeeded()
        animateRoundRectViewIfNeeded()
    }
    
    fileprivate func adjustmentContentInsetIfNeeded() {
        switch menuOptions.displayMode {
        case .standard(_, let centerItem, _) where centerItem: break
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
    
    fileprivate func focusMenuItem() {
        let isSelected: (MenuItemView) -> Bool = { self.menuItemViews.index(of: $0) == self.currentPage }
        
        // make selected item focused
        menuItemViews.forEach {
            $0.isSelected = isSelected($0)
            if $0.isSelected {
                self.currentMenuItemView = $0
            }
        }

        // make selected item foreground
        sortedMenuItemViews.forEach { $0.layer.zPosition = isSelected($0) ? 0 : -1 }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
}

extension MenuView: Pagable {
    var currentPage: Int {
        return currentIndex
    }
    var previousPage: Int {
        return currentPage - 1 < 0 ? menuItemCount - 1 : currentPage - 1
    }
    var nextPage: Int {
        return currentPage + 1 > menuItemCount - 1 ? 0 : currentPage + 1
    }
    func update(currentPage page: Int) {
        currentIndex = page
    }
}

extension MenuView: ViewCleanable {
    func cleanup() {
        contentView.removeFromSuperview()
        switch menuOptions.focusMode {
        case .underline: underlineView.removeFromSuperview()
        case .roundRect: roundRectView.removeFromSuperview()
        case .none: break
        }
        
        if !menuItemViews.isEmpty {
            menuItemViews.forEach {
                $0.cleanup()
                $0.removeFromSuperview()
            }
        }
    }
}

extension MenuView: MenuItemMultipliable {
    var menuItemCount: Int {
        switch menuOptions.displayMode {
        case .infinite: return menuOptions.itemsOptions.count * menuOptions.dummyItemViewsSet
        default: return menuOptions.itemsOptions.count
        }
    }
    func rawPage(_ page: Int) -> Int {
        let startIndex = currentPage - menuItemCount / 2
        return (startIndex + page + menuItemCount) % menuItemCount
    }
}
