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

public class PagingMenuController: UIViewController {
    weak public var delegate: PagingMenuControllerDelegate?
    public private(set) var menuView: MenuView!
    public private(set) var pagingViewController: PagingViewController!
    public var currentPage: Int {
        switch options.menuComponentType {
        case .MenuView: return menuView.currentPage
        default: return pagingViewController.currentPage
        }
    }
    public private(set) var pagingViewControllers = [UIViewController]() {
        willSet {
            options.menuItemCount = newValue.count
            if newValue.flatMap({ $0.menuItemImage }).isEmpty {
                if newValue.flatMap({ $0.menuItemDescription }).isEmpty {
                    options.menuItemViewContent = .Text
                } else {
                    options.menuItemViewContent = .MultilineText
                }
            } else {
                options.menuItemViewContent = .Image
            }

            switch options.menuItemViewContent {
            case .Text: menuItemTitles = newValue.map { $0.title ?? "Menu" }
            case .Image: menuItemImages = newValue.map { $0.menuItemImage ?? UIImage() }
            case .MultilineText:
                multiLineMenuItems = newValue.map { MultilineMenuItem(title: $0.title ?? "Menu", description: $0.menuItemDescription ?? "Description") }
            }
        }
        didSet {
            cleanup()
        }
    }
    
    private var options: PagingMenuOptions!
    private var menuItemTitles: [String] = []
    private var multiLineMenuItems: [MultilineMenuItem] = []
    private var menuItemImages: [UIImage] = []
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
        let pageWidth = pagingViewController.contentScrollView.frame.width
        let order = Int(ceil((pagingViewController.contentScrollView.contentOffset.x - pageWidth / 2) / pageWidth))
        
        if case .Infinite = options.menuDisplayMode {
            return PagingViewPosition(order: order)
        }
        
        // consider left edge menu as center position
        guard pagingViewController.currentPage == 0 && pagingViewController.contentScrollView.contentSize.width < (pageWidth * CGFloat(visiblePagingViewNumber)) else { return PagingViewPosition(order: order) }
        return PagingViewPosition(order: order + 1)
    }
    private let visiblePagingViewNumber: Int = 3
    private let ExceptionName = "PMCException"
    
    // MARK: - Lifecycle
    
    public init(viewControllers: [UIViewController], options: PagingMenuOptions) {
        super.init(nibName: nil, bundle: nil)
        
        setup(viewControllers, options: options)
    }
    
    convenience public init(viewControllers: [UIViewController]) {
        self.init(viewControllers: viewControllers, options: PagingMenuOptions())
    }
    
    public init(menuItemTypes: [MenuItemType], options: PagingMenuOptions) {
        super.init(nibName: nil, bundle: nil)
        
        setup(menuItemTypes, options: options)
    }
    
    convenience public init(menuItemTypes: [MenuItemType]) {
        self.init(menuItemTypes: menuItemTypes, options: PagingMenuOptions())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // fix unnecessary inset for menu view when implemented by programmatically
        menuView?.contentInset.top = 0
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if let menuView = menuView {
            menuView.updateMenuViewConstraints(size: size)
            
            coordinator.animateAlongsideTransition({ [unowned self] (_) -> Void in
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                
                // reset selected menu item view position
                switch self.options.menuDisplayMode {
                case .Standard, .Infinite:
                    self.moveToMenuPage(self.menuView.currentPage, animated: true)
                default: break
                }
                }, completion: nil)
        }
    }
    
    // MARK: - Public
    
    public func setup(viewControllers: [UIViewController], options: PagingMenuOptions) {
        self.options = options
        pagingViewControllers = viewControllers
        
        // validate
        validateDefaultPage()
        validatePageNumbers()
        
        setupMenuView()
        setupMenuController()
        
        moveToMenuPage(pagingViewController.currentPage, animated: false)
    }
    
    private func setupMenuView() {
        switch options.menuComponentType {
        case .MenuController: return
        default: break
        }
        
        constructMenuView()
        layoutMenuView()
    }
    
    private func setupMenuController() {
        switch options.menuComponentType {
        case .MenuView: return
        default: break
        }

        constructPagingViewController()
        layoutPagingViewController()
    }
    
    public func setup(menuItemTypes: [MenuItemType], options: PagingMenuOptions) {
        self.options = options
        options.menuComponentType = .MenuView
        
        if let title = menuItemTypes.first where title is String {
            options.menuItemViewContent = .Text
            menuItemTitles = menuItemTypes.map { $0 as! String }
        } else if let image = menuItemTypes.first where image is UIImage {
            options.menuItemViewContent = .Image
            menuItemImages = menuItemTypes.map { $0 as! UIImage }
        } else if let item = menuItemTypes.first where item is MultilineMenuItem {
            options.menuItemViewContent = .MultilineText
            multiLineMenuItems = menuItemTypes.map { $0 as! MultilineMenuItem }
        }
        
        setupMenuView()
        
        menuView.moveToMenu(menuView.currentPage, animated: false)
    }
    
    public func moveToMenuPage(page: Int, animated: Bool = true) {
        switch options.menuComponentType {
        case .MenuView, .All:
            // ignore an unexpected page number
            guard page < menuView.menuItemCount else { return }
            
            let lastPage = menuView.currentPage
            guard page != lastPage else {
                // place views on appropriate position
                menuView.moveToMenu(page, animated: animated)
                pagingViewController?.positionMenuController()
                return
            }
            
            guard options.menuComponentType == .All else {
                menuView.moveToMenu(page, animated: animated)
                return
            }
        case .MenuController:
            guard page < pagingViewController.controllers.count else { return }
            guard page != pagingViewController.currentPage else { return }
        }
        
        // hide paging views if it's moving to far away
        hidePagingMenuControllers(page)
        
        let previousViewController = pagingViewController.currentViewController
        
        let nextPage = page % options.menuItemCount
        let nextPagingViewController = pagingViewController.controllers[nextPage]
        delegate?.willMoveToPageMenuController?(nextPagingViewController, previousMenuController: previousViewController)
        
        pagingViewController.currentPage = nextPage
        pagingViewController.currentViewController = nextPagingViewController
        menuView?.moveToMenu(page)
        
        let duration = animated ? options.animationDuration : 0
        UIView.animateWithDuration(duration, animations: {
            [unowned self] () -> Void in
            self.pagingViewController.positionMenuController()
            }) { [weak self] (_) -> Void in
                guard let _ = self else { return }
                
                self!.pagingViewController.relayoutPagingViewControllers()
                
                // show paging views
                self!.showPagingMenuControllers()
                
                self!.delegate?.didMoveToPageMenuController?(nextPagingViewController, previousMenuController: previousViewController)
        }
    }
    
    // MARK: - UIGestureRecognizer
    
    internal func handleTapGesture(recognizer: UITapGestureRecognizer) {
        guard let menuItemView = recognizer.view as? MenuItemView else { return }
        guard let page = menuView.menuItemViews.indexOf(menuItemView) where page != menuView.currentPage else { return }
        
        let newPage: Int
        switch self.options.menuDisplayMode {
        case .Standard(_, _, .PagingEnabled):
            newPage = page < self.menuView.currentPage ? self.menuView.currentPage - 1 : self.menuView.currentPage + 1
        case .Infinite(_, .PagingEnabled):
            if menuItemView.frame.midX > menuView.currentMenuItemView.frame.midX {
                newPage = menuView.nextPage
            } else {
                newPage = menuView.previousPage
            }
        case .Infinite: fallthrough
        default:
            newPage = page
        }
        
        moveToMenuPage(newPage)
    }
    
    internal func handleSwipeGesture(recognizer: UISwipeGestureRecognizer) {
        guard let menuView = recognizer.view as? MenuView else { return }
        
        let newPage: Int
        switch (recognizer.direction, options.menuDisplayMode) {
        case (UISwipeGestureRecognizerDirection.Left, .Infinite):
            newPage = menuView.nextPage
        case (UISwipeGestureRecognizerDirection.Left, _):
            newPage = min(nextIndex, options.menuItemCount - 1)
        case (UISwipeGestureRecognizerDirection.Right, .Infinite):
            newPage = menuView.previousPage
        case (UISwipeGestureRecognizerDirection.Right, _):
            newPage = max(previousIndex, 0)
        default: return
        }
        
        moveToMenuPage(newPage)
    }
    
    // MARK: - Constructor
    
    private func constructMenuView() {
        switch options.menuComponentType {
        case .MenuController: return
        default: break
        }
        
        switch options.menuItemViewContent {
        case .Text: menuView = MenuView(menuItemTypes: menuItemTitles, options: options)
        case .Image: menuView = MenuView(menuItemTypes: menuItemImages, options: options)
        case .MultilineText: menuView = MenuView(menuItemTypes: multiLineMenuItems, options: options)
        }
        
        menuView.delegate = self
        view.addSubview(menuView)
        
        addTapGestureHandlers()
        addSwipeGestureHandlersIfNeeded()
    }
    
    private func layoutMenuView() {
        let viewsDictionary = ["menuView": menuView]
        
        let verticalConstraints: [NSLayoutConstraint]
        switch options.menuComponentType {
        case .All:
            switch options.menuPosition {
            case .Top:
                verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[menuView]", options: [], metrics: nil, views: viewsDictionary)
            case .Bottom:
                verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView]|", options: [], metrics: nil, views: viewsDictionary)
            }
        case .MenuView:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[menuView]", options: [], metrics: nil, views: viewsDictionary)
        default: return
        }
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[menuView]|", options: [], metrics: nil, views: viewsDictionary)
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        
        menuView.setNeedsLayout()
        menuView.layoutIfNeeded()
    }

    private func constructPagingViewController() {
        pagingViewController = PagingViewController(viewControllers: pagingViewControllers, options: options)
        pagingViewController.contentScrollView.delegate = self

        view.addSubview(pagingViewController.view)
        addChildViewController(pagingViewController)
        pagingViewController.didMoveToParentViewController(self)
    }

    private func layoutPagingViewController() {
        let viewsDictionary: [String: UIView]
        switch options.menuComponentType {
        case .MenuController:
            viewsDictionary = ["pagingView": pagingViewController.view]
        default:
            viewsDictionary = ["menuView": menuView, "pagingView": pagingViewController.view]
        }

        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[pagingView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints: [NSLayoutConstraint]
        switch (options.menuComponentType, options.menuPosition) {
        case (.MenuController, _):
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pagingView]|", options: [], metrics: nil, views: viewsDictionary)
        case (_, .Top):
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView][pagingView]|", options: [], metrics: nil, views: viewsDictionary)
        case (_, .Bottom):
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pagingView][menuView]", options: [], metrics: nil, views: viewsDictionary)
        }

        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        if let menuView = self.menuView {
            menuView.cleanup()
            menuView.removeFromSuperview()
        }
        if let pagingViewController = self.pagingViewController {
            pagingViewController.cleanup()
            pagingViewController.view.removeFromSuperview()
            pagingViewController.removeFromParentViewController()
            pagingViewController.willMoveToParentViewController(nil)
        }
    }
    
    // MARK: - Private
    
    private func updateCurrentPage(page: Int) {
        menuView?.currentPage = page
        pagingViewController?.currentPage = page
    }
    
    private func hidePagingMenuControllers(page: Int) {
        switch (options.lazyLoadingPage, options.menuDisplayMode, page) {
        case (.Three, .Infinite, menuView?.previousPage ?? previousIndex),
             (.Three, .Infinite, menuView?.nextPage ?? nextIndex),
             (.Three, _, previousIndex),
             (.Three, _, nextIndex): break
        default: pagingViewController.visibleControllers.forEach { $0.view.alpha = 0 }
        }
    }
    
    private func showPagingMenuControllers() {
        pagingViewController.visibleControllers.forEach { $0.view.alpha = 1 }
    }
    
    // MARK: - Gesture handler
    
    private func addTapGestureHandlers() {
        menuView.menuItemViews.forEach {
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PagingMenuController.handleTapGesture(_:)))
            gestureRecognizer.numberOfTapsRequired = 1
            $0.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    private func addSwipeGestureHandlersIfNeeded() {
        switch options.menuDisplayMode {
        case .Standard(_, _, .PagingEnabled): break
        case .Infinite(_, .PagingEnabled): break
        default: return
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

extension PagingMenuController: UIScrollViewDelegate {
    private var nextPageFromCurrentPosition: Int {
        // set new page number according to current moving direction
        let nextPage: Int
        switch currentPagingViewPosition {
        case .Left:
            nextPage = options.menuComponentType == .MenuController ? previousIndex : menuView.previousPage
        case .Right:
            nextPage = options.menuComponentType == .MenuController ? nextIndex : menuView.nextPage
        default: nextPage = pagingViewController.currentPage
        }
        return nextPage
    }
    
    private var nextPageFromCurrentPoint: Int {
        let point = CGPointMake(menuView.contentOffset.x + menuView.frame.width / 2, 0)
        for (index, menuItemView) in menuView.menuItemViews.enumerate() {
            guard CGRectContainsPoint(menuItemView.frame, point) else { continue }
            return index
        }
        return menuView.currentPage
    }
    
    // MARK: - UIScrollViewDelegate
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let nextPage: Int
        switch scrollView {
        case let scrollView where scrollView.isEqual(pagingViewController.contentScrollView):
            nextPage = nextPageFromCurrentPosition
        case let scrollView where scrollView.isEqual(menuView):
            nextPage = nextPageFromCurrentPoint
        default: return
        }
        
        moveToMenuPage(nextPage)
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        switch (scrollView, decelerate) {
        case (let scrollView, false) where scrollView.isEqual(menuView): break
        default: return
        }
        
        let nextPage = nextPageFromCurrentPoint
        moveToMenuPage(nextPage)
    }
}