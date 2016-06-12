//
//  PagingViewController.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 6/3/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import UIKit

public class PagingViewController: UIViewController {
    public let controllers: [UIViewController]
    public internal(set) var currentViewController: UIViewController!
    public private(set) var visibleControllers = [UIViewController]()
    
    internal let contentScrollView: UIScrollView = {
        $0.pagingEnabled = true
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.scrollsToTop = false
        $0.bounces = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIScrollView(frame: .zero))
    
    private let options: PagingMenuControllerCustomizable
    private var currentIndex: Int = 0
    
    init(viewControllers: [UIViewController], options: PagingMenuControllerCustomizable) {
        controllers = viewControllers
        self.options = options
        
        super.init(nibName: nil, bundle: nil)
        
        updateCurrentPage(options.defaultPage)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        positionMenuController()
        showVisibleControllers()
    }
    
    override public func viewDidLayoutSubviews() {
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
        
        updateCurrentPage(options.defaultPage)
        currentViewController = controllers[currentPage]
        hideVisibleControllers()
    }
    
    private func setupView() {
        view.backgroundColor = options.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupContentScrollView() {
        contentScrollView.backgroundColor = options.backgroundColor
        contentScrollView.scrollEnabled = options.scrollEnabled
        view.addSubview(contentScrollView)
    }
    
    private func layoutContentScrollView() {
        NSLayoutConstraint.activateConstraints([
            contentScrollView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            contentScrollView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
            contentScrollView.topAnchor.constraintEqualToAnchor(view.topAnchor),
            contentScrollView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor),
            ])
    }
    
    private func constructPagingViewControllers() {
        for (index, controller) in controllers.enumerate() {
            // construct three child view controllers at a maximum, previous(optional), current and next(optional)
            if !shouldLoadPage(index) {
                // remove unnecessary child view controllers
                if isVisibleController(controller) {
                    controller.willMoveToParentViewController(nil)
                    controller.view!.removeFromSuperview()
                    controller.removeFromParentViewController()
                    
                    let _ = visibleControllers.indexOf(controller).flatMap { visibleControllers.removeAtIndex($0) }
                }
                continue
            }
            
            // ignore if it's already added
            if isVisibleController(controller) {
                continue
            }
            
            guard let pagingView = controller.view else {
                fatalError("\(controller) doesn't have any view")
            }
            
            pagingView.frame = .zero
            pagingView.backgroundColor = options.backgroundColor
            pagingView.translatesAutoresizingMaskIntoConstraints = false
            
            contentScrollView.addSubview(pagingView)
            addChildViewController(controller as UIViewController)
            controller.didMoveToParentViewController(self)
            
            visibleControllers.append(controller)
        }
    }
    
    private func layoutPagingViewControllers() {
        // cleanup
        NSLayoutConstraint.deactivateConstraints(contentScrollView.constraints)
        
        for (index, controller) in controllers.enumerate() {
            if !shouldLoadPage(index) {
                continue
            }
            
            let pagingView = controller.view
            
            // only one view controller
            if options.lazyLoadingPage == LazyLoadingPage.One ||
                controllers.count == MinimumSupportedViewCount || options.menuControllerSet == MenuControllerSet.Single {
                // H:|[pagingView]|
                NSLayoutConstraint.activateConstraints([
                    pagingView.leadingAnchor.constraintEqualToAnchor(contentScrollView.leadingAnchor),
                    pagingView.trailingAnchor.constraintEqualToAnchor(contentScrollView.trailingAnchor),
                    ])
            } else {
                if case .All(let menuOptions, _) = options.componentType, case .Infinite = menuOptions.displayMode {
                    if index == currentPage {
                        let previousPagingView = controllers[previousPage].view
                        let nextPagingView = controllers[nextPage].view
                        
                        // H:[previousPagingView][pagingView][nextPagingView]
                        NSLayoutConstraint.activateConstraints([
                            previousPagingView.trailingAnchor.constraintEqualToAnchor(pagingView.leadingAnchor, constant: 0),
                            pagingView.trailingAnchor.constraintEqualToAnchor(nextPagingView.leadingAnchor, constant: 0)
                            ])
                    } else if index == previousPage {
                        // "H:|[pagingView]
                        pagingView.leadingAnchor.constraintEqualToAnchor(contentScrollView.leadingAnchor).active = true
                    } else if index == nextPage {
                        // H:[pagingView]|
                        pagingView.trailingAnchor.constraintEqualToAnchor(contentScrollView.trailingAnchor).active = true
                    }
                } else {
                    if index == 0 || index == previousPage {
                        pagingView.leadingAnchor.constraintEqualToAnchor(contentScrollView.leadingAnchor).active = true
                    } else {
                        let previousPagingView = controllers[index - 1].view
                        if index == controllers.count - 1 || index == nextPage {
                            // H:[pagingView]|
                            pagingView.trailingAnchor.constraintEqualToAnchor(contentScrollView.trailingAnchor).active = true
                        }
                        // H:[previousPagingView][pagingView]
                        previousPagingView.trailingAnchor.constraintEqualToAnchor(pagingView.leadingAnchor, constant: 0).active = true
                    }
                }
            }
            // H:[pagingView(==contentScrollView)
            pagingView.widthAnchor.constraintEqualToAnchor(contentScrollView.widthAnchor).active = true
            
            // V:|[pagingView(==contentScrollView)]|
            NSLayoutConstraint.activateConstraints([
                pagingView.topAnchor.constraintEqualToAnchor(contentScrollView.topAnchor),
                pagingView.bottomAnchor.constraintEqualToAnchor(contentScrollView.bottomAnchor),
                pagingView.heightAnchor.constraintEqualToAnchor(contentScrollView.heightAnchor)
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
        guard case .All(let menuOptions, _) = options.componentType, case .Infinite = menuOptions.displayMode else { return currentPage - 1 }
        
        return currentPage - 1 < 0 ? menuOptions.itemsOptions.count - 1 : currentPage - 1
    }
    var nextPage: Int {
        guard case .All(let menuOptions, _) = options.componentType, case .Infinite = menuOptions.displayMode else { return currentPage + 1 }
        
        return currentPage + 1 > menuOptions.itemsOptions.count - 1 ? 0 : currentPage + 1
    }
    func updateCurrentPage(page: Int) {
        currentIndex = page
    }
}

extension PagingViewController: ViewCleanable {
    func cleanup() {
        visibleControllers.removeAll(keepCapacity: true)
        currentViewController = nil
        
        childViewControllers.forEach {
            $0.willMoveToParentViewController(nil)
            $0.view.removeFromSuperview()
            $0.removeFromParentViewController()
        }
        
        contentScrollView.removeFromSuperview()
    }
}

extension PagingViewController: PageLoadable {
    func shouldLoadPage(page: Int) -> Bool {
        switch (options.menuControllerSet, options.lazyLoadingPage) {
        case (.Single, _),
             (_, .One):
            guard page == currentPage else { return false }
        case (_, .Three):
            if case .All(let menuOptions, _) = options.componentType,
                case .Infinite = menuOptions.displayMode {
                guard page == currentPage ||
                    page == previousPage ||
                    page == nextPage else { return false }
            } else {
                guard page >= previousPage &&
                    page <= nextPage else { return false }
            }
        }
        return true
    }
    
    func isVisibleController(controller: UIViewController) -> Bool {
        return self.childViewControllers.contains(controller)
    }
    
    func hideVisibleControllers() {
        guard shouldWaitForLayout() else { return }
        visibleControllers.forEach { $0.view.alpha = 0 }
    }
    
    func showVisibleControllers() {
        guard shouldWaitForLayout() else { return }
        visibleControllers.forEach { $0.view.alpha = 1 }
    }
    
    private func shouldWaitForLayout() -> Bool {
        switch options.componentType {
        case .All(let menuOptions, _):
            guard case .Infinite = menuOptions.displayMode else { return false }
            return true
        default: break
        }
        
        guard options.defaultPage > 0 else { return false }
        return true
    }
}