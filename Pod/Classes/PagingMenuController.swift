//
//  PagingMenuController.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 3/18/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

public protocol PagingMenuControllerDelegate: class {
    func willMove(toMenu menuController: UIViewController, fromMenu previousMenuController: UIViewController)
    func didMove(toMenu menuController: UIViewController, fromMenu previousMenuController: UIViewController)
    func willMove(toMenuItem menuItemView: MenuItemView, fromMenuItem previousMenuItemView: MenuItemView)
    func didMove(toMenuItem menuItemView: MenuItemView, fromMenuItem previousMenuItemView: MenuItemView)
}

public extension PagingMenuControllerDelegate {
    func willMove(toMenu menuController: UIViewController, fromMenu previousMenuController: UIViewController) {}
    func didMove(toMenu menuController: UIViewController, fromMenu previousMenuController: UIViewController) {}
    func willMove(toMenuItem menuItemView: MenuItemView, fromMenuItem previousMenuItemView: MenuItemView) {}
    func didMove(toMenuItem menuItemView: MenuItemView, fromMenuItem previousMenuItemView: MenuItemView) {}
}

internal let MinimumSupportedViewCount = 1
internal let VisiblePagingViewNumber = 3

open class PagingMenuController: UIViewController, PagingValidator {
    weak open var delegate: PagingMenuControllerDelegate?
    open fileprivate(set) var menuView: MenuView? {
        didSet {
            guard let menuView = menuView else { return }
            
            menuView.delegate = self
            menuView.viewDelegate = delegate
            menuView.update(currentPage: options.defaultPage)
            view.addSubview(menuView)
        }
    }
    open fileprivate(set) var pagingViewController: PagingViewController? {
        didSet {
            guard let pagingViewController = pagingViewController else { return }
            
            pagingViewController.contentScrollView.delegate = self
            view.addSubview(pagingViewController.view)
            addChildViewController(pagingViewController)
            pagingViewController.didMove(toParentViewController: self)
        }
    }
    
    fileprivate var options: PagingMenuControllerCustomizable! {
        didSet {
            cleanup()
            
            validate(options)
        }
    }
    fileprivate var menuOptions: MenuViewCustomizable?
    
    // MARK: - Lifecycle
    
    public init(options: PagingMenuControllerCustomizable) {
        super.init(nibName: nil, bundle: nil)
        
        setup(options)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // fix unnecessary inset for menu view when implemented by programmatically
        menuView?.contentInset.top = 0
    }
    
    override open func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let menuView = menuView, let menuOptions = menuOptions {
            menuView.updateMenuViewConstraints(size)
            
            coordinator.animate(alongsideTransition: { [unowned self] (_) -> Void in
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                
                // reset selected menu item view position
                switch menuOptions.displayMode {
                case .standard, .infinite:
                    self.move(toPage: menuView.currentPage)
                default: break
                }
                }, completion: nil)
        }
    }
    
    // MARK: - Public
    
    open func setup(_ options: PagingMenuControllerCustomizable) {
        self.options = options
        
        switch options.componentType {
        case .all(let menuOptions, _): self.menuOptions = menuOptions
        case .menuView(let menuOptions): self.menuOptions = menuOptions
        default: break
        }
        
        setupMenuView()
        setupMenuController()
        
        move(toPage: currentPage, animated: false)
    }
    
    fileprivate func setupMenuView() {
        switch options.componentType {
        case .pagingController: return
        default: break
        }
        
        constructMenuView()
        layoutMenuView()
    }
    
    fileprivate func setupMenuController() {
        switch options.componentType {
        case .menuView: return
        default: break
        }
        
        constructPagingViewController()
        layoutPagingViewController()
    }
    
    open func move(toPage page: Int, animated: Bool = true) {
        switch options.componentType {
        case .menuView, .all:
            // ignore an unexpected page number
            guard let menuView = menuView , page < menuView.menuItemCount else { return }
            
            let lastPage = menuView.currentPage
            guard page != lastPage else {
                // place views on appropriate position
                menuView.move(toPage: page, animated: animated)
                pagingViewController?.positionMenuController()
                return
            }
            
            switch options.componentType {
            case .all: break
            default:
                menuView.move(toPage: page, animated: animated)
                return
            }
        case .pagingController:
            guard let pagingViewController = pagingViewController , page < pagingViewController.controllers.count else { return }
            guard page != pagingViewController.currentPage else { return }
        }
        
        guard let pagingViewController = pagingViewController,
            let previousPagingViewController = pagingViewController.currentViewController else { return }
        
        // hide paging views if it's moving to far away
        hidePagingMenuControllers(page)
        
        let nextPage = page % pagingViewController.controllers.count
        let nextPagingViewController = pagingViewController.controllers[nextPage]
        delegate?.willMove(toMenu: nextPagingViewController, fromMenu: previousPagingViewController)
        menuView?.move(toPage: page)
        
        pagingViewController.update(currentPage: nextPage)
        pagingViewController.currentViewController = nextPagingViewController
        
        let duration = animated ? options.animationDuration : 0
        UIView.animate(withDuration: duration, animations: {
            () -> Void in
            pagingViewController.positionMenuController()
            }) { [weak self] (_) -> Void in
                pagingViewController.relayoutPagingViewControllers()
                
                // show paging views
                self?.showPagingMenuControllers()
                
                self?.delegate?.didMove(toMenu: nextPagingViewController, fromMenu: previousPagingViewController)
        }
    }
    
    // MARK: - Constructor
    
    fileprivate func constructMenuView() {
        guard let menuOptions = self.menuOptions else { return }
        
        menuView = MenuView(menuOptions: menuOptions)
        
        addTapGestureHandler()
        addSwipeGestureHandler()
    }
    
    fileprivate func layoutMenuView() {
        guard let menuView = menuView else { return }
        let viewsDictionary = ["menuView": menuView]
        
        let verticalConstraints: [NSLayoutConstraint]
        switch options.componentType {
        case .all(let menuOptions, _):
            switch menuOptions.menuPosition {
            case .top:
                verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[menuView]", options: [], metrics: nil, views: viewsDictionary)
            case .bottom:
                verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[menuView]|", options: [], metrics: nil, views: viewsDictionary)
            }
        case .menuView:
            verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[menuView]", options: [], metrics: nil, views: viewsDictionary)
        default: return
        }
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[menuView]|", options: [], metrics: nil, views: viewsDictionary)
        NSLayoutConstraint.activate(horizontalConstraints + verticalConstraints)
        
        menuView.setNeedsLayout()
        menuView.layoutIfNeeded()
    }

    fileprivate func constructPagingViewController() {
        let viewControllers: [UIViewController]
        switch options.componentType {
        case .pagingController(let pagingControllers): viewControllers = pagingControllers
        case .all(_, let pagingControllers): viewControllers = pagingControllers
        default: return
        }
        
        pagingViewController = PagingViewController(viewControllers: viewControllers, options: options)
    }

    fileprivate func layoutPagingViewController() {
        guard let pagingViewController = pagingViewController else { return }
        let viewsDictionary: [String: UIView]
        switch options.componentType {
        case .pagingController:
            viewsDictionary = ["pagingView": pagingViewController.view]
        default:
            guard let menuView = menuView else { return }
            viewsDictionary = ["menuView": menuView, "pagingView": pagingViewController.view]
        }

        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[pagingView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints: [NSLayoutConstraint]
        switch (options.componentType) {
        case .pagingController:
            verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[pagingView]|", options: [], metrics: nil, views: viewsDictionary)
        case .all(let menuOptions, _):
            switch menuOptions.menuPosition {
            case .top:
                verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[menuView][pagingView]|", options: [], metrics: nil, views: viewsDictionary)
            case .bottom:
                verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[pagingView][menuView]", options: [], metrics: nil, views: viewsDictionary)
            }
        default: return
        }

        NSLayoutConstraint.activate(horizontalConstraints + verticalConstraints)
    }
    
    // MARK: - Private
    
    fileprivate func hidePagingMenuControllers(_ page: Int) {
        guard let menuOptions = menuOptions else { return }
        
        switch (options.lazyLoadingPage, menuOptions.displayMode, page) {
        case (.three, .infinite, menuView?.previousPage ?? previousPage),
             (.three, .infinite, menuView?.nextPage ?? nextPage): break
        case (.three, .infinite, _): pagingViewController?.visibleControllers.forEach { $0.view.alpha = 0 }
        default: break
        }
    }
    
    fileprivate func showPagingMenuControllers() {
        pagingViewController?.visibleControllers.forEach { $0.view.alpha = 1 }
    }
}

extension PagingMenuController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let nextPage: Int
        switch (scrollView, pagingViewController, menuView) {
        case let (scrollView, pagingViewController?, _) where scrollView.isEqual(pagingViewController.contentScrollView):
            nextPage = nextPageFromCurrentPosition
        case let (scrollView, _, menuView?) where scrollView.isEqual(menuView):
            nextPage = nextPageFromCurrentPoint
        default: return
        }
        
        move(toPage: nextPage)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        switch (scrollView, decelerate) {
        case (let scrollView, false) where scrollView.isEqual(menuView): break
        default: return
        }
        
        let nextPage = nextPageFromCurrentPoint
        move(toPage: nextPage)
    }
}

extension PagingMenuController: Pagable {
    public var currentPage: Int {
        switch options.componentType {
        case .menuView:
            guard let menuView = menuView else { return 0 }
            return menuView.currentPage
        default:
            guard let pagingViewController = pagingViewController else { return 0 }
            return pagingViewController.currentPage
        }
    }
    var previousPage: Int {
        guard let menuOptions = menuOptions,
            case .infinite = menuOptions.displayMode,
            let controllers = pagingViewController?.controllers else { return currentPage - 1 }
        
        return currentPage - 1 < 0 ? controllers.count - 1 : currentPage - 1
    }
    var nextPage: Int {
        guard let menuOptions = menuOptions,
            case .infinite = menuOptions.displayMode,
            let controllers = pagingViewController?.controllers else { return currentPage + 1 }
        
        return currentPage + 1 > controllers.count - 1 ? 0 : currentPage + 1
    }
}

extension PagingMenuController: PageDetectable {
    var currentPagingViewPosition: PagingViewPosition {
        guard let pagingViewController = pagingViewController else { return .unknown }
        let pageWidth = pagingViewController.contentScrollView.frame.width
        let order = Int(ceil((pagingViewController.contentScrollView.contentOffset.x - pageWidth / 2) / pageWidth))
        
        if let menuOptions = menuOptions,
            case .infinite = menuOptions.displayMode {
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
        case (.left, .pagingController): page = previousPage
        case (.left, _): page = menuView?.previousPage ?? previousPage
        case (.right, .pagingController): page = nextPage
        case (.right, _): page = menuView?.nextPage ?? nextPage
        default: page = pagingViewController?.currentPage ?? currentPage
        }
        
        return page
    }
    
    var nextPageFromCurrentPoint: Int {
        guard let menuView = menuView else { return 0 }
        
        let point = CGPoint(x: menuView.contentOffset.x + menuView.frame.width / 2, y: 0)
        for (index, menuItemView) in menuView.menuItemViews.enumerated() {
            guard menuItemView.frame.contains(point) else { continue }
            return index
        }
        return menuView.currentPage
    }
}

extension PagingMenuController: GestureHandler {
    func addTapGestureHandler() {
        menuView?.menuItemViews.forEach {
            $0.addGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    func addSwipeGestureHandler() {
        guard let menuOptions = menuOptions else { return }
        
        switch menuOptions.displayMode {
        case .standard(_, _, .pagingEnabled): break
        case .infinite(_, .pagingEnabled): break
        default: return
        }
        
        menuView?.panGestureRecognizer.require(toFail: leftSwipeGestureRecognizer)
        menuView?.addGestureRecognizer(leftSwipeGestureRecognizer)
        menuView?.panGestureRecognizer.require(toFail: rightSwipeGestureRecognizer)
        menuView?.addGestureRecognizer(rightSwipeGestureRecognizer)
    }
    
    internal func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
        guard let menuItemView = recognizer.view as? MenuItemView,
            let menuView = menuView,
            let page = menuView.menuItemViews.index(of: menuItemView),
            page != menuView.currentPage,
            let menuOptions = menuOptions else { return }
        
        let newPage: Int
        switch menuOptions.displayMode {
        case .standard(_, _, .pagingEnabled):
            newPage = page < currentPage ? menuView.currentPage - 1 : menuView.currentPage + 1
        case .infinite(_, .pagingEnabled):
            if menuItemView.frame.midX > menuView.currentMenuItemView.frame.midX {
                newPage = menuView.nextPage
            } else {
                newPage = menuView.previousPage
            }
        case .infinite: fallthrough
        default:
            newPage = page
        }
        
        move(toPage: newPage)
    }
    
    internal func handleSwipeGesture(_ recognizer: UISwipeGestureRecognizer) {
        guard let menuView = recognizer.view as? MenuView,
            let menuOptions = menuOptions else { return }
        
        let newPage: Int
        switch (recognizer.direction, menuOptions.displayMode) {
        case (UISwipeGestureRecognizerDirection.left, .infinite):
            newPage = menuView.nextPage
        case (UISwipeGestureRecognizerDirection.left, _):
            newPage = min(nextPage, menuOptions.itemsOptions.count - 1)
        case (UISwipeGestureRecognizerDirection.right, .infinite):
            newPage = menuView.previousPage
        case (UISwipeGestureRecognizerDirection.right, _):
            newPage = max(previousPage, 0)
        default: return
        }
        
        move(toPage: newPage)
    }
}

extension PagingMenuController: ViewCleanable {
    func cleanup() {
        if let menuView = self.menuView {
            menuView.cleanup()
            menuView.removeFromSuperview()
        }
        if let pagingViewController = self.pagingViewController {
            pagingViewController.cleanup()
            pagingViewController.view.removeFromSuperview()
            pagingViewController.removeFromParentViewController()
            pagingViewController.willMove(toParentViewController: nil)
        }
    }
}
