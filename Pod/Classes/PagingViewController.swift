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
        let viewsDictionary = ["contentScrollView": contentScrollView]
        
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentScrollView]|", options: [], metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentScrollView]|", options: [], metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
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
        
        var viewsDictionary: [String: AnyObject] = ["contentScrollView": contentScrollView]
        for (index, controller) in controllers.enumerate() {
            if !shouldLoadPage(index) {
                continue
            }
            
            viewsDictionary["pagingView"] = controller.view!
            var horizontalVisualFormat = String()
            
            // only one view controller
            if options.lazyLoadingPage == LazyLoadingPage.One ||
                controllers.count == MinimumSupportedViewCount || options.menuControllerSet == MenuControllerSet.Single {
                horizontalVisualFormat = "H:|[pagingView(==contentScrollView)]|"
            } else {
                if case .All(let menuOptions, _) = options.componentType, case .Infinite = menuOptions.displayMode {
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
            
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(horizontalVisualFormat, options: [], metrics: nil, views: viewsDictionary)
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pagingView(==contentScrollView)]|", options: [], metrics: nil, views: viewsDictionary)
            
            NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
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