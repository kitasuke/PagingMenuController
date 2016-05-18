//
//  MenuView.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/9/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

public protocol MenuItemType {}
extension String: MenuItemType {}
extension UIImage: MenuItemType {}

@objc public protocol MenuViewDelegate: class {
    optional func willMoveToMenuItemView(menuItemView: MenuItemView, previousMenuItemView: MenuItemView)
    optional func didMoveToMenuItemView(menuItemView: MenuItemView, previousMenuItemView: MenuItemView)
}

public class MenuView: UIScrollView {
    weak public var viewDelegate: MenuViewDelegate?
    public private(set) var menuItemViews = [MenuItemView]()
    public private(set) var currentPage: Int = 0
    public private(set) var currentMenuItemView: MenuItemView!
    internal var menuItemCount: Int {
        switch options.menuDisplayMode {
        case .Infinite: return options.menuItemCount * options.dummyMenuItemViewsSet
        default: return options.menuItemCount
        }
    }
    internal var previousPage: Int {
        return currentPage - 1 < 0 ? menuItemCount - 1 : currentPage - 1
    }
    internal var nextPage: Int {
        return currentPage + 1 > menuItemCount - 1 ? 0 : currentPage + 1
    }
    private var sortedMenuItemViews = [MenuItemView]()
    private var options: PagingMenuOptions!
    
    private let contentView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    lazy private var underlineView: UIView = {
        let view = UIView(frame: .zero)
        return view
    }()
    lazy private var roundRectView: UIView = {
        let view = UIView(frame: .zero)
        view.userInteractionEnabled = true
        return view
    }()
    private var menuViewBounces: Bool {
        switch options.menuDisplayMode {
        case .Standard(_, _, .ScrollEnabledAndBouces),
             .Infinite(_, .ScrollEnabledAndBouces): return true
        default: return false
        }
    }
    private var menuViewScrollEnabled: Bool {
        switch options.menuDisplayMode {
        case .Standard(_, _, .ScrollEnabledAndBouces),
             .Standard(_, _, .ScrollEnabled),
             .Infinite(_, .ScrollEnabledAndBouces),
             .Infinite(_, .ScrollEnabled): return true
        default: return false
        }
    }
    private var contentOffsetX: CGFloat {
        switch options.menuDisplayMode {
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
        guard menuItemCount > options.minumumSupportedViewCount else { return 0.0 }
        let ratio = CGFloat(currentPage) / CGFloat(menuItemCount - 1)
        return (contentSize.width - frame.width) * ratio
    }
    lazy private var rawIndex: (Int) -> Int = { [unowned self] in
        let count = self.menuItemCount
        let startIndex = self.currentPage - count / 2
        return (startIndex + $0 + count) % count
    }
    
    // MARK: - Lifecycle
    
    internal init<Element: MenuItemType>(menuItemTypes: [Element], options: PagingMenuOptions) {
        super.init(frame: .zero)
        
        self.options = options
        self.options.menuItemCount = menuItemTypes.count
        commonInit({ self.constructMenuItemViews(menuItemTypes) })
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
        let duration = animated ? options.animationDuration : 0
        let previousPage = currentPage
        currentPage = page
        
        // hide menu view when constructing itself
        if !animated {
            alpha = 0
        }
        
        let menuItemView = menuItemViews[page]
        let previousMenuItemView = currentMenuItemView
        
        if let previousMenuItemView = previousMenuItemView where page != previousPage {
            viewDelegate?.willMoveToMenuItemView?(menuItemView, previousMenuItemView: previousMenuItemView)
        }
        
        UIView.animateWithDuration(duration, animations: { [unowned self] () -> Void in
            self.focusMenuItem()
            if self.options.menuSelectedItemCenter {
                self.positionMenuItemViews()
            }
        }) { [weak self] (_) in
            guard let _ = self else { return }
            
            // relayout menu item views dynamically
            if case .Infinite = self!.options.menuDisplayMode {
                self!.relayoutMenuItemViews()
            }
            if self!.options.menuSelectedItemCenter {
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
    
    internal func updateMenuViewConstraints(size size: CGSize) {
        if case .SegmentedControl = options.menuDisplayMode {
            menuItemViews.forEach { $0.updateConstraints(size) }
        }
        setNeedsLayout()
        layoutIfNeeded()

        animateUnderlineViewIfNeeded()
        animateRoundRectViewIfNeeded()
    }
    
    internal func cleanup() {
        contentView.removeFromSuperview()
        switch options.menuItemMode {
        case .Underline(_, _, _, _): underlineView.removeFromSuperview()
        case .RoundRect(_, _, _, _): roundRectView.removeFromSuperview()
        case .None: break
        }
        
        if !menuItemViews.isEmpty {
            menuItemViews.forEach {
                $0.cleanup()
                $0.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Private method
    
    private func setupScrollView() {
        backgroundColor = options.backgroundColor
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bounces = menuViewBounces
        scrollEnabled = menuViewScrollEnabled
        decelerationRate = options.deceleratingRate
        scrollsToTop = false
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func layoutScrollView() {
        let viewsDictionary = ["menuView": self]
        let metrics = ["height": options.menuHeight]
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
    
    private func constructMenuItemViews<Element: MenuItemType>(menuItemTypes: [Element]) {
        constructMenuItemViews({
            switch self.options.menuItemViewContent {
            case .Text: return MenuItemView(title: menuItemTypes[$0] as! String, options: self.options, addDivider: $1)
            case .Image: return MenuItemView(image: menuItemTypes[$0] as! UIImage, options: self.options, addDivider: $1)
            }
        })
    }
    
    private func constructMenuItemViews(constructor: (Int, Bool) -> MenuItemView) {
        for index in 0..<menuItemCount {
            let addDivider = index < menuItemCount - 1
            let menuItemView = constructor(index % options.menuItemCount, addDivider)
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
        
        if case .Infinite = options.menuDisplayMode {
            for i in 0..<menuItemCount {
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
        guard case let .Underline(height, color, horizontalPadding, verticalPadding) = options.menuItemMode else { return }
        
        let width = menuItemViews[currentPage].bounds.width - horizontalPadding * 2
        underlineView.frame = CGRectMake(horizontalPadding, options.menuHeight - (height + verticalPadding), width, height)
        underlineView.backgroundColor = color
        contentView.addSubview(underlineView)
    }
    
    private func setupRoundRectViewIfNeeded() {
        guard case let .RoundRect(radius, _, verticalPadding, selectedColor) = options.menuItemMode else { return }
        
        let height = options.menuHeight - verticalPadding * 2
        roundRectView.frame = CGRectMake(0, verticalPadding, 0, height)
        roundRectView.layer.cornerRadius = radius
        roundRectView.backgroundColor = selectedColor
        contentView.addSubview(roundRectView)
    }
    
    private func animateUnderlineViewIfNeeded() {
        guard case let .Underline(_, _, horizontalPadding, _) = options.menuItemMode else { return }
        
        let targetFrame = menuItemViews[currentPage].frame
        underlineView.frame.origin.x = targetFrame.minX + horizontalPadding
        underlineView.frame.size.width = targetFrame.width - horizontalPadding * 2
    }
    
    private func animateRoundRectViewIfNeeded() {
        guard case let .RoundRect(_, horizontalPadding, _, _) = options.menuItemMode else { return }
        
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
        switch options.menuDisplayMode {
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