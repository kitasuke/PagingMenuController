//
//  PagingMenuController.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 3/18/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

@objc public protocol PagingMenuControllerDelegate: class {
    optional func willMoveToMenuPage(page: Int)
    optional func didMoveToMenuPage(page: Int)
}

public class PagingMenuController: UIViewController, UIScrollViewDelegate {
    
    public weak var delegate: PagingMenuControllerDelegate?
    private var options: PagingMenuOptions!
    private var menuView: MenuView!
    private var contentScrollView: UIScrollView!
    private var contentView: UIView!
    private var pagingViewControllers = [UIViewController]() {
        willSet {
            options.menuItemCount = newValue.count
        }
    }
    private var currentPage: Int = 0
    private var currentViewController: UIViewController!
    private var menuItemTitles: [String] {
        get {
            return pagingViewControllers.map { viewController -> String in
                return viewController.title ?? "Menu"
            }
        }
    }
    private enum PagingViewPosition {
        case Left
        case Center
        case Right
        case Unknown

        init(order: Int) {
            switch order {
            case 0: self = .Left
            case 1: self = .Center
            case 2: self = .Right
            default: self = .Unknown
            }
        }
    }
    private var currentPosition: PagingViewPosition = .Left
    private let visiblePagingViewNumber: Int = 3

    private let ExceptionName = "PMCException"

    // MARK: - Lifecycle
    
    public init(viewControllers: [UIViewController], options: PagingMenuOptions) {
        super.init(nibName: nil, bundle: nil)
        
        setup(viewControllers: viewControllers, options: options)
    }
    
    convenience public init(viewControllers: [UIViewController]) {
        self.init(viewControllers: viewControllers, options: PagingMenuOptions())
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        moveToMenuPage(currentPage, animated: false)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // fix unnecessary inset for menu view when implemented by programmatically
        menuView.contentInset = UIEdgeInsetsZero

        if let currentViewController = currentViewController {
            contentScrollView.contentOffset.x = currentViewController.view!.frame.minX
        }
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        menuView.updateMenuItemConstraintsIfNeeded(size: size)
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    public func setup(viewControllers viewControllers: [UIViewController], options: PagingMenuOptions) {
        self.options = options
        pagingViewControllers = viewControllers
        
        // validate
        validateDefaultPage()
        
        cleanup()
        
        currentPage = self.options.defaultPage
        
        constructMenuView()
        constructContentScrollView()
        layoutMenuView()
        layoutContentScrollView()
        constructContentView()
        layoutContentView()
        constructPagingViewControllers()
        layoutPagingViewControllers()

        currentPosition = currentPagingViewPosition()
        currentViewController = pagingViewControllers[self.options.defaultPage]
    }
    
    public func rebuild(viewControllers: [UIViewController], options: PagingMenuOptions) {
        setup(viewControllers: viewControllers, options: options)
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    // MARK: - UISCrollViewDelegate
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if !scrollView.isEqual(self.contentScrollView) || scrollView.dragging != true {
            return
        }
        
        let position = currentPagingViewPosition()
        if currentPosition != position {
            let newPage: Int
            switch position {
            case .Left: newPage = currentPage - 1
            case .Right: newPage = currentPage + 1
            default: newPage = currentPage
            }

            menuView.moveToMenu(page: newPage, animated: true)
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if !scrollView.isEqual(self.contentScrollView) {
            return
        }

        let position = currentPagingViewPosition()

        // go back to starting position
        if currentPosition == position {
            menuView.moveToMenu(page: currentPage, animated: true)
            return
        }

        // set new page number according to current moving direction
        switch position {
        case .Left: currentPage--
        case .Right: currentPage++
        default: return
        }

        delegate?.willMoveToMenuPage?(currentPage)
        currentViewController = pagingViewControllers[currentPage]
        contentScrollView.contentOffset.x = currentViewController.view!.frame.minX

        constructPagingViewControllers()
        layoutPagingViewControllers()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()

        currentPosition = currentPagingViewPosition()
        delegate?.didMoveToMenuPage?(currentPage)
    }
    
    // MARK: - UIGestureRecognizer
    
    internal func handleTapGesture(recognizer: UITapGestureRecognizer) {
        let tappedMenuView = recognizer.view as! MenuItemView
        if let tappedPage = menuView.menuItemViews.indexOf(tappedMenuView) where tappedPage != currentPage {
            let page = targetPage(tappedPage: tappedPage)
            moveToMenuPage(page, animated: true)
        }
    }
    
    internal func handleSwipeGesture(recognizer: UISwipeGestureRecognizer) {
        var newPage = currentPage
        if recognizer.direction == .Left {
            newPage = min(++newPage, menuView.menuItemViews.count - 1)
        } else if recognizer.direction == .Right {
            newPage = max(--newPage, 0)
        }
        moveToMenuPage(newPage, animated: true)
    }
    
    // MARK: - Constructor
    
    private func constructMenuView() {
        menuView = MenuView(menuItemTitles: menuItemTitles, options: options)
        menuView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuView)
        
        addTapGestureHandlers()
        addSwipeGestureHandlersIfNeeded()
    }
    
    private func layoutMenuView() {
        let viewsDictionary = ["menuView": menuView]
        let metrics = ["height": options.menuHeight]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[menuView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let verticalConstraints: [NSLayoutConstraint]
        switch options.menuPosition {
        case .Top:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[menuView(height)]", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: viewsDictionary)
        case .Bottom:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView(height)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: metrics, views: viewsDictionary)
        }
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        
        menuView.setNeedsLayout()
        menuView.layoutIfNeeded()
    }
    
    private func constructContentScrollView() {
        contentScrollView = UIScrollView(frame: CGRectZero)
        contentScrollView.delegate = self
        contentScrollView.pagingEnabled = true
        contentScrollView.showsHorizontalScrollIndicator = false
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.scrollsToTop = false
        contentScrollView.bounces = false
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentScrollView)
    }
    
    private func layoutContentScrollView() {
        let viewsDictionary = ["contentScrollView": contentScrollView, "menuView": menuView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentScrollView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let verticalConstraints: [NSLayoutConstraint]
        switch options.menuPosition {
        case .Top:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView][contentScrollView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        case .Bottom:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentScrollView][menuView]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        }
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
    
    private func constructContentView() {
        contentView = UIView(frame: CGRectZero)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentScrollView.addSubview(contentView)
    }
    
    private func layoutContentView() {
        let viewsDictionary = ["contentView": contentView, "contentScrollView": contentScrollView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView(==contentScrollView)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
    
    private func constructPagingViewControllers() {
        for (index, pagingViewController) in pagingViewControllers.enumerate() {
            if shouldLoadPage(index) != true {
                // remove unnecessary child view controllers
                if isVisiblePagingViewController(pagingViewController) {
                    pagingViewController.willMoveToParentViewController(nil)
                    pagingViewController.view!.removeFromSuperview()
                    pagingViewController.removeFromParentViewController()
                }
                continue
            }

            // construct three child view controllers at a maximum, previous(optional), current and next(optional)
            if isVisiblePagingViewController(pagingViewController) {
                continue
            }

            pagingViewController.view!.frame = CGRectZero
            pagingViewController.view!.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(pagingViewController.view!)
            addChildViewController(pagingViewController as UIViewController)
            pagingViewController.didMoveToParentViewController(self)
        }
    }
    
    private func layoutPagingViewControllers() {
        // cleanup
        NSLayoutConstraint.deactivateConstraints(contentView.constraints)

        var viewsDictionary: [String: AnyObject] = ["contentScrollView": contentScrollView]
        for (index, pagingViewController) in pagingViewControllers.enumerate() {
            if shouldLoadPage(index) != true {
                continue
            }
            
            viewsDictionary["pagingView"] = pagingViewController.view!
            let horizontalVisualFormat: String

            // only one view controller
            if (options.menuItemCount == options.minumumSupportedViewCount) {
                horizontalVisualFormat = "H:|[pagingView(==contentScrollView)]|"
            } else {
                if index == 0 || index == currentPage - 1 {
                    horizontalVisualFormat = "H:|[pagingView(==contentScrollView)]"
                } else {
                    viewsDictionary["previousPagingView"] = pagingViewControllers[index - 1].view
                    if index == pagingViewControllers.count - 1 || index == currentPage + 1 {
                        horizontalVisualFormat = "H:[previousPagingView][pagingView(==contentScrollView)]|"
                    } else {
                        horizontalVisualFormat = "H:[previousPagingView][pagingView(==contentScrollView)]"
                    }
                }
            }
            
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(horizontalVisualFormat, options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pagingView(==contentScrollView)]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
            
            NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        }

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        if let menuView = self.menuView, let contentScrollView = self.contentScrollView {
            menuView.removeFromSuperview()
            contentScrollView.removeFromSuperview()
        }
        currentPage = 0
    }
    
    // MARK: - Gesture handler
    
    private func addTapGestureHandlers() {
        for menuItemView in menuView.menuItemViews {
            menuItemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "handleTapGesture:"))
        }
    }
    
    private func addSwipeGestureHandlersIfNeeded() {
        switch options.menuDisplayMode {
        case .FlexibleItemWidth(_, let scrollingMode):
            switch scrollingMode {
            case .PagingEnabled: break
            default: return
            }
        case .FixedItemWidth(_, _, let scrollingMode):
            switch scrollingMode {
            case .PagingEnabled: break
            default: return
            }
        case .SegmentedControl:
            return
        }
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: "handleSwipeGesture:")
        leftSwipeGesture.direction = .Left
        menuView.panGestureRecognizer.requireGestureRecognizerToFail(leftSwipeGesture)
        menuView.addGestureRecognizer(leftSwipeGesture)
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: "handleSwipeGesture:")
        rightSwipeGesture.direction = .Right
        menuView.panGestureRecognizer.requireGestureRecognizerToFail(rightSwipeGesture)
        menuView.addGestureRecognizer(rightSwipeGesture)
    }
    
    // MARK: - Page controller
    
    private func moveToMenuPage(page: Int, animated: Bool) {
        currentPage = page
        currentViewController = pagingViewControllers[page]
        menuView.moveToMenu(page: currentPage, animated: animated)

        delegate?.willMoveToMenuPage?(currentPage)

        let duration = animated ? options.animationDuration : 0
        UIView.animateWithDuration(duration, animations: {
            [unowned self] () -> Void in
            self.contentScrollView.contentOffset.x = self.currentViewController.view!.frame.minX
        }) {
            (finished: Bool) -> Void in
            if finished {
                self.delegate?.didMoveToMenuPage?(self.currentPage)
                self.constructPagingViewControllers()
                self.layoutPagingViewControllers()
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }
        }
    }

    private func shouldLoadPage(index: Int) -> Bool {
        if index < currentPage - 1 || index > currentPage + 1 {
            return false
        }
        return true
    }

    private func isVisiblePagingViewController(pagingViewController: UIViewController) -> Bool {
        return childViewControllers.contains(pagingViewController)
    }
    
    // MARK: - Page calculator
    
    private func currentPagingViewPosition() -> PagingViewPosition {
        let pageWidth = contentScrollView.frame.width
        let order = Int(ceil((contentScrollView.contentOffset.x - pageWidth / 2) / pageWidth))
        if currentPage == 0 &&
                contentScrollView.contentSize.width < (pageWidth * CGFloat(visiblePagingViewNumber)) {
            // consider left edge menu as center position
            return PagingViewPosition(order: order + 1)
        }
        return PagingViewPosition(order: order)
    }
    
    private func targetPage(tappedPage tappedPage: Int) -> Int {
        switch options.menuDisplayMode {
        case .FlexibleItemWidth(_, let scrollingMode):
            if case .PagingEnabled = scrollingMode {
                return tappedPage < currentPage ? currentPage-1 : currentPage+1
            }
        case .FixedItemWidth(_, _, let scrollingMode):
            if case .PagingEnabled = scrollingMode {
                return tappedPage < currentPage ? currentPage-1 : currentPage+1
            }
        case .SegmentedControl:
            return tappedPage
        }
        return tappedPage
    }
    
    // MARK: - Validator
    
    private func validateDefaultPage() {
        if options.defaultPage >= options.menuItemCount || options.defaultPage < 0 {
            NSException(name: ExceptionName, reason: "default page is invalid", userInfo: nil).raise()
        }
    }
}