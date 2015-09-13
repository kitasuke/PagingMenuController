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
    
    private let ExceptionName = "PMCException"

    // MARK: - Lifecycle
    
    public init(viewControllers: [UIViewController], options: PagingMenuOptions) {
        super.init(nibName: nil, bundle: nil)
        
        setup(viewControllers: viewControllers, options: options)
    }
    
    convenience public init(viewControllers: [UIViewController]) {
        self.init(viewControllers: viewControllers, options: PagingMenuOptions())
    }

    required public init(coder aDecoder: NSCoder) {
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
            contentScrollView.contentOffset.x = currentViewController.view!.frame.origin.x
        }
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        menuView.updateMenuItemConstraintsIfNeeded(size: size)
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    public func setup(#viewControllers: [UIViewController], options: PagingMenuOptions) {
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
        
        let page = currentPagingViewPage()
        if currentPage == page {
            self.contentScrollView.contentOffset = scrollView.contentOffset
        } else {
            currentPage = page
            menuView.moveToMenu(page: currentPage, animated: true)
        }
    }
    
    public func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        if !scrollView.isEqual(self.contentScrollView) {
            return
        }
        
        let nextPage = scrollView.panGestureRecognizer.translationInView(contentView).x < 0.0 ? currentPage + 1 : currentPage - 1
        delegate?.willMoveToMenuPage?(nextPage)
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if !scrollView.isEqual(self.contentScrollView) {
            return
        }

        currentViewController = pagingViewControllers[currentPage]

        delegate?.didMoveToMenuPage?(currentPage)
        constructPagingViewControllers()
        layoutPagingViewControllers()
    }
    
    // MARK: - UIGestureRecognizer
    
    internal func handleTapGesture(recognizer: UITapGestureRecognizer) {
        let tappedMenuView = recognizer.view as! MenuItemView
        if let tappedPage = find(menuView.menuItemViews, tappedMenuView) where tappedPage != currentPage {
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
        menuView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(menuView)
        
        addTapGestureHandlers()
        addSwipeGestureHandlersIfNeeded()
    }
    
    private func layoutMenuView() {
        let viewsDictionary = ["menuView": menuView]
        let metrics = ["height": options.menuHeight]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[menuView]|", options: .allZeros, metrics: nil, views: viewsDictionary)
        let verticalConstraints: [AnyObject]
        switch options.menuPosition {
        case .Top:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[menuView(height)]", options: .allZeros, metrics: metrics, views: viewsDictionary)
        case .Bottom:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView(height)]|", options: .allZeros, metrics: metrics, views: viewsDictionary)
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
        contentScrollView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(contentScrollView)
    }
    
    private func layoutContentScrollView() {
        let viewsDictionary = ["contentScrollView": contentScrollView, "menuView": menuView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentScrollView]|", options: .allZeros, metrics: nil, views: viewsDictionary)
        let verticalConstraints: [AnyObject]
        switch options.menuPosition {
        case .Top:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView][contentScrollView]|", options: .allZeros, metrics: nil, views: viewsDictionary)
        case .Bottom:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentScrollView][menuView]", options: .allZeros, metrics: nil, views: viewsDictionary)
        }
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
    
    private func constructContentView() {
        contentView = UIView(frame: CGRectZero)
        contentView.setTranslatesAutoresizingMaskIntoConstraints(false)
        contentScrollView.addSubview(contentView)
    }
    
    private func layoutContentView() {
        let viewsDictionary = ["contentView": contentView, "contentScrollView": contentScrollView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: .allZeros, metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView(==contentScrollView)]|", options: .allZeros, metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
    
    private func constructPagingViewControllers() {
        for (index, pagingViewController) in enumerate(pagingViewControllers) {
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
            pagingViewController.view!.setTranslatesAutoresizingMaskIntoConstraints(false)

            contentView.addSubview(pagingViewController.view!)
            addChildViewController(pagingViewController as UIViewController)
            pagingViewController.didMoveToParentViewController(self)
        }
    }
    
    private func layoutPagingViewControllers() {
        // cleanup
        NSLayoutConstraint.deactivateConstraints(contentView.constraints())

        var viewsDictionary: [String: AnyObject] = ["contentScrollView": contentScrollView]
        for (index, pagingViewController) in enumerate(pagingViewControllers) {
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
            
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(horizontalVisualFormat, options: .allZeros, metrics: nil, views: viewsDictionary)
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pagingView(==contentScrollView)]|", options: .allZeros, metrics: nil, views: viewsDictionary)
            
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

        delegate?.willMoveToMenuPage?(currentPage)
        menuView.moveToMenu(page: currentPage, animated: animated)

        let duration = animated ? options.animationDuration : 0
        UIView.animateWithDuration(duration, animations: {
            [unowned self] () -> Void in
            self.contentScrollView.contentOffset.x = self.currentViewController.view!.frame.origin.x
        }) {
            (finished: Bool) -> Void in
            if finished {
                self.delegate?.didMoveToMenuPage?(self.currentPage)
                self.constructPagingViewControllers()
                self.layoutPagingViewControllers()
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
        return contains(childViewControllers as! [UIViewController], pagingViewController)
    }
    
    // MARK: - Page calculator
    
    private func currentPagingViewPage() -> Int {
        let pageWidth = contentScrollView.frame.width
        
        return Int(floor((contentScrollView.contentOffset.x - pageWidth / 2) / pageWidth)) + 1
    }
    
    private func targetPage(#tappedPage: Int) -> Int {
        switch options.menuDisplayMode {
        case .FlexibleItemWidth(_, let scrollingMode):
            switch scrollingMode {
            case .PagingEnabled:
                return tappedPage < currentPage ? currentPage-1 : currentPage+1
            default:
                return tappedPage
            }
        case .FixedItemWidth(_, _, let scrollingMode):
            switch scrollingMode {
            case .PagingEnabled:
                return tappedPage < currentPage ? currentPage-1 : currentPage+1
            default:
                return tappedPage
            }
        case .SegmentedControl:
            return tappedPage
        }
    }
    
    // MARK: - Validator
    
    private func validateDefaultPage() {
        if options.defaultPage >= options.menuItemCount || options.defaultPage < 0 {
            NSException(name: ExceptionName, reason: "default page is invalid", userInfo: nil).raise()
        }
    }
}