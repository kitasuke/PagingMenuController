//
//  PagingViewController.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 6/3/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import UIKit

open class PagingViewController: UIViewController {
    public let controllers: [UIViewController]
    public internal(set) var currentViewController: UIViewController!
    public fileprivate(set) var visibleControllers = [UIViewController]()
    
    internal let contentScrollView: UIScrollView = {
        $0.isPagingEnabled = true
        $0.isDirectionalLockEnabled = true
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.scrollsToTop = false
        $0.bounces = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIScrollView(frame: .zero))
    
    fileprivate let options: PagingMenuControllerCustomizable
    fileprivate var currentIndex: Int = 0
    
    init(viewControllers: [UIViewController], options: PagingMenuControllerCustomizable) {
        controllers = viewControllers
        self.options = options
        
        super.init(nibName: nil, bundle: nil)
        
        update(currentPage: options.defaultPage)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        positionMenuController()
        showVisibleControllers()
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // position paging views correctly after view size is decided
        positionMenuController()
    }
    
    // MARK: - Constructor
    
    internal func setup() {
        setupView()
        setupContentScrollView()
        layoutContentScrollView()
        constructPagingViewControllers()
        layoutPagingViewControllers()
        
        update(currentPage: options.defaultPage)
        currentViewController = controllers[currentPage]
        hideVisibleControllers()
    }
    
    fileprivate func setupView() {
        view.backgroundColor = options.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    fileprivate func setupContentScrollView() {
        contentScrollView.backgroundColor = options.backgroundColor
        contentScrollView.isScrollEnabled = options.isScrollEnabled
        view.addSubview(contentScrollView)
    }
    
    fileprivate func layoutContentScrollView() {
        NSLayoutConstraint.activate([
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
    }
    
    fileprivate func constructPagingViewControllers() {
        for (index, controller) in controllers.enumerated() {
            // construct three child view controllers at a maximum, previous(optional), current and next(optional)
            if !shouldLoad(page: index) {
                // remove unnecessary child view controllers
                if isVisible(controller: controller) {
                    controller.willMove(toParent: nil)
                    controller.view!.removeFromSuperview()
                    controller.removeFromParent()
                    
                    let _ = visibleControllers.index(of: controller).flatMap { visibleControllers.remove(at: $0) }
                }
                continue
            }
            
            // ignore if it's already added
            if isVisible(controller: controller) {
                continue
            }
            
            guard let pagingView = controller.view else {
                fatalError("\(controller) doesn't have any view")
            }
            
            pagingView.frame = .zero
            pagingView.backgroundColor = pagingView.backgroundColor ?? options.backgroundColor
            pagingView.translatesAutoresizingMaskIntoConstraints = false
            
            contentScrollView.addSubview(pagingView)
            addChild(controller as UIViewController)
            controller.didMove(toParent: self)
            
            visibleControllers.append(controller)
        }
    }
    
    fileprivate func layoutPagingViewControllers() {
        // cleanup
        NSLayoutConstraint.deactivate(contentScrollView.constraints)
        
        for (index, controller) in controllers.enumerated() {
            if !shouldLoad(page: index) {
                continue
            }
            
            guard let pagingView = controller.view else { continue }
            
            // only one view controller
            if options.lazyLoadingPage == LazyLoadingPage.one ||
                controllers.count == MinimumSupportedViewCount ||
            options.menuControllerSet == MenuControllerSet.single {
                // H:|[pagingView]|
                NSLayoutConstraint.activate([
                    pagingView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor),
                    pagingView.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor),
                    ])
            } else {
                if case .all(let menuOptions, _) = options.componentType,
                    case .infinite = menuOptions.displayMode {
                    if index == currentPage {
                        guard let previousPagingView = controllers[previousPage].view,
                            let nextPagingView = controllers[nextPage].view else { continue }
                        
                        // H:[previousPagingView][pagingView][nextPagingView]
                        NSLayoutConstraint.activate([
                            previousPagingView.trailingAnchor.constraint(equalTo: pagingView.leadingAnchor, constant: 0),
                            pagingView.trailingAnchor.constraint(equalTo: nextPagingView.leadingAnchor, constant: 0)
                            ])
                    } else if index == previousPage {
                        // "H:|[pagingView]
                        pagingView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor).isActive = true
                    } else if index == nextPage {
                        // H:[pagingView]|
                        pagingView.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor).isActive = true
                    }
                } else {
                    switch (options.lazyLoadingPage, index) {
                    case (.three, 0),
                         (.three, previousPage),
                         (.all, 0):
                        // H:|[pagingView]
                        pagingView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor).isActive = true
                    case (.three, controllers.count - 1),
                             (.three, nextPage),
                             (.all, controllers.count - 1):
                            guard let previousPagingView = controllers[index - 1].view else { continue }
                            // H:[previousPagingView][pagingView]|
                            previousPagingView.trailingAnchor.constraint(equalTo: pagingView.leadingAnchor, constant: 0).isActive = true
                            pagingView.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor).isActive = true
                    case (.three, _), (.all, _):
                        guard let previousPagingView = controllers[index - 1].view else { continue }
                        // H:[previousPagingView][pagingView]
                        previousPagingView.trailingAnchor.constraint(equalTo: pagingView.leadingAnchor, constant: 0).isActive = true
                    default: break
                    }
                }
            }
            // H:[pagingView(==contentScrollView)
            pagingView.widthAnchor.constraint(equalTo: contentScrollView.widthAnchor).isActive = true
            
            // V:|[pagingView(==contentScrollView)]|
            NSLayoutConstraint.activate([
                pagingView.topAnchor.constraint(equalTo: contentScrollView.topAnchor),
                pagingView.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),
                pagingView.heightAnchor.constraint(equalTo: contentScrollView.heightAnchor)
                ])
        }
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    // MARK: - Internal
    
    internal func relayoutPagingViewControllers() {
        constructPagingViewControllers()
        layoutPagingViewControllers()
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    internal func positionMenuController() {
        if let currentViewController = currentViewController,
            let currentView = currentViewController.view {
            contentScrollView.contentOffset.x = currentView.frame.minX
        }
    }
}

extension PagingViewController: Pagable {
    public var currentPage: Int {
        return currentIndex
    }
    var previousPage: Int {
        guard case .all(let menuOptions, _) = options.componentType, case .infinite = menuOptions.displayMode else { return currentPage - 1 }
        
        return currentPage - 1 < 0 ? menuOptions.itemsOptions.count - 1 : currentPage - 1
    }
    var nextPage: Int {
        guard case .all(let menuOptions, _) = options.componentType, case .infinite = menuOptions.displayMode else { return currentPage + 1 }
        
        return currentPage + 1 > menuOptions.itemsOptions.count - 1 ? 0 : currentPage + 1
    }
    func update(currentPage page: Int) {
        currentIndex = page
    }
}

extension PagingViewController {
    func cleanup() {
        visibleControllers.removeAll(keepingCapacity: true)
        currentViewController = nil
        
        children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
        
        contentScrollView.removeFromSuperview()
    }
}

// MARK: Page Control

extension PagingViewController {
    fileprivate func shouldLoad(page: Int) -> Bool {
        switch (options.menuControllerSet, options.lazyLoadingPage) {
        case (.single, _),
             (_, .one):
            guard page == currentPage else { return false }
        case (_, .three):
            if case .all(let menuOptions, _) = options.componentType,
                case .infinite = menuOptions.displayMode {
                guard page == currentPage ||
                    page == previousPage ||
                    page == nextPage else { return false }
            } else {
                guard page >= previousPage &&
                    page <= nextPage else { return false }
            }
        case (_, .all): return true
        }
        return true
    }
    
    fileprivate func isVisible(controller: UIViewController) -> Bool {
        return self.children.contains(controller)
    }
    
    fileprivate func hideVisibleControllers() {
        guard shouldWaitForLayout() else { return }
        visibleControllers.forEach { $0.view.alpha = 0 }
    }
    
    fileprivate func showVisibleControllers() {
        guard shouldWaitForLayout() else { return }
        visibleControllers.forEach { $0.view.alpha = 1 }
    }
    
    fileprivate func shouldWaitForLayout() -> Bool {
        switch options.componentType {
        case .all(let menuOptions, _):
            guard case .infinite = menuOptions.displayMode else { return false }
            return true
        default: break
        }
        
        guard options.defaultPage > 0 else { return false }
        return true
    }
}
