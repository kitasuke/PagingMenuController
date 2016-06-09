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
    optional func willMoveToMenuItemView(menuItemView: MenuItemView, previousMenuItemView: MenuItemView)
    optional func didMoveToMenuItemView(menuItemView: MenuItemView, previousMenuItemView: MenuItemView)
}

internal let MinimumSupportedViewCount = 1
internal let VisiblePagingViewNumber: Int = 3

public class PagingMenuController: UIViewController, PagingValidator {
    weak public var delegate: PagingMenuControllerDelegate?
    public private(set) var menuView: MenuView!
    public private(set) var pagingViewController: PagingViewController!
    
    private var options: PagingMenuControllerCustomizable! {
        didSet {
            cleanup()
        }
    }
    private var menuOptions: MenuViewCustomizable?
    
    // MARK: - Lifecycle
    
    public init(options: PagingMenuControllerCustomizable) {
        super.init(nibName: nil, bundle: nil)
        
        setup(options)
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
        
        if let menuView = menuView, let menuOptions = menuOptions {
            menuView.updateMenuViewConstraints(size: size)
            
            coordinator.animateAlongsideTransition({ [unowned self] (_) -> Void in
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                
                // reset selected menu item view position
                switch menuOptions.mode {
                case .Standard, .Infinite:
                    self.moveToMenuPage(self.menuView.currentPage, animated: true)
                default: break
                }
                }, completion: nil)
        }
    }
    
    // MARK: - Public
    
    public func setup(options: PagingMenuControllerCustomizable) {
        self.options = options
        
        switch options.componentType {
        case .All(let menuOptions, _): self.menuOptions = menuOptions
        case .MenuView(let menuOptions): self.menuOptions = menuOptions
        default: break
        }
        
        // validate
        validate(options)
        
        setupMenuView()
        setupMenuController()
        
        moveToMenuPage(currentPage, animated: false)
    }
    
    private func setupMenuView() {
        switch options.componentType {
        case .PagingController: return
        default: break
        }
        
        constructMenuView()
        layoutMenuView()
    }
    
    private func setupMenuController() {
        switch options.componentType {
        case .MenuView: return
        default: break
        }

        constructPagingViewController()
        layoutPagingViewController()
    }
    
    public func moveToMenuPage(page: Int, animated: Bool = true) {
        switch options.componentType {
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
            
            switch options.componentType {
            case .All: break
            default:
                menuView.moveToMenu(page, animated: animated)
                return
            }
        case .PagingController:
            guard page < pagingViewController.controllers.count else { return }
            guard page != pagingViewController.currentPage else { return }
        }
        
        // hide paging views if it's moving to far away
        hidePagingMenuControllers(page)
        
        let previousViewController = pagingViewController.currentViewController
        
        let nextPage = page % pagingViewController.controllers.count
        let nextPagingViewController = pagingViewController.controllers[nextPage]
        delegate?.willMoveToPageMenuController?(nextPagingViewController, previousMenuController: previousViewController)
        menuView?.moveToMenu(page)
        
        pagingViewController.currentPage = nextPage
        pagingViewController.currentViewController = nextPagingViewController
        
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
    
    // MARK: - Constructor
    
    private func constructMenuView() {
        guard let menuOptions = self.menuOptions else { return }
        
        menuView = MenuView(menuOptions: menuOptions)
        menuView.delegate = self
        menuView.viewDelegate = delegate
        view.addSubview(menuView)
        
        addTapGestureHandler()
        addSwipeGestureHandler()
    }
    
    private func layoutMenuView() {
        let viewsDictionary = ["menuView": menuView]
        
        let verticalConstraints: [NSLayoutConstraint]
        switch options.componentType {
        case .All(let menuOptions, _):
            switch menuOptions.menuPosition {
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
        let viewControllers: [UIViewController]
        switch options.componentType {
        case .PagingController(let pagingControllers): viewControllers = pagingControllers
        case .All(_, let pagingControllers): viewControllers = pagingControllers
        default: return
        }
        
        pagingViewController = PagingViewController(viewControllers: viewControllers, options: options)
        pagingViewController.contentScrollView.delegate = self

        view.addSubview(pagingViewController.view)
        addChildViewController(pagingViewController)
        pagingViewController.didMoveToParentViewController(self)
    }

    private func layoutPagingViewController() {
        let viewsDictionary: [String: UIView]
        switch options.componentType {
        case .PagingController:
            viewsDictionary = ["pagingView": pagingViewController.view]
        default:
            viewsDictionary = ["menuView": menuView, "pagingView": pagingViewController.view]
        }

        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[pagingView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints: [NSLayoutConstraint]
        switch (options.componentType) {
        case .PagingController:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pagingView]|", options: [], metrics: nil, views: viewsDictionary)
        case .All(let menuOptions, _):
            switch menuOptions.menuPosition {
            case .Top:
                verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView][pagingView]|", options: [], metrics: nil, views: viewsDictionary)
            case .Bottom:
                verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pagingView][menuView]", options: [], metrics: nil, views: viewsDictionary)
            }
        default: return
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
        guard let menuOptions = menuOptions else { return }
        
        switch (options.lazyLoadingPage, menuOptions.mode, page) {
        case (.Three, .Infinite, menuView?.previousPage ?? previousPage),
             (.Three, .Infinite, menuView?.nextPage ?? nextPage),
             (.Three, _, previousPage),
             (.Three, _, nextPage): break
        default: pagingViewController.visibleControllers.forEach { $0.view.alpha = 0 }
        }
    }
    
    private func showPagingMenuControllers() {
        pagingViewController.visibleControllers.forEach { $0.view.alpha = 1 }
    }
}

extension PagingMenuController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let nextPage: Int
        switch (scrollView, pagingViewController, menuView) {
        case let (scrollView, pagingViewController?, _) where scrollView.isEqual(pagingViewController.contentScrollView):
            nextPage = nextPageFromCurrentPosition
        case let (scrollView, _, menuView?) where scrollView.isEqual(menuView):
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

extension PagingMenuController: Pagable {
    public var currentPage: Int {
        switch options.componentType {
        case .MenuView: return menuView.currentPage
        default: return pagingViewController.currentPage
        }
    }
    
    var previousPage: Int {
        guard let menuOptions = menuOptions,
            case .Infinite = menuOptions.mode,
            let controllers = pagingViewController?.controllers else { return currentPage - 1 }
        
        return currentPage - 1 < 0 ? controllers.count - 1 : currentPage - 1
    }
    var nextPage: Int {
        guard let menuOptions = menuOptions,
            case .Infinite = menuOptions.mode,
            let controllers = pagingViewController?.controllers else { return currentPage + 1 }
        
        return currentPage + 1 > controllers.count - 1 ? 0 : currentPage + 1
    }
}

extension PagingMenuController: PageDetectable {
    var currentPagingViewPosition: PagingViewPosition {
        let pageWidth = pagingViewController.contentScrollView.frame.width
        let order = Int(ceil((pagingViewController.contentScrollView.contentOffset.x - pageWidth / 2) / pageWidth))
        
        if let menuOptions = menuOptions,
            case .Infinite = menuOptions.mode {
            return PagingViewPosition(order: order)
        }
        
        // consider left edge menu as center position
        guard pagingViewController.currentPage == 0 && pagingViewController.contentScrollView.contentSize.width < (pageWidth * CGFloat(VisiblePagingViewNumber)) else { return PagingViewPosition(order: order) }
        return PagingViewPosition(order: order + 1)
    }
    
    var nextPageFromCurrentPosition: Int {
        // set new page number according to current moving direction
        let page: Int
        switch (currentPagingViewPosition, options.componentType) {
        case (.Left, .PagingController): page = previousPage
        case (.Left, _): page = menuView.previousPage
        case (.Right, .PagingController): page = nextPage
        case (.Right, _): page = menuView.nextPage
        default: page = pagingViewController.currentPage
        }
        
        return page
    }
    
    var nextPageFromCurrentPoint: Int {
        let point = CGPointMake(menuView.contentOffset.x + menuView.frame.width / 2, 0)
        for (index, menuItemView) in menuView.menuItemViews.enumerate() {
            guard CGRectContainsPoint(menuItemView.frame, point) else { continue }
            return index
        }
        return menuView.currentPage
    }
}

extension PagingMenuController: GestureHandler {
    func addTapGestureHandler() {
        menuView.menuItemViews.forEach {
            $0.addGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    func addSwipeGestureHandler() {
        guard let menuOptions = menuOptions else { return }
        
        switch menuOptions.mode {
        case .Standard(_, _, .PagingEnabled): break
        case .Infinite(_, .PagingEnabled): break
        default: return
        }
        
        menuView.panGestureRecognizer.requireGestureRecognizerToFail(leftSwipeGestureRecognizer)
        menuView.addGestureRecognizer(leftSwipeGestureRecognizer)
        menuView.panGestureRecognizer.requireGestureRecognizerToFail(rightSwipeGestureRecognizer)
        menuView.addGestureRecognizer(rightSwipeGestureRecognizer)
    }
    
    internal func handleTapGesture(recognizer: UITapGestureRecognizer) {
        guard let menuItemView = recognizer.view as? MenuItemView,
            let page = menuView.menuItemViews.indexOf(menuItemView) where page != menuView.currentPage,
            let menuOptions = menuOptions else { return }
        
        let newPage: Int
        switch menuOptions.mode {
        case .Standard(_, _, .PagingEnabled):
            newPage = page < currentPage ? menuView.currentPage - 1 : menuView.currentPage + 1
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
        guard let menuView = recognizer.view as? MenuView,
            let menuOptions = menuOptions else { return }
        
        let newPage: Int
        switch (recognizer.direction, menuOptions.mode) {
        case (UISwipeGestureRecognizerDirection.Left, .Infinite):
            newPage = menuView.nextPage
        case (UISwipeGestureRecognizerDirection.Left, _):
            newPage = min(nextPage, menuOptions.itemsOptions.count - 1)
        case (UISwipeGestureRecognizerDirection.Right, .Infinite):
            newPage = menuView.previousPage
        case (UISwipeGestureRecognizerDirection.Right, _):
            newPage = max(previousPage, 0)
        default: return
        }
        
        moveToMenuPage(newPage)
    }
}