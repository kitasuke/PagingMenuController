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
    public internal(set) var currentPage: Int = 0
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
    private var previousIndex: Int {
        guard case .All(let menuOptions, _) = options.componentType, case .Infinite = menuOptions.mode else { return currentPage - 1 }
        
        return currentPage - 1 < 0 ? menuOptions.itemsOptions.count - 1 : currentPage - 1
    }
    private var nextIndex: Int {
        guard case .All(let menuOptions, _) = options.componentType, case .Infinite = menuOptions.mode else { return currentPage + 1 }
        
        return currentPage + 1 > menuOptions.itemsOptions.count - 1 ? 0 : currentPage + 1
    }
    
    lazy private var shouldLoadPage: (Int) -> Bool = { [unowned self] in
        switch (self.options.menuControllerSet, self.options.lazyLoadingPage) {
        case (.Single, _),
             (_, .One):
            guard $0 == self.currentPage else { return false }
        case (_, .Three):
            if case .All(let menuOptions, _) = self.options.componentType, case .Infinite = menuOptions.mode {
                guard $0 == self.currentPage || $0 == self.previousIndex || $0 == self.nextIndex else { return false }
            } else {
                guard $0 >= self.previousIndex && $0 <= self.nextIndex else { return false }
            }
        }
        return true
    }
    lazy private var isVisibleControllers: (UIViewController) -> Bool = { [unowned self] in
        return self.childViewControllers.contains($0)
    }
    
    init(viewControllers: [UIViewController], options: PagingMenuControllerCustomizable) {
        controllers = viewControllers
        self.options = options
        
        super.init(nibName: nil, bundle: nil)

        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        positionMenuController()
        showVisibleControllersIfNeeded()
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
        
        currentPage = options.defaultPage
        currentViewController = controllers[currentPage]
        hideVisibleControllersIfNeeded()
    }
    
    private func setupView() {
        view.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupContentScrollView() {
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
                if isVisibleControllers(controller) {
                    controller.willMoveToParentViewController(nil)
                    controller.view!.removeFromSuperview()
                    controller.removeFromParentViewController()
                    
                    if let viewIndex = visibleControllers.indexOf(controller) {
                        visibleControllers.removeAtIndex(viewIndex)
                    }
                }
                continue
            }
            
            // ignore if it's already added
            if isVisibleControllers(controller) {
                continue
            }
            
            guard let pagingView = controller.view else {
                fatalError("\(controller) doesn't have any view")
            }
            
            pagingView.frame = .zero
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
                if case .All(let menuOptions, _) = options.componentType, case .Infinite = menuOptions.mode {
                    if index == currentPage {
                        viewsDictionary["previousPagingView"] = controllers[previousIndex].view
                        viewsDictionary["nextPagingView"] = controllers[nextIndex].view
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
                        viewsDictionary["previousPagingView"] = controllers[index - 1].view
                        if index == controllers.count - 1 || index == nextIndex {
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
    
    internal func cleanup() {
        visibleControllers.removeAll(keepCapacity: true)
        currentViewController = nil
        
        childViewControllers.forEach {
            $0.willMoveToParentViewController(nil)
            $0.view.removeFromSuperview()
            $0.removeFromParentViewController()
        }
        
        contentScrollView.removeFromSuperview()
    }
    
    // MARK: - Private
    
    private func hideVisibleControllersIfNeeded() {
        guard shouldWaitForLayout() else { return }
        visibleControllers.forEach { $0.view.alpha = 0 }
    }
    
    private func showVisibleControllersIfNeeded() {
        guard shouldWaitForLayout() else { return }
        visibleControllers.forEach { $0.view.alpha = 1 }
    }
    
    private func shouldWaitForLayout() -> Bool {
        switch options.componentType {
        case .All(let menuOptions, _):
            guard case .Infinite = menuOptions.mode else { return false }
        case .PagingController:
            guard options.defaultPage > 0 else { return false }
        default: return false
        }
        return true
    }
}