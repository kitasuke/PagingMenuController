//
//  PagingViewController.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 6/3/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import UIKit

open class PagingViewController: UIViewController {
    open let controllers: [UIViewController]
    open internal(set) var currentViewController: UIViewController!
    open fileprivate(set) var visibleControllers = [UIViewController]()
    
    internal let contentScrollView: UIScrollView = {
        $0.isPagingEnabled = true
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
        let viewsDictionary = ["contentScrollView": contentScrollView]
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[contentScrollView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[contentScrollView]|", options: [], metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activate(horizontalConstraints + verticalConstraints)
    }
    
    fileprivate func constructPagingViewControllers() {
        for (index, controller) in controllers.enumerated() {
            // construct three child view controllers at a maximum, previous(optional), current and next(optional)
            if !shouldLoad(page: index) {
                // remove unnecessary child view controllers
                if isVisible(controller: controller) {
                    controller.willMove(toParentViewController: nil)
                    controller.view!.removeFromSuperview()
                    controller.removeFromParentViewController()
                    
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
            pagingView.backgroundColor = options.backgroundColor
            pagingView.translatesAutoresizingMaskIntoConstraints = false
            
            contentScrollView.addSubview(pagingView)
            addChildViewController(controller as UIViewController)
            controller.didMove(toParentViewController: self)
            
            visibleControllers.append(controller)
        }
    }
    
    fileprivate func layoutPagingViewControllers() {
        // cleanup
        NSLayoutConstraint.deactivate(contentScrollView.constraints)
        
        var viewsDictionary: [String: AnyObject] = ["contentScrollView": contentScrollView]
        for (index, controller) in controllers.enumerated() {
            if !shouldLoad(page: index) {
                continue
            }
            
            viewsDictionary["pagingView"] = controller.view!
            var horizontalVisualFormat = String()
            
            // only one view controller
            if options.lazyLoadingPage == LazyLoadingPage.one ||
                controllers.count == MinimumSupportedViewCount || options.menuControllerSet == MenuControllerSet.single {
                horizontalVisualFormat = "H:|[pagingView(==contentScrollView)]|"
            } else {
                if case .all(let menuOptions, _) = options.componentType, case .infinite = menuOptions.displayMode {
                    if index == currentPage {
                        viewsDictionary["previousPagingView"] = controllers[previousPage].view
                        viewsDictionary["nextPagingView"] = controllers[nextPage].view
                        horizontalVisualFormat = "H:[previousPagingView][pagingView(==contentScrollView)][nextPagingView]"
                    } else if index == previousPage {
                        horizontalVisualFormat = "H:|[pagingView(==contentScrollView)]"
                    } else if index == nextPage {
                        horizontalVisualFormat = "H:[pagingView(==contentScrollView)]|"
                    }
                } else {
                    if index == 0 || index == previousPage {
                        horizontalVisualFormat = "H:|[pagingView(==contentScrollView)]"
                    } else {
                        viewsDictionary["previousPagingView"] = controllers[index - 1].view
                        if index == controllers.count - 1 || index == nextPage {
                            horizontalVisualFormat = "H:[previousPagingView][pagingView(==contentScrollView)]|"
                        } else {
                            horizontalVisualFormat = "H:[previousPagingView][pagingView(==contentScrollView)]"
                        }
                    }
                }
            }
            
            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: horizontalVisualFormat, options: [], metrics: nil, views: viewsDictionary)
            let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[pagingView(==contentScrollView)]|", options: [], metrics: nil, views: viewsDictionary)
            
            NSLayoutConstraint.activate(horizontalConstraints + verticalConstraints)
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

extension PagingViewController: ViewCleanable {
    func cleanup() {
        visibleControllers.removeAll(keepingCapacity: true)
        currentViewController = nil
        
        childViewControllers.forEach {
            $0.willMove(toParentViewController: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParentViewController()
        }
        
        contentScrollView.removeFromSuperview()
    }
}

extension PagingViewController: PageLoadable {
    func shouldLoad(page: Int) -> Bool {
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
        }
        return true
    }
    
    func isVisible(controller: UIViewController) -> Bool {
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
