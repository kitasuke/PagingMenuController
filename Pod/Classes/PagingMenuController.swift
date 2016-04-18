//
//  PagingMenuController.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 3/18/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

@objc public protocol PagingMenuControllerDelegate: class {
    optional func willMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController)
    optional func didMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController)
}

public class PagingMenuController: UIViewController, UIScrollViewDelegate {
    
    public weak var delegate: PagingMenuControllerDelegate?
    public private(set) var menuView: MenuView!
    public private(set) var currentPage: Int = 0
    public private(set) var currentViewController: UIViewController!
    public private(set) var visiblePagingViewControllers = [UIViewController]()
    public private(set) var pagingViewControllers = [UIViewController]() {
        willSet {
            options.menuItemCount = newValue.count
        }
        didSet {
            cleanup()
        }
    }
    
    private var options: PagingMenuOptions!
    private let visiblePagingViewNumber: Int = 3
    private let contentScrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.scrollsToTop = false
        scrollView.bounces = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    private let contentView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var menuItemTitles: [String] {
        return pagingViewControllers.map {
            return $0.title ?? "Menu"
        }
    }
    private enum PagingViewPosition {
        case Left, Center, Right, Unknown
        
        init(order: Int) {
            switch order {
            case 0: self = .Left
            case 1: self = .Center
            case 2: self = .Right
            default: self = .Unknown
            }
        }
    }
    private var previousIndex: Int {
        guard case .Infinite = options.menuDisplayMode else { return currentPage - 1 }
        
        return currentPage - 1 < 0 ? options.menuItemCount - 1 : currentPage - 1
    }
    private var nextIndex: Int {
        guard case .Infinite = options.menuDisplayMode else { return currentPage + 1 }
        
        return currentPage + 1 > options.menuItemCount - 1 ? 0 : currentPage + 1
    }
    private var currentPagingViewPosition: PagingViewPosition {
        let pageWidth = contentScrollView.frame.width
        let order = Int(ceil((contentScrollView.contentOffset.x - pageWidth / 2) / pageWidth))
        
        if case .Infinite = options.menuDisplayMode {
            return PagingViewPosition(order: order)
        }
        
        // consider left edge menu as center position
        guard currentPage == 0 && contentScrollView.contentSize.width < (pageWidth * CGFloat(visiblePagingViewNumber)) else { return PagingViewPosition(order: order) }
        return PagingViewPosition(order: order + 1)
    }
    lazy private var targetPage: (Int) -> Int = {
        guard case let .Standard(_, _, scrollingMode) = self.options.menuDisplayMode else { return $0 }
        guard case .PagingEnabled = scrollingMode else { return $0 }
        return $0 < self.currentPage ? self.currentPage - 1 : self.currentPage + 1
    }
    lazy private var shouldLoadPage: (Int) -> Bool = {
        switch self.options.lazyLoadingPage {
        case .One:
            guard $0 == self.currentPage else { return false }
        case .Three:
            if case .Infinite = self.options.menuDisplayMode {
                guard $0 == self.currentPage || $0 == self.previousIndex || $0 == self.nextIndex else { return false }
            } else {
                guard $0 >= self.previousIndex && $0 <= self.nextIndex else { return false }
            }
        }
        return true
    }
    
    lazy private var isVisiblePagingViewController: (UIViewController) -> Bool = {
        return self.childViewControllers.contains($0)
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
        if let currentViewController = currentViewController, let currentView = currentViewController.view {
            contentScrollView.contentOffset.x = currentView.frame.minX
        }
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if let menuView = menuView {
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
    }
    
    // MARK: - Public
    
    public func setup(viewControllers viewControllers: [UIViewController], options: PagingMenuOptions) {
        self.options = options
        pagingViewControllers = viewControllers
        visiblePagingViewControllers.reserveCapacity(visiblePagingViewNumber)
        
        // validate
        validateDefaultPage()
        validatePageNumbers()
        
        currentPage = options.defaultPage
        
        constructMenuView()
        setupContentScrollView()
        layoutMenuView()
        layoutContentScrollView()
        setupContentView()
        layoutContentView()
        constructPagingViewControllers()
        layoutPagingViewControllers()
        
        currentViewController = pagingViewControllers[currentPage]
        moveToMenuPage(currentPage, animated: false)
    }
    
    public func moveToMenuPage(page: Int, animated: Bool) {
        // ignore an unexpected page number
        guard page < options.menuItemCount else { return }
        
        let previousPage = currentPage
        let previousViewController = currentViewController
        currentViewController = pagingViewControllers[page]
        delegate?.willMoveToPageMenuController?(currentViewController, previousMenuController: previousViewController)
        
        currentPage = page
        menuView.moveToMenu(page: currentPage, animated: animated)
        
        // hide paging views if it's moving to far away
        hidePagingViewsIfNeeded(previousPage)
        
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
                
                self!.delegate?.didMoveToPageMenuController?(self!.currentViewController, previousMenuController: previousViewController)
        }
    }
    
    // MARK: - UIScrollViewDelegate
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        guard scrollView.isEqual(contentScrollView) else { return }
        
        // set new page number according to current moving direction
        let nextPage: Int
        switch currentPagingViewPosition {
        case .Left: nextPage = previousIndex
        case .Right: nextPage = nextIndex
        default: return
        }
        
        let previousViewController = currentViewController
        currentViewController = pagingViewControllers[nextPage]
        delegate?.willMoveToPageMenuController?(currentViewController, previousMenuController: previousViewController)
        
        currentPage = nextPage
        menuView.moveToMenu(page: currentPage, animated: true)
        if let currentView = currentViewController.view {
            contentScrollView.contentOffset.x = currentView.frame.minX
        }
        
        constructPagingViewControllers()
        layoutPagingViewControllers()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        delegate?.didMoveToPageMenuController?(currentViewController, previousMenuController: previousViewController)
    }
    
    // MARK: - UIGestureRecognizer
    
    internal func handleTapGesture(recognizer: UITapGestureRecognizer) {
        let tappedMenuView = recognizer.view as! MenuItemView
        guard let tappedPage = menuView.menuItemViews.indexOf(tappedMenuView) where tappedPage != currentPage else { return }
        
        moveToMenuPage(targetPage(tappedPage), animated: true)
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
        // H:|[menuView]|
        menuView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        menuView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        
        switch options.menuPosition {
        case .Top:
            // V:|[menuView]
            menuView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        case .Bottom:
            // V:[menuView]|
            menuView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        }
        
        // V:[menuView(height)]
        menuView.heightAnchor.constraintEqualToConstant(options.menuHeight).active = true
        
        menuView.setNeedsLayout()
        menuView.layoutIfNeeded()
    }
    
    private func setupContentScrollView() {
        contentScrollView.delegate = self
        contentScrollView.scrollEnabled = options.scrollEnabled
        view.addSubview(contentScrollView)
    }
    
    private func layoutContentScrollView() {
        // H:|[contentScrollView]|
        contentScrollView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        contentScrollView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        
        switch options.menuPosition {
        case .Top:
            // V:[menuView][contentScrollView]|
            menuView.bottomAnchor.constraintEqualToAnchor(contentScrollView.topAnchor, constant: 0).active = true
            contentScrollView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        case .Bottom:
            // V:|[contentScrollView][menuView]
            contentScrollView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
            contentScrollView.bottomAnchor.constraintEqualToAnchor(menuView.topAnchor, constant: 0).active = true
        }
    }
    
    private func setupContentView() {
        contentScrollView.addSubview(contentView)
    }
    
    private func layoutContentView() {
        // H:|[contentView]|
        contentView.leadingAnchor.constraintEqualToAnchor(contentScrollView.leadingAnchor).active = true
        contentView.trailingAnchor.constraintEqualToAnchor(contentScrollView.trailingAnchor).active = true
        
        // V:|[contentView(==contentScrollView)]|
        contentView.topAnchor.constraintEqualToAnchor(contentScrollView.topAnchor).active = true
        contentView.bottomAnchor.constraintEqualToAnchor(contentScrollView.bottomAnchor).active = true
        contentView.heightAnchor.constraintEqualToAnchor(contentScrollView.heightAnchor).active = true
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
            
            guard let pagingView = pagingViewController.view else {
                fatalError("\(pagingViewController) doesn't have any view")
            }
            
            pagingView.frame = .zero
            pagingView.translatesAutoresizingMaskIntoConstraints = false

            contentView.addSubview(pagingView)
            addChildViewController(pagingViewController as UIViewController)
            pagingViewController.didMoveToParentViewController(self)
            
            visiblePagingViewControllers.append(pagingViewController)
        }
    }
    
    private func layoutPagingViewControllers() {
        // cleanup
        NSLayoutConstraint.deactivateConstraints(contentView.constraints)
        
        for (index, pagingViewController) in pagingViewControllers.enumerate() {
            if !shouldLoadPage(index) {
                continue
            }
            
            let pagingView = pagingViewController.view
            
            // only one view controller
            if options.menuItemCount == options.minumumSupportedViewCount ||
                options.lazyLoadingPage == .One {
                // H:|[pagingView(==contentScrollView)]|
                pagingView.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor).active = true
                pagingView.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor).active = true
                pagingView.widthAnchor.constraintEqualToAnchor(contentScrollView.widthAnchor).active = true
            } else {
                if case .Infinite = options.menuDisplayMode {
                    if index == currentPage {
                        let previousPagingView = pagingViewControllers[previousIndex].view
                        let nextPagingView = pagingViewControllers[nextIndex].view
                        
                        // H:[previousPagingView][pagingView][nextPagingView]
                        previousPagingView.trailingAnchor.constraintEqualToAnchor(pagingView.leadingAnchor, constant: 0).active = true
                        pagingView.trailingAnchor.constraintEqualToAnchor(nextPagingView.leadingAnchor, constant: 0).active = true
                    } else if index == previousIndex {
                        // "H:|[pagingView]
                        pagingView.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor).active = true
                    } else if index == nextIndex {
                        // H:[pagingView]|
                        pagingView.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor).active = true
                    }
                    // H:[pagingView(==contentScrollView)]
                    pagingView.widthAnchor.constraintEqualToAnchor(contentScrollView.widthAnchor).active = true
                } else {
                    if index == 0 || index == previousIndex {
                        pagingView.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor).active = true
                    } else {
                        let previousPagingView = pagingViewControllers[index - 1].view
                        if index == pagingViewControllers.count - 1 || index == nextIndex {
                            // H:[pagingView]|
                            pagingView.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor).active = true
                        }
                        // H:[previousPagingView][pagingView]
                        previousPagingView.trailingAnchor.constraintEqualToAnchor(pagingView.leadingAnchor, constant: 0).active = true
                    }
                    // H:[pagingView(==contentScrollView)
                    pagingView.widthAnchor.constraintEqualToAnchor(contentScrollView.widthAnchor).active = true
                }
            }
            
            // V:|[pagingView(==contentScrollView)]|
            pagingView.topAnchor.constraintEqualToAnchor(contentView.topAnchor).active = true
            pagingView.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor).active = true
            pagingView.heightAnchor.constraintEqualToAnchor(contentScrollView.heightAnchor).active = true
        }

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        visiblePagingViewControllers.removeAll()
        currentViewController = nil
        
        childViewControllers.forEach {
            $0.willMoveToParentViewController(nil)
            $0.view.removeFromSuperview()
            $0.removeFromParentViewController()
        }
        
        if let menuView = self.menuView {
            menuView.cleanup()
            menuView.removeFromSuperview()
            contentScrollView.removeFromSuperview()
        }
    }
    
    // MARK: - Gesture handler
    
    private func addTapGestureHandlers() {
        menuView.menuItemViews.forEach { $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(PagingMenuController.handleTapGesture(_:)))) }
    }
    
    private func addSwipeGestureHandlersIfNeeded() {
        switch options.menuDisplayMode {
        case .Standard(_, _, .PagingEnabled): break
        case .Standard: return
        case .SegmentedControl: return
        case .Infinite: break
        }
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(PagingMenuController.handleSwipeGesture(_:)))
        leftSwipeGesture.direction = .Left
        menuView.panGestureRecognizer.requireGestureRecognizerToFail(leftSwipeGesture)
        menuView.addGestureRecognizer(leftSwipeGesture)
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(PagingMenuController.handleSwipeGesture(_:)))
        rightSwipeGesture.direction = .Right
        menuView.panGestureRecognizer.requireGestureRecognizerToFail(rightSwipeGesture)
        menuView.addGestureRecognizer(rightSwipeGesture)
    }
    
    // MARK: - Page controller
    
    private func hidePagingViewsIfNeeded(lastPage: Int) {
        if case .Three = options.lazyLoadingPage {
            guard lastPage != previousIndex && lastPage != nextIndex else { return }
        }
        visiblePagingViewControllers.forEach { $0.view.alpha = 0 }
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