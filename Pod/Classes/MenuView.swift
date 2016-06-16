//
//  MenuView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

public class MenuView: UIScrollView {
    public private(set) var currentMenuItemView: MenuItemView!
    
    weak internal var viewDelegate: PagingMenuControllerDelegate?
    internal private(set) var menuItemViews = [MenuItemView]()
    
    private var menuOptions: MenuViewCustomizable!
    private var sortedMenuItemViews = [MenuItemView]()
    private let contentView: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIView(frame: .zero))
    lazy private var underlineView: UIView = {
        return UIView(frame: .zero)
    }()
    lazy private var roundRectView: UIView = {
        $0.userInteractionEnabled = true
        return $0
    }(UIView(frame: .zero))
    private var menuViewBounces: Bool {
        switch menuOptions.displayMode {
        case .Standard(_, _, .ScrollEnabledAndBouces),
             .Infinite(_, .ScrollEnabledAndBouces): return true
        default: return false
        }
    }
    private var menuViewScrollEnabled: Bool {
        switch menuOptions.displayMode {
        case .Standard(_, _, .ScrollEnabledAndBouces),
             .Standard(_, _, .ScrollEnabled),
             .Infinite(_, .ScrollEnabledAndBouces),
             .Infinite(_, .ScrollEnabled): return true
        default: return false
        }
    }
    private var contentOffsetX: CGFloat {
        switch menuOptions.displayMode {
        case let .Standard(_, centerItem, _) where centerItem:
            return centerOfScreenWidth
        case .SegmentedControl:
            return contentOffset.x
        case .Infinite:
            return centerOfScreenWidth
        default:
            return contentOffsetXForCurrentPage
        }
    }
    private var centerOfScreenWidth: CGFloat {
        return menuItemViews[currentPage].frame.midX - UIApplication.sharedApplication().keyWindow!.bounds.width / 2
    }
    private var contentOffsetXForCurrentPage: CGFloat {
        guard menuItemCount > MinimumSupportedViewCount else { return 0.0 }
        let ratio = CGFloat(currentPage) / CGFloat(menuItemCount - 1)
        return (contentSize.width - frame.width) * ratio
    }
    private var currentIndex: Int = 0
    
    // MARK: - Lifecycle
    internal init(menuOptions: MenuViewCustomizable) {
        super.init(frame: CGRectMake(0, 0, 0, menuOptions.height))
        
        self.menuOptions = menuOptions
        
        commonInit({ self.constructMenuItemViews(menuOptions) })
    }
    
    private func commonInit(constructor: () -> Void) {
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
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        adjustmentContentInsetIfNeeded()
    }
    
    // MARK: - Internal method
    
    internal func moveToMenu(page: Int, animated: Bool = true) {
        // hide menu view when constructing itself
        if !animated {
            alpha = 0
        }
        
        let menuItemView = menuItemViews[page]
        let previousPage = currentPage
        let previousMenuItemView = currentMenuItemView
        
        if let previousMenuItemView = previousMenuItemView where page != previousPage {
            viewDelegate?.willMoveToMenuItemView?(menuItemView, previousMenuItemView: previousMenuItemView)
        }
        
        updateCurrentPage(page)
        
        let duration = animated ? menuOptions.animationDuration : 0
        UIView.animateWithDuration(duration, animations: { [unowned self] () -> Void in
            self.focusMenuItem()
            if self.menuOptions.selectedItemCenter {
                self.positionMenuItemViews()
            }
        }) { [weak self] (_) in
            guard let _ = self else { return }
            
            // relayout menu item views dynamically
            if case .Infinite = self!.menuOptions.displayMode {
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
            
            if let previousMenuItemView = previousMenuItemView where page != previousPage {
                self!.viewDelegate?.didMoveToMenuItemView?(self!.currentMenuItemView, previousMenuItemView: previousMenuItemView)
            }
        }
    }
    
    internal func updateMenuViewConstraints(size: CGSize) {
        if case .SegmentedControl = menuOptions.displayMode {
            menuItemViews.forEach { $0.updateConstraints(size) }
        }
        setNeedsLayout()
        layoutIfNeeded()

        animateUnderlineViewIfNeeded()
        animateRoundRectViewIfNeeded()
    }
    
    // MARK: - Private method
    
    private func setupScrollView() {
        backgroundColor = menuOptions.backgroundColor
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bounces = menuViewBounces
        scrollEnabled = menuViewScrollEnabled
        decelerationRate = menuOptions.deceleratingRate
        scrollsToTop = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func layoutScrollView() {
        let viewsDictionary = ["menuView": self]
        let metrics = ["height": menuOptions.height]
        NSLayoutConstraint.activateConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView(height)]", options: [], metrics: metrics, views: viewsDictionary)
        )
    }
    
    private func setupContentView() {
        addSubview(contentView)
    }
    
    private func layoutContentView() {
        let viewsDictionary = ["contentView": contentView, "scrollView": self]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView(==scrollView)]|", options: [], metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }

    private func constructMenuItemViews(menuOptions: MenuViewCustomizable) {
        constructMenuItemViews({
            return MenuItemView(menuOptions: menuOptions, menuItemOptions: menuOptions.itemsOptions[$0], addDiveder: $1)
        })
    }
    
    private func constructMenuItemViews(constructor: (Int, Bool) -> MenuItemView) {
        for index in 0..<menuItemCount {
            let addDivider = index < menuItemCount - 1
            let menuItemView = constructor(index % menuOptions.itemsOptions.count, addDivider)
            menuItemView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(menuItemView)
            
            menuItemViews.append(menuItemView)
        }
        
        sortMenuItemViews()
    }
    
    private func sortMenuItemViews() {
        if !sortedMenuItemViews.isEmpty {
            sortedMenuItemViews.removeAll()
        }
        
        if case .Infinite = menuOptions.displayMode {
            for i in 0..<menuItemCount {
                let page = rawPage(i)
                sortedMenuItemViews.append(menuItemViews[page])
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
                if index == menuItemCount - 1 {
                    visualFormat = "H:[previousMenuItemView][menuItemView]|"
                } else {
                    visualFormat = "H:[previousMenuItemView][menuItemView]"
                }
            }
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(visualFormat, options: [], metrics: nil, views: viewsDicrionary)
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[menuItemView]|", options: [], metrics: nil, views: viewsDicrionary)
            
            NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        }
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func setupUnderlineViewIfNeeded() {
        guard case let .Underline(height, color, horizontalPadding, verticalPadding) = menuOptions.focusMode else { return }
        
        let width = menuItemViews[currentPage].bounds.width - horizontalPadding * 2
        underlineView.frame = CGRectMake(horizontalPadding, menuOptions.height - (height + verticalPadding), width, height)
        underlineView.backgroundColor = color
        contentView.addSubview(underlineView)
    }
    
    private func setupRoundRectViewIfNeeded() {
        guard case let .RoundRect(radius, _, verticalPadding, selectedColor) = menuOptions.focusMode else { return }
        
        let height = menuOptions.height - verticalPadding * 2
        roundRectView.frame = CGRectMake(0, verticalPadding, 0, height)
        roundRectView.layer.cornerRadius = radius
        roundRectView.backgroundColor = selectedColor
        contentView.addSubview(roundRectView)
    }
    
    private func animateUnderlineViewIfNeeded() {
        guard case let .Underline(_, _, horizontalPadding, _) = menuOptions.focusMode else { return }
        
        let targetFrame = menuItemViews[currentPage].frame
        underlineView.frame.origin.x = targetFrame.minX + horizontalPadding
        underlineView.frame.size.width = targetFrame.width - horizontalPadding * 2
    }
    
    private func animateRoundRectViewIfNeeded() {
        guard case let .RoundRect(_, horizontalPadding, _, _) = menuOptions.focusMode else { return }
        
        let targetFrame = menuItemViews[currentPage].frame
        roundRectView.frame.origin.x = targetFrame.minX + horizontalPadding
        roundRectView.frame.size.width = targetFrame.width - horizontalPadding * 2
    }

    private func relayoutMenuItemViews() {
        sortMenuItemViews()
        layoutMenuItemViews()
    }

    private func positionMenuItemViews() {
        contentOffset.x = contentOffsetX
        animateUnderlineViewIfNeeded()
        animateRoundRectViewIfNeeded()
    }
    
    private func adjustmentContentInsetIfNeeded() {
        switch menuOptions.displayMode {
        case let .Standard(_, centerItem, _) where centerItem: break
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
    
    private func focusMenuItem() {
        let selected: (MenuItemView) -> Bool = { self.menuItemViews.indexOf($0) == self.currentPage }
        
        // make selected item focused
        menuItemViews.forEach {
            $0.selected = selected($0)
            if $0.selected {
                self.currentMenuItemView = $0
            }
        }

        // make selected item foreground
        sortedMenuItemViews.forEach { $0.layer.zPosition = selected($0) ? 0 : -1 }
        
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
    func updateCurrentPage(page: Int) {
        currentIndex = page
    }
}

extension MenuView: ViewCleanable {
    func cleanup() {
        contentView.removeFromSuperview()
        switch menuOptions.focusMode {
        case .Underline: underlineView.removeFromSuperview()
        case .RoundRect: roundRectView.removeFromSuperview()
        case .None: break
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
        case .Infinite: return menuOptions.itemsOptions.count * menuOptions.dummyItemViewsSet
        default: return menuOptions.itemsOptions.count
        }
    }
    func rawPage(page: Int) -> Int {
        let startIndex = currentPage - menuItemCount / 2
        return (startIndex + page + menuItemCount) % menuItemCount
    }
}