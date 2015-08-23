//
//  PagingMenuController.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 3/18/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

@objc public protocol PagingMenuControllerDelegate: class {
    optional func willMoveToMenuPage(page: Int)
    optional func didMoveToMenuPage(page: Int)
}

public class PagingMenuController: UIViewController, UIScrollViewDelegate {
    
    public weak var delegate: PagingMenuControllerDelegate?
    private var options: PagingMenuOptions!
    private var menuView: MenuView!
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var pagingViewControllers = [UIViewController]()
    private var currentPage: Int = 0
    private var currentViewController: UIViewController!
    private let ExceptionName = "PMCException"

    // MARK: - Lifecycle
    
    public init(viewControllers: [UIViewController], options: PagingMenuOptions) {
        super.init(nibName: nil, bundle: nil)
        
        setup(viewControllers: viewControllers, options: options)
    }
    
    convenience public init(viewControllers: [UIViewController]) {
        self.init(viewControllers: viewControllers, options: PagingMenuOptions())
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // fix unnecessary inset for menu view when implemented by programmatically
        menuView.contentInset = UIEdgeInsetsZero
        
        moveToMenuPage(currentPage, animated: false)
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        menuView.updateMenuItemConstraintsIfNeeded(size: size)
    }
    
    public func setup(#viewControllers: [UIViewController], options: PagingMenuOptions) {
        pagingViewControllers = viewControllers
        self.options = options
        self.options.menuItemCount = pagingViewControllers.count
        
        // validate
        validateDefaultPage()
        validateRoundRectScaleIfNeeded()
        
        constructMenuView()
        constructScrollView()
        layoutMenuView()
        layoutScrollView()
        constructContentView()
        layoutContentView()
        constructPagingViewControllers()
        layoutPagingViewControllers()
        
        currentPage = self.options.defaultPage
        currentViewController = pagingViewControllers[self.options.defaultPage]
    }
    
    // MARK: - UISCrollViewDelegate
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if !scrollView.isEqual(self.scrollView) || !scrollView.dragging {
            return
        }
        
        let page = currentPagingViewPage()
        if currentPage == page {
            self.scrollView.contentOffset = scrollView.contentOffset
        } else {
            currentPage = page
            menuView.moveToMenu(page: currentPage, animated: true)
        }
    }
    
    public func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        if !scrollView.isEqual(self.scrollView) {
            return
        }
        
        let nextPage = scrollView.panGestureRecognizer.translationInView(contentView).x < 0.0 ? currentPage + 1 : currentPage - 1
        delegate?.willMoveToMenuPage?(nextPage)
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        if !scrollView.isEqual(self.scrollView) {
            return
        }
        delegate?.didMoveToMenuPage?(currentPage)
    }
    
    // MARK: - UIGestureRecognizer
    
    internal func handleTapGesture(recognizer: UITapGestureRecognizer) {
        let tappedMenuView = recognizer.view as! MenuItemView
        if let tappedPage = find(menuView.menuItemViews, tappedMenuView) where tappedPage != currentPage {
            let page = targetPage(tappedPage: tappedPage)
            moveToMenuPage(page, animated: true)
        }
    }
    
    internal func handleSwipeGesture(recognizer: UISwipeGestureRecognizer) {
        var newPage = currentPage
        if recognizer.direction == .Left {
            newPage = min(++newPage, menuView.menuItemViews.count - 1)
        } else if recognizer.direction == .Right {
            newPage = max(--newPage, 0)
        }
        moveToMenuPage(newPage, animated: true)
    }
    
    // MARK: - Constructor
    
    private func constructMenuView() {
        menuView = MenuView(menuItemTitles: menuItemTitles(), options: options)
        menuView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(menuView)
        
        for menuItemView in menuView.menuItemViews {
            menuItemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "handleTapGesture:"))
        }
        
        addSwipeGestureHandlersIfNeeded()
    }
    
    private func layoutMenuView() {
        let viewsDictionary = ["menuView": menuView]
        let metrics = ["height": options.menuHeight]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[menuView]|", options: .allZeros, metrics: nil, views: viewsDictionary)
        let verticalConstraints: [AnyObject]
        switch options.menuPosition {
        case .Top:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[menuView(height)]", options: .allZeros, metrics: metrics, views: viewsDictionary)
        case .Bottom:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView(height)]|", options: .allZeros, metrics: metrics, views: viewsDictionary)
        }
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
    
    private func constructScrollView() {
        scrollView = UIScrollView(frame: CGRectZero)
        scrollView.delegate = self
        scrollView.pagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.scrollsToTop = false
        scrollView.bounces = false
        scrollView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addSubview(scrollView)
    }
    
    private func layoutScrollView() {
        let viewsDictionary = ["scrollView": scrollView, "menuView": menuView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[scrollView]|", options: .allZeros, metrics: nil, views: viewsDictionary)
        let verticalConstraints: [AnyObject]
        switch options.menuPosition {
        case .Top:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView][scrollView]|", options: .allZeros, metrics: nil, views: viewsDictionary)
        case .Bottom:
            verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[scrollView][menuView]", options: .allZeros, metrics: nil, views: viewsDictionary)
        }
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
    
    private func constructContentView() {
        contentView = UIView(frame: CGRectZero)
        contentView.setTranslatesAutoresizingMaskIntoConstraints(false)
        scrollView.addSubview(contentView)
    }
    
    private func layoutContentView() {
        let viewsDictionary = ["contentView": contentView, "scrollView": scrollView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: .allZeros, metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView(==scrollView)]|", options: .allZeros, metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
    }
    
    private func constructPagingViewControllers() {
        for (index, pagingViewController) in enumerate(pagingViewControllers) {
            pagingViewController.view!.frame = CGRectZero
            pagingViewController.view!.setTranslatesAutoresizingMaskIntoConstraints(false)

            contentView.addSubview(pagingViewController.view!)
            addChildViewController(pagingViewController as UIViewController)
            pagingViewController.didMoveToParentViewController(self)
        }
    }
    
    private func layoutPagingViewControllers() {
        var contentWidth: CGFloat = 0.0
        var viewsDictionary: [String: AnyObject] = ["scrollView": scrollView]
        for (index, pagingViewController) in enumerate(pagingViewControllers) {
            contentWidth += view.frame.width
            
            viewsDictionary["pagingView"] = pagingViewController.view!
            let horizontalVisualFormat: String
            if (index == 0) {
                horizontalVisualFormat = "H:|[pagingView(==scrollView)]"
            } else if (index == pagingViewControllers.count - 1) {
                horizontalVisualFormat = "H:[previousPagingView][pagingView(==scrollView)]|"
                viewsDictionary["previousPagingView"] = pagingViewControllers[index - 1].view
            } else {
                horizontalVisualFormat = "H:[previousPagingView][pagingView(==scrollView)][nextPagingView]"
                viewsDictionary["previousPagingView"] = pagingViewControllers[index - 1].view
                viewsDictionary["nextPagingView"] = pagingViewControllers[index + 1].view
            }
            
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(horizontalVisualFormat, options: .allZeros, metrics: nil, views: viewsDictionary)
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pagingView(==scrollView)]|", options: .allZeros, metrics: nil, views: viewsDictionary)
            
            NSLayoutConstraint.activateConstraints(horizontalConstraints + verticalConstraints)
        }
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    private func menuItemTitles() -> [String] {
        var titles = [String]()
        for (index, viewController) in enumerate(pagingViewControllers) {
            if let title = viewController.title {
                titles.append(title)
            } else {
                titles.append("Menu \(index)")
            }
        }
        return titles
    }
    
    // MARK: - Gesture handler
    
    private func addSwipeGestureHandlersIfNeeded() {
        switch options.menuDisplayMode {
        case .FlexibleItemWidth(_, let scrollingMode):
            switch scrollingMode {
            case .PagingEnabled: break
            default: return
            }
        case .FixedItemWidth(_, _, let scrollingMode):
            switch scrollingMode {
            case .PagingEnabled: break
            default: return
            }
        case .SegmentedControl:
            return
        }
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: "handleSwipeGesture:")
        leftSwipeGesture.direction = .Left
        menuView.panGestureRecognizer.requireGestureRecognizerToFail(leftSwipeGesture)
        menuView.addGestureRecognizer(leftSwipeGesture)
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: "handleSwipeGesture:")
        rightSwipeGesture.direction = .Right
        menuView.panGestureRecognizer.requireGestureRecognizerToFail(rightSwipeGesture)
        menuView.addGestureRecognizer(rightSwipeGesture)
    }
    
    // MARK: - Page controller
    
    private func moveToMenuPage(page: Int, animated: Bool) {
        currentPage = page
        currentViewController = pagingViewControllers[page]
        
        delegate?.willMoveToMenuPage?(currentPage)
        
        menuView.moveToMenu(page: currentPage, animated: animated)
        
        let duration = animated ? options.animationDuration : 0
        UIView.animateWithDuration(duration, animations: { [unowned self] () -> Void in
            self.scrollView.contentOffset.x = self.scrollView.frame.width * CGFloat(page)
            }) { (finished: Bool) -> Void in
                if finished {
                    self.delegate?.didMoveToMenuPage?(self.currentPage)
                }
        }
    }
    
    // MARK: - Page calculator
    
    private func currentPagingViewPage() -> Int {
        let pageWidth = scrollView.frame.width
        
        return Int(floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth)) + 1
    }
    
    private func targetPage(#tappedPage: Int) -> Int {
        switch options.menuDisplayMode {
        case .FlexibleItemWidth(_, let scrollingMode):
            switch scrollingMode {
            case .PagingEnabled:
                return tappedPage < currentPage ? currentPage-1 : currentPage+1
            default:
                return tappedPage
            }
        case .FixedItemWidth(_, _, let scrollingMode):
            switch scrollingMode {
            case .PagingEnabled:
                return tappedPage < currentPage ? currentPage-1 : currentPage+1
            default:
                return tappedPage
            }
        case .SegmentedControl:
            return tappedPage
        }
    }
    
    // MARK: - Validator
    
    private func validateDefaultPage() {
        if options.defaultPage >= options.menuItemCount || options.defaultPage < 0 {
            NSException(name: ExceptionName, reason: "default page is invalid", userInfo: nil).raise()
        }
    }
    
    private func validateRoundRectScaleIfNeeded() {
        switch options.menuItemMode {
        case .RoundRect(_, let horizontalScale, let verticalScale, _):
            if horizontalScale < 0 || horizontalScale > 1 || verticalScale < 0 || verticalScale > 1 {
                NSException(name: ExceptionName, reason: "scale value should be between 0 and 1", userInfo: nil).raise()
            }
        default: break
        }
    }
}