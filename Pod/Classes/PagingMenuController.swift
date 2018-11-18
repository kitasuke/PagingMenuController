//
//  PagingMenuController.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 3/18/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

@available(*, unavailable, message: "Please use `onMove` property instead")
public protocol PagingMenuControllerDelegate: class {}

public enum MenuMoveState {
    case willMoveController(to: UIViewController, from: UIViewController)
    case didMoveController(to: UIViewController, from: UIViewController)
    case willMoveItem(to: MenuItemView, from: MenuItemView)
    case didMoveItem(to: MenuItemView, from: MenuItemView)
    case didScrollStart
    case didScrollEnd
}

internal let MinimumSupportedViewCount = 1
internal let VisiblePagingViewNumber = 3

open class PagingMenuController: UIViewController {
    public fileprivate(set) var menuView: MenuView? {
        didSet {
            guard let menuView = menuView else { return }
            
            menuView.delegate = self
            menuView.onMove = onMove
            menuView.update(currentPage: options.defaultPage)
            view.addSubview(menuView)
        }
    }
    public fileprivate(set) var pagingViewController: PagingViewController? {
        didSet {
            guard let pagingViewController = pagingViewController else { return }
            
            pagingViewController.contentScrollView.delegate = self
            view.addSubview(pagingViewController.view)
            addChild(pagingViewController)
            pagingViewController.didMove(toParent: self)
        }
    }
    public var onMove: ((MenuMoveState) -> Void)? {
        didSet {
            guard let menuView = menuView else { return }
            
            menuView.onMove = onMove
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
        case .all(let menuOptions, _):
            self.menuOptions = menuOptions
        case .menuView(let menuOptions):
            self.menuOptions = menuOptions
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
        onMove?(.willMoveController(to: nextPagingViewController, from: previousPagingViewController))
        menuView?.move(toPage: page)
        
        pagingViewController.update(currentPage: nextPage)
        pagingViewController.currentViewController = nextPagingViewController
        
        let duration = animated ? options.animationDuration : 0
        let animationClosure = {
            pagingViewController.positionMenuController()
        }
        let completionClosure = { [weak self] (_: Bool) -> Void in
            pagingViewController.relayoutPagingViewControllers()

            // show paging views
            self?.showPagingMenuControllers()

            self?.onMove?(.didMoveController(to: nextPagingViewController, from: previousPagingViewController))
        }
        if duration > 0 {
            UIView.animate(withDuration: duration, animations: animationClosure, completion: completionClosure)
        } else {
            animationClosure()
            completionClosure(true)
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
        
        let height: CGFloat
        switch options.componentType {
        case .all(let menuOptions, _):
            height = menuOptions.height
            switch menuOptions.menuPosition {
            case .top:
                // V:|[menuView]
                menuView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
            case .bottom:
                // V:[menuView]|
                menuView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            }
        case .menuView(let menuOptions):
            height = menuOptions.height
            // V:|[menuView]
            menuView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        default: return
        }
        
        // H:|[menuView]|
        // V:[menuView(height)]
        NSLayoutConstraint.activate([
            menuView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            menuView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            menuView.heightAnchor.constraint(equalToConstant: height)
            ])
        
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
        
        // H:|[pagingView]|
        NSLayoutConstraint.activate([
            pagingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pagingViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        
        switch options.componentType {
        case .pagingController:
            // V:|[pagingView]|
            NSLayoutConstraint.activate([
                pagingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                ])
        case .all(let menuOptions, _):
            guard let menuView = menuView else { return }
            
            switch menuOptions.menuPosition {
            case .top:
                // V:[menuView][pagingView]|
                NSLayoutConstraint.activate([
                    menuView.bottomAnchor.constraint(equalTo: pagingViewController.view.topAnchor, constant: 0),
                    pagingViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                    ])
            case .bottom:
                // V:|[pagingView][menuView]
                NSLayoutConstraint.activate([
                    pagingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
                    pagingViewController.view.bottomAnchor.constraint(equalTo: menuView.topAnchor, constant: 0),
                    ])
            }
        default: return
        }
    }
    
    // MARK: - Private
    
    fileprivate func hidePagingMenuControllers(_ page: Int) {
        guard let menuOptions = menuOptions else { return }
        
        switch (options.lazyLoadingPage, menuOptions.displayMode, page) {
        case (.three, .infinite, menuView?.previousPage ?? previousPage),
             (.three, .infinite, menuView?.nextPage ?? nextPage): break
        case (.three, .infinite, _):
            pagingViewController?.visibleControllers.forEach { $0.view.alpha = 0 }
        default: break
        }
    }
    
    fileprivate func showPagingMenuControllers() {
        pagingViewController?.visibleControllers.forEach { $0.view.alpha = 1 }
    }
}

extension PagingMenuController: UIScrollViewDelegate {
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        onMove?(.didScrollEnd)
        
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

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        onMove?(.didScrollStart)
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
        switch (menuView, pagingViewController) {
        case (let menuView?, _):
            return menuView.currentPage
        case (_, let pagingViewController?):
            return pagingViewController.currentPage
        default:
            return 0
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

// MARK: Page Control

extension PagingMenuController {
    fileprivate enum PagingViewPosition {
        case left, center, right, unknown
        
        init(order: Int) {
            switch order {
            case 0: self = .left
            case 1: self = .center
            case 2: self = .right
            default: self = .unknown
            }
        }
    }
    
    fileprivate var currentPagingViewPosition: PagingViewPosition {
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
    
    fileprivate var nextPageFromCurrentPosition: Int {
        // set new page number according to current moving direction
        let page: Int
        switch options.lazyLoadingPage {
        case .all:
            guard let scrollView = pagingViewController?.contentScrollView else { return currentPage }
            page = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        default:
            switch (currentPagingViewPosition, options.componentType) {
            case (.left, .pagingController):
                page = previousPage
            case (.left, _):
                page = menuView?.previousPage ?? previousPage
            case (.right, .pagingController):
                page = nextPage
            case (.right, _):
                page = menuView?.nextPage ?? nextPage
            default:
                page = currentPage
            }
        }
        
        return page
    }
    
    fileprivate var nextPageFromCurrentPoint: Int {
        guard let menuView = menuView else { return 0 }
        
        let point = CGPoint(x: menuView.contentOffset.x + menuView.frame.width / 2, y: 0)
        for (index, menuItemView) in menuView.menuItemViews.enumerated() {
            guard menuItemView.frame.contains(point) else { continue }
            return index
        }
        return menuView.currentPage
    }
}

// MARK: - GestureRecognizer

extension PagingMenuController {
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        gestureRecognizer.numberOfTapsRequired = 1
        return gestureRecognizer
    }
    
    fileprivate var leftSwipeGestureRecognizer: UISwipeGestureRecognizer {
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        gestureRecognizer.direction = .left
        return gestureRecognizer
    }
    
    fileprivate var rightSwipeGestureRecognizer: UISwipeGestureRecognizer {
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        gestureRecognizer.direction = .right
        return gestureRecognizer
    }
    
    fileprivate func addTapGestureHandler() {
        menuView?.menuItemViews.forEach {
            $0.addGestureRecognizer(tapGestureRecognizer)
        }
    }
    
    fileprivate func addSwipeGestureHandler() {
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
    
    @objc internal func handleTapGesture(_ recognizer: UITapGestureRecognizer) {
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
    
    @objc internal func handleSwipeGesture(_ recognizer: UISwipeGestureRecognizer) {
        guard let menuView = recognizer.view as? MenuView,
            let menuOptions = menuOptions else { return }
        
        let newPage: Int
        switch (recognizer.direction, menuOptions.displayMode) {
        case (UISwipeGestureRecognizer.Direction.left, .infinite):
            newPage = menuView.nextPage
        case (UISwipeGestureRecognizer.Direction.left, _):
            newPage = min(nextPage, menuOptions.itemsOptions.count - 1)
        case (UISwipeGestureRecognizer.Direction.right, .infinite):
            newPage = menuView.previousPage
        case (UISwipeGestureRecognizer.Direction.right, _):
            newPage = max(previousPage, 0)
        default: return
        }
        
        move(toPage: newPage)
    }
}

extension PagingMenuController {
    func cleanup() {
        if let menuView = self.menuView {
            menuView.cleanup()
            menuView.removeFromSuperview()
        }
        if let pagingViewController = self.pagingViewController {
            pagingViewController.cleanup()
            pagingViewController.view.removeFromSuperview()
            pagingViewController.removeFromParent()
            pagingViewController.willMove(toParent: nil)
        }
    }
}

// MARK: Validator

extension PagingMenuController {
    fileprivate func validate(_ options: PagingMenuControllerCustomizable) {
        validateDefaultPage(options)
        validateContentsCount(options)
        validateInfiniteMenuItemNumbers(options)
    }
    
    fileprivate func validateContentsCount(_ options: PagingMenuControllerCustomizable) {
        switch options.componentType {
        case .all(let menuOptions, let pagingControllers):
            guard menuOptions.itemsOptions.count == pagingControllers.count else {
                raise("number of menu items and view controllers doesn't match")
                return
            }
        default: break
        }
    }
    
    fileprivate func validateDefaultPage(_ options: PagingMenuControllerCustomizable) {
        let maxCount: Int
        switch options.componentType {
        case .pagingController(let pagingControllers):
            maxCount = pagingControllers.count
        case .all(_, let pagingControllers):
            maxCount = pagingControllers.count
        case .menuView(let menuOptions):
            maxCount = menuOptions.itemsOptions.count
        }
        
        guard options.defaultPage >= maxCount || options.defaultPage < 0 else { return }
        
        raise("default page is invalid")
    }
    
    fileprivate func validateInfiniteMenuItemNumbers(_ options: PagingMenuControllerCustomizable) {
        guard case .all(let menuOptions, _) = options.componentType,
            case .infinite = menuOptions.displayMode else { return }
        guard menuOptions.itemsOptions.count < VisiblePagingViewNumber else { return }
        
        raise("number of view controllers should be more than three with Infinite display mode")
    }
    
    fileprivate var exceptionName: String {
        return "PMCException"
    }
    
    fileprivate func raise(_ reason: String) {
        NSException(name: NSExceptionName(rawValue: exceptionName), reason: reason, userInfo: nil).raise()
    }
}
