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
    public private(set) var menuView: MenuView!
    public private(set) var currentPage: Int = 0
    public private(set) var currentViewController: UIViewController!
    public private(set) var visiblePagingViewControllers = [UIViewController]()
    public private(set) var pagingViewControllers = [UIViewController]() {
        willSet {
            options.menuItemCount = newValue.count
        }
    }
    
    private var contentScrollView: UIScrollView!
    private var contentView: UIView!
    private var menuItemTitles: [String] {
        get {
            return pagingViewControllers.map {
                return $0.title ?? "Menu"
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
    private var previousIndex: Int {
        guard case .Infinite = options.menuDisplayMode else { return currentPage - 1 }
        
        return currentPage - 1 < 0 ? options.menuItemCount - 1 : currentPage - 1
    }
    private var nextIndex: Int {
        guard case .Infinite = options.menuDisplayMode else { return currentPage + 1 }
        
        return currentPage + 1 > options.menuItemCount - 1 ? 0 : currentPage + 1
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

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // position properly for Infinite mode
        menuView?.moveToMenu(page: currentPage, animated: false)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // fix unnecessary inset for menu view when implemented by programmatically
        menuView?.contentInset.top = 0

        // position paging views correctly after view size is decided
        if let currentViewController = currentViewController {
            contentScrollView.contentOffset.x = currentViewController.view!.frame.minX
        }
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        menuView.updateMenuViewConstraints(size: size)
        
        coordinator.animateAlongsideTransition({ [weak self] (_) -> Void in
            guard let _ = self else { return }
            
            self!.view.setNeedsLayout()
            self!.view.layoutIfNeeded()
            
            // reset selected menu item view position
            switch self!.options.menuDisplayMode {
            case .Standard, .Infinite:
                self!.menuView.moveToMenu(page: self!.currentPage, animated: true)
            default: break
            }
        }, completion: nil)
    }
    
    // MARK: - Public
    
    public func setup(viewControllers viewControllers: [UIViewController], options: PagingMenuOptions) {
        self.options = options
        pagingViewControllers = viewControllers
        visiblePagingViewControllers.reserveCapacity(visiblePagingViewNumber)
        
        // validate
        validateDefaultPage()
        validatePageNumbers()
        
        // cleanup
        cleanup()
        
        currentPage = options.defaultPage
        
        constructMenuView()
        constructContentScrollView()
        layoutMenuView()
        layoutContentScrollView()
        constructContentView()
        layoutContentView()
        constructPagingViewControllers()
        layoutPagingViewControllers()

        currentPosition = currentPagingViewPosition()
        currentViewController = pagingViewControllers[currentPage]
        moveToMenuPage(currentPage, animated: false)
    }
    
    public func rebuild(viewControllers: [UIViewController], options: PagingMenuOptions) {
        // cleanup properties to avoid memory leaks. This could also be placed inside the cleanup method, or in within didSet{} of the pagingViewController
        visiblePagingViewControllers.removeAll()
        currentViewController = nil
        
        for childViewController in childViewControllers {
            childViewController.view.removeFromSuperview()
            childViewController.removeFromParentViewController()
        }

        // perform setup
        
        setup(viewControllers: viewControllers, options: options)
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    public func moveToMenuPage(page: Int, animated: Bool) {
        // ignore an unexpected page number
        guard page < options.menuItemCount else { return }
        
        let lastPage = currentPage
        currentPage = page
        currentViewController = pagingViewControllers[page]
        menuView.moveToMenu(page: currentPage, animated: animated)
        
        delegate?.willMoveToMenuPage?(currentPage)
        
        // hide paging views if it's moving to far away
        hidePagingViewsIfNeeded(lastPage)
        
        let duration = animated ? options.animationDuration : 0
        UIView.animateWithDuration(duration, animations: {
            [weak self] () -> Void in
            guard let _ = self else { return }
            
            self!.contentScrollView.contentOffset.x = self!.currentViewController.view!.frame.minX
            }) { [weak self] (_) -> Void in
                guard let _ = self else { return }
                
                // show paging views
                self!.visiblePagingViewControllers.forEach { $0.view.alpha = 1 }
                
                // reconstruct visible paging views
                self!.constructPagingViewControllers()
                self!.layoutPagingViewControllers()
                self!.view.setNeedsLayout()
                self!.view.layoutIfNeeded()
                
                self!.currentPosition = self!.currentPagingViewPosition()
                self!.delegate?.didMoveToMenuPage?(self!.currentPage)
        }
    }
    
    // MARK: - UISCrollViewDelegate
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        guard scrollView.isEqual(contentScrollView) else { return }

        let position = currentPagingViewPosition()
        
        // set new page number according to current moving direction
        switch position {
        case .Left: currentPage = previousIndex
        case .Right: currentPage = nextIndex
        default: return
        }

        delegate?.willMoveToMenuPage?(currentPage)
        menuView.moveToMenu(page: currentPage, animated: true)
        currentViewController = pagingViewControllers[currentPage]
        contentScrollView.contentOffset.x = currentViewController.view!.frame.minX

        constructPagingViewControllers()
        layoutPagingViewControllers()
        view.setNeedsLayout()
        view.layoutIfNeeded()

        currentPosition = currentPagingViewPosition()
        delegate?.didMoveToMenuPage?(currentPage)
    }
    
    // MARK: - UIGestureRecognizer
    
    internal func handleTapGesture(recognizer: UITapGestureRecognizer) {
        let tappedMenuView = recognizer.view as! MenuItemView
        guard let tappedPage = menuView.menuItemViews.indexOf(tappedMenuView) where tappedPage != currentPage else { return }
        
        let page = targetPage(tappedPage: tappedPage)
        moveToMenuPage(page, animated: true)
    }
    
    internal func handleSwipeGesture(recognizer: UISwipeGestureRecognizer) {
        var newPage = currentPage
        if recognizer.direction == .Left {
            newPage = min(nextIndex, menuView.menuItemViews.count - 1)
        } else if recognizer.direction == .Right {
            newPage = max(previousIndex, 0)
        } else {
            return
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
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[menuView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints: [NSLayoutConstraint]
        switch options.menuPosition {
        case .Top:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[menuView(height)]", options: [], metrics: metrics, views: viewsDictionary)
        case .Bottom:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView(height)]|", options: [], metrics: metrics, views: viewsDictionary)
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
        contentScrollView.scrollEnabled = options.scrollEnabled
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentScrollView)
    }
    
    private func layoutContentScrollView() {
        let viewsDictionary = ["contentScrollView": contentScrollView, "menuView": menuView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentScrollView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints: [NSLayoutConstraint]
        switch options.menuPosition {
        case .Top:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView][contentScrollView]|", options: [], metrics: nil, views: viewsDictionary)
        case .Bottom:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentScrollView][menuView]", options: [], metrics: nil, views: viewsDictionary)
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
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView(==contentScrollView)]|", options: [], metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
    
    private func constructPagingViewControllers() {
        for (index, pagingViewController) in pagingViewControllers.enumerate() {
            // construct three child view controllers at a maximum, previous(optional), current and next(optional)
            if !shouldLoadPage(index) {
                // remove unnecessary child view controllers
                if isVisiblePagingViewController(pagingViewController) {
                    pagingViewController.willMoveToParentViewController(nil)
                    pagingViewController.view!.removeFromSuperview()
                    pagingViewController.removeFromParentViewController()
                    
                    if let viewIndex = visiblePagingViewControllers.indexOf(pagingViewController) {
                        visiblePagingViewControllers.removeAtIndex(viewIndex)
                    }
                }
                continue
            }
            
            // ignore if it's already added
            if isVisiblePagingViewController(pagingViewController) {
                continue
            }
            
            pagingViewController.view!.frame = CGRectZero
            pagingViewController.view!.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(pagingViewController.view!)
            addChildViewController(pagingViewController as UIViewController)
            pagingViewController.didMoveToParentViewController(self)
            
            visiblePagingViewControllers.append(pagingViewController)
        }
    }
    
    private func layoutPagingViewControllers() {
        // cleanup
        NSLayoutConstraint.deactivateConstraints(contentView.constraints)

        var viewsDictionary: [String: AnyObject] = ["contentScrollView": contentScrollView]
        for (index, pagingViewController) in pagingViewControllers.enumerate() {
            if !shouldLoadPage(index) {
                continue
            }
            
            viewsDictionary["pagingView"] = pagingViewController.view!
            var horizontalVisualFormat = String()
            
            // only one view controller
            if (options.menuItemCount == options.minumumSupportedViewCount) {
                horizontalVisualFormat = "H:|[pagingView(==contentScrollView)]|"
            } else {
                if case .Infinite = options.menuDisplayMode {
                    if index == currentPage {
                        viewsDictionary["previousPagingView"] = pagingViewControllers[previousIndex].view
                        viewsDictionary["nextPagingView"] = pagingViewControllers[nextIndex].view
                        horizontalVisualFormat = "H:[previousPagingView][pagingView(==contentScrollView)][nextPagingView]"
                    } else if index == previousIndex {
                        horizontalVisualFormat = "H:|[pagingView(==contentScrollView)]"
                    } else if index == nextIndex {
                        horizontalVisualFormat = "H:[pagingView(==contentScrollView)]|"
                    }
                } else {
                    if index == 0 || index == previousIndex {
                        horizontalVisualFormat = "H:|[pagingView(==contentScrollView)]"
                    } else {
                        viewsDictionary["previousPagingView"] = pagingViewControllers[index - 1].view
                        if index == pagingViewControllers.count - 1 || index == nextIndex {
                            horizontalVisualFormat = "H:[previousPagingView][pagingView(==contentScrollView)]|"
                        } else {
                            horizontalVisualFormat = "H:[previousPagingView][pagingView(==contentScrollView)]"
                        }
                    }
                }
            }
            
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(horizontalVisualFormat, options: [], metrics: nil, views: viewsDictionary)
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pagingView(==contentScrollView)]|", options: [], metrics: nil, views: viewsDictionary)
            
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
        currentPage = options.defaultPage
    }
    
    // MARK: - Gesture handler
    
    private func addTapGestureHandlers() {
        menuView.menuItemViews.forEach { $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "handleTapGesture:")) }
    }
    
    private func addSwipeGestureHandlersIfNeeded() {
        switch options.menuDisplayMode {
        case .Standard(_, _, .PagingEnabled): break
        case .Standard: return
        case .SegmentedControl: return
        case .Infinite: break
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
    
    private func hidePagingViewsIfNeeded(lastPage: Int) {
        guard lastPage != previousIndex && lastPage != nextIndex else { return }
        visiblePagingViewControllers.forEach { $0.view.alpha = 0 }
    }

    private func shouldLoadPage(index: Int) -> Bool {
        if case .Infinite = options.menuDisplayMode {
            guard index == currentPage || index == previousIndex || index == nextIndex else { return false }
        } else {
            guard index >= previousIndex && index <= nextIndex else { return false }
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
        
        if case .Infinite = options.menuDisplayMode {
            return PagingViewPosition(order: order)
        }
        
        // consider left edge menu as center position
        guard currentPage == 0 && contentScrollView.contentSize.width < (pageWidth * CGFloat(visiblePagingViewNumber)) else { return PagingViewPosition(order: order) }
        return PagingViewPosition(order: order + 1)
    }
    
    private func targetPage(tappedPage tappedPage: Int) -> Int {
        guard case let .Standard(_, _, scrollingMode) = options.menuDisplayMode else { return tappedPage }
        guard case .PagingEnabled = scrollingMode else { return tappedPage }
        return tappedPage < currentPage ? currentPage - 1 : currentPage + 1
    }
    
    // MARK: - Validator
    
    private func validateDefaultPage() {
        guard options.defaultPage >= options.menuItemCount || options.defaultPage < 0 else { return }
        
        NSException(name: ExceptionName, reason: "default page is invalid", userInfo: nil).raise()
    }
    
    private func validatePageNumbers() {
        guard case .Infinite = options.menuDisplayMode else { return }
        guard options.menuItemCount < visiblePagingViewNumber else { return }
        
        NSException(name: ExceptionName, reason: "the number of view controllers should be more than three with Infinite display mode", userInfo: nil).raise()
    }
}