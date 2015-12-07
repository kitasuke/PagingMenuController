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
    private var options: PagingMenuOptions = PagingMenuOptions()
    public private(set) var menuView: MenuView!
    public var currentPage: Int {
        let offsetX = contentScrollView?.contentOffset.x ?? 0
        let page = Int(offsetX / view.bounds.width)

        if case .Infinite = options.menuDisplayMode {
            return max(0, page - 1)
        } else {
            return page
        }
    }

    public var currentViewController: UIViewController? {
        guard currentPage > pagingViewControllers?.count else { return nil }
        return pagingViewControllers?[currentPage]
    }

    public private(set) var pagingViewControllers: [UIViewController]? {
        didSet {
            options.menuItemCount = pagingViewControllers?.count ?? 0

            // remove previous childViewContorllers
            for childViewController in childViewControllers {
                childViewController.willMoveToParentViewController(nil)
                childViewController.view.removeFromSuperview()
                childViewController.removeFromParentViewController()
                childViewController.didMoveToParentViewController(nil)
            }

            constructMenuView()
            layoutMenuView()
            constructContentScrollView()
            layoutContentScrollView()

            // add new childViewControllers
            guard let
                pagingViewControllers = self.pagingViewControllers,
                contentScrollView = contentScrollView else { return }

            let containerWidth = view.bounds.width
            assert(containerWidth > 0)

            for (page, pagingViewController) in pagingViewControllers.enumerate() {
                pagingViewController.willMoveToParentViewController(self)
                addChildViewController(pagingViewController)

                let view = pagingViewController.view
                contentScrollView.addSubview(view)
                view.translatesAutoresizingMaskIntoConstraints = false


                // constraint Top + Width + Height of pages
                for attribute in [NSLayoutAttribute.Top, .Width, .Height] {
                    NSLayoutConstraint(item: view, attribute: attribute, relatedBy: .Equal, toItem: contentScrollView, attribute: attribute, multiplier: 1, constant: 0).active = true
                }

                // constraint leading of first page to superview
                let toItem: UIView
                let toAttribute: NSLayoutAttribute
                let constant: CGFloat

                if page == 0 {
                    toItem = contentScrollView
                    toAttribute = .Leading

                    if case .Infinite = options.menuDisplayMode {
                        constant = containerWidth
                    } else {
                        constant = 0
                    }
                } else {
                    let previousPage = page - 1
                    toItem = pagingViewControllers[previousPage].view
                    toAttribute = .Trailing
                    constant = 0
                }

                NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: toItem, attribute: toAttribute, multiplier: 1, constant: constant).active = true

                pagingViewController.didMoveToParentViewController(self)
            }

            var pageCount = pagingViewControllers.count
            if case .Infinite = options.menuDisplayMode {
                pageCount += 2 // add space for front and back copy of views
            }

            contentScrollView.contentSize.width = CGFloat(pageCount) * containerWidth
        }
    }

    private var contentScrollView: UIScrollView!
    private var menuItemTitles: [String] {
        get {
            guard let pagingViewControllers = pagingViewControllers else { return [] }
            return pagingViewControllers.map { return $0.title ?? "Menu" }
        }
    }
    private enum PagingViewPosition {
        case Left
        case Center
        case Right

        init?(order: Int) {
            switch order {
            case 0: self = .Left
            case 1: self = .Center
            case 2: self = .Right
            default: return nil
            }
        }
    }

    private let visiblePagingViewNumber: Int = 3
    private var previousIndex: Int {
        guard case .Infinite = options.menuDisplayMode else { return currentPage - 1 }

        return currentPage - 1 < 0 ? options.menuItemCount - 1 : currentPage - 1
    }
    private var nextIndex: Int {
        guard case .Infinite = options.menuDisplayMode else { return currentPage + 1 }

        return currentPage + 1 > options.menuItemCount - 1 ? 0 : currentPage + 1
    }

    private let ExceptionName = "PMCException"

    // MARK: - Lifecycle

    public init(viewControllers: [UIViewController], options: PagingMenuOptions? = nil) {
        if let options = options {
            self.options = options
        }

        super.init(nibName: nil, bundle: nil)
        setup(viewControllers: viewControllers)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // position properly for Infinite mode
        menuView.moveToMenu(page: currentPage, animated: false)
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // fix unnecessary inset for menu view when implemented by programmatically
        menuView.contentInset.top = 0

        // position paging views correctly after view size is decided
        if let currentViewController = currentViewController {
            contentScrollView.contentOffset.x = currentViewController.view!.frame.minX
        }
    }

    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        menuView.updateMenuViewConstraints(size: size)

        coordinator.animateAlongsideTransition({ [unowned self] (_) -> Void in
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()

            // reset selected menu item view position
            switch self.options.menuDisplayMode {
            case .Standard, .Infinite:
                self.menuView.moveToMenu(page: self.currentPage, animated: true)
            default: break
            }
            }, completion: nil)
    }

    public func setup(viewControllers viewControllers: [UIViewController]) {
        pagingViewControllers = viewControllers

        validateDefaultPage()
        validatePageNumbers()

        moveToMenuPage(options.defaultPage, animated: false)
    }

    public func rebuild(viewControllers: [UIViewController], options: PagingMenuOptions? = nil) {
        // perform setup
        if let options = options {
            self.options = options
        }
        setup(viewControllers: viewControllers)

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    // MARK: - UISCrollViewDelegate

    public func scrollViewDidScroll(scrollView: UIScrollView) {
        guard toViewController == nil && scrollView.isEqual(contentScrollView) else { return }
        guard let pagingViewControllers = pagingViewControllers else { return }

        var isScrollingLeft = lastVisiblePage > currentPage

        if case .Infinite = options.menuDisplayMode {
            if scrollView.contentOffset.x < offsetXFirstPage { // index < page 0 -> copy last ViewController to image
                isScrollingLeft = true
                setupImageViewCopy(copyType: .Front)
            } else if scrollView.contentOffset.x > pagingViewControllers.last?.view.frame.origin.x {
                setupImageViewCopy(copyType: .Back)
            }
        }

        func nextPageIndex(currentPage currentPage: Int) -> Int {
            let count = pagingViewControllers.count
            let nextPage = currentPage + (isScrollingLeft ? -1 : 1)

            switch nextPage {
            case _ where nextPage >= count:
                return 0
            case _ where nextPage < 0:
                return count - 1
            default:
                return nextPage
            }
        }

        let nextPage = nextPageIndex(currentPage: lastVisiblePage)
        self.toViewController = pagingViewControllers[nextPage]
        toViewController?.beginAppearanceTransition(true, animated: true)
        toViewController?.endAppearanceTransition()
    }

    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        guard scrollView.isEqual(contentScrollView), let pagingViewControllers = pagingViewControllers else { return }

        if case .Infinite = options.menuDisplayMode {
            if scrollView.contentOffset.x == 0 {
                jumpToPage(.Back)
            } else if scrollView.contentOffset.x == offsetXLastPage {
                jumpToPage(.Front)
            }
        }

        // update menuView
        menuView.moveToMenu(page: currentPage, animated: true)
        delegate?.didMoveToMenuPage?(currentPage)

        // invoke appearance on VCs
        let viewController: UIViewController?

        if currentPage == lastVisiblePage {
            // we're going back to the VC we came from. notify toVC that it's disappearing again
            viewController = toViewController
        } else {
            viewController = pagingViewControllers[lastVisiblePage]
            lastVisiblePage = currentPage
        }

        viewController?.beginAppearanceTransition(false, animated: true)
        viewController?.endAppearanceTransition()
        toViewController = nil
    }

    // MARK: - UIGestureRecognizer

    internal func handleTapGesture(recognizer: UITapGestureRecognizer) {
        guard let
            tappedMenuView = recognizer.view as? MenuItemView,
            tappedPage = menuView.menuItemViews.indexOf(tappedMenuView) where tappedPage != currentPage else { return }

        let page = targetPage(tappedPage: tappedPage)
        moveToMenuPage(page, animated: true)
    }

    internal func handleSwipeGesture(recognizer: UISwipeGestureRecognizer) {
        var newPage = currentPage
        if recognizer.direction == .Left {
            newPage = min(nextIndex, menuView.menuItemViews.count - 1)
        } else if recognizer.direction == .Right {
            newPage = max(previousIndex, 0)
        } else {
            return
        }

        moveToMenuPage(newPage, animated: true)
    }

    // MARK: - Constructor

    private func constructMenuView() {
        menuView?.removeFromSuperview()
        menuView = MenuView(menuItemTitles: menuItemTitles, options: options)
        menuView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuView)

        addTapGestureHandlers()
        addSwipeGestureHandlersIfNeeded()
    }

    private func layoutMenuView() {
        NSLayoutConstraint(item: menuView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: options.menuHeight).active = true

        for edge in [NSLayoutAttribute.Leading, .Trailing, options.menuPosition.layoutAttribute] {
            NSLayoutConstraint(item: menuView, attribute: edge, relatedBy: .Equal, toItem: menuView.superview, attribute: edge, multiplier: 1, constant: 0).active = true
        }
    }

    private func constructContentScrollView() {
        contentScrollView?.removeFromSuperview()
        contentScrollView = UIScrollView(frame: CGRectZero)
        contentScrollView.delegate = self
        contentScrollView.pagingEnabled = true
        contentScrollView.showsHorizontalScrollIndicator = false
        contentScrollView.showsVerticalScrollIndicator = false
        contentScrollView.scrollsToTop = false
        contentScrollView.bounces = true
        contentScrollView.scrollEnabled = options.scrollEnabled
        contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentScrollView)
    }

    private func layoutContentScrollView() {
        guard let contentScrollView = contentScrollView where contentScrollView.superview != nil,
            let menuView = menuView else { return }

        for edge in [NSLayoutAttribute.Leading, .Bottom, .Trailing] {
            NSLayoutConstraint(item: contentScrollView, attribute: edge, relatedBy: .Equal, toItem: contentScrollView.superview, attribute: edge, multiplier: 1, constant: 0).active = true
        }

        NSLayoutConstraint(item: contentScrollView, attribute: .Top, relatedBy: .Equal, toItem: menuView, attribute: .Bottom, multiplier: 1, constant: 0).active = true
    }


    // MARK: - Gesture handler

    private func addTapGestureHandlers() {
        menuView.menuItemViews.forEach { $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "handleTapGesture:")) }
    }

    private func addSwipeGestureHandlersIfNeeded() {
        switch options.menuDisplayMode {
        case .Standard(_, _, .PagingEnabled): break
        case .Standard: return
        case .SegmentedControl: return
        case .Infinite: break
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

    private func moveToMenuPage(let page: Int, animated: Bool) {
        guard let pagingViewControllers = pagingViewControllers else { return }
        let fromViewController = pagingViewControllers[currentPage]
        toViewController = pagingViewControllers[page] // use toViewController ivar here to avoid false appearance invokations. see scrollViewDidScroll:

        fromViewController.beginAppearanceTransition(false, animated: animated)
        toViewController?.beginAppearanceTransition(true, animated: animated)

        menuView.moveToMenu(page: page, animated: animated)
        delegate?.willMoveToMenuPage?(page)

        var actualPage = page
        let jumpPage: InfiniteCopyType?

        if case .Infinite = self.options.menuDisplayMode {
            let lastPage = pagingViewControllers.count - 1

            if currentPage == 0 && page == lastPage {
                // jump to back by scrolling to beginning, and jumping in completion block
                setupImageViewCopy(copyType: .Front)
                jumpPage = .Back
                actualPage = 0
            } else if currentPage == lastPage && page == 0 {
                // jump to front by scrolling to end, and jumping in completion block
                setupImageViewCopy(copyType: .Back)
                jumpPage = .Front
                actualPage = lastPage + 2 // jump to front by scrolling to copy
            } else {
                jumpPage = nil
                actualPage++ // increase by one (there's a copy of last VC's view at page 0)
            }
        } else {
            jumpPage = nil
        }

        let duration = animated ? options.animationDuration : 0
        let offsetX = view.bounds.width * CGFloat(actualPage)

        UIView.animateWithDuration(duration, animations: {
            [unowned self] in
            self.contentScrollView.contentOffset.x = offsetX
            }) { [unowned self] _ in
                if let jumpPage = jumpPage {
                    self.jumpToPage(jumpPage) // cann this before the toViewController is nilled
                }

                fromViewController.endAppearanceTransition()
                self.toViewController?.endAppearanceTransition()
                self.toViewController = nil

                self.delegate?.didMoveToMenuPage?(page)
        }
    }

    private func shouldLoadPage(index: Int) -> Bool {
        if case .Infinite = options.menuDisplayMode {
            guard index == currentPage || index == previousIndex || index == nextIndex else { return false }
        } else {
            guard index >= previousIndex && index <= nextIndex else { return false }
        }
        return true
    }

    // MARK: - Page calculator

    private var currentPagingViewPosition: PagingViewPosition {
        guard let contentScrollView = contentScrollView else { return .Left }
        let pageWidth = contentScrollView.frame.width
        let order = Int(ceil((contentScrollView.contentOffset.x - pageWidth / 2) / pageWidth))

        if case .Infinite = options.menuDisplayMode {
            return PagingViewPosition(order: order) ?? .Left
        }

        // consider left edge menu as center position
        guard currentPage == 0 && contentScrollView.contentSize.width < (pageWidth * CGFloat(visiblePagingViewNumber)) else {
            return PagingViewPosition(order: order) ?? .Left
        }

        return PagingViewPosition(order: order + 1) ?? .Left
    }

    private func targetPage(tappedPage tappedPage: Int) -> Int {
        guard case let .Standard(_, _, scrollingMode) = options.menuDisplayMode else { return tappedPage }
        guard case .PagingEnabled = scrollingMode else { return tappedPage }
        return tappedPage < currentPage ? currentPage - 1 : currentPage + 1
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

    // MARK: - Private

    private var lastVisiblePage: Int = 0

    /// The viewController that will be visible when scrolling ends
    private var toViewController: UIViewController?

    private func viewCopyImageView(isFront isFront: Bool) -> UIImageView {
        let imageView = UIImageView()
        imageView.backgroundColor = .greenColor()
        contentScrollView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let toItem = isFront ? contentScrollView : pagingViewControllers!.last!.view

        for attribute in [NSLayoutAttribute.Top, .Leading, .Height, .Width] {
            let toAttribute: NSLayoutAttribute

            if !isFront && attribute == .Leading {
                toAttribute = .Trailing
            } else {
                toAttribute = attribute
            }

            NSLayoutConstraint(item: imageView, attribute: attribute, relatedBy: .Equal, toItem: toItem, attribute: toAttribute, multiplier: 1, constant: 0).active = true
        }

        return imageView
    }
    private lazy var frontImageView: UIImageView = self.viewCopyImageView(isFront: true)
    private lazy var backImageView: UIImageView = self.viewCopyImageView(isFront: false)

    private var offsetXFirstPage: CGFloat {
        if case .Infinite = options.menuDisplayMode {
            return view.bounds.width
        } else {
            return 0
        }
    }

    private var offsetXLastPage: CGFloat {
        if let count = pagingViewControllers?.count,
            case .Infinite = options.menuDisplayMode {
                return view.bounds.width * CGFloat(count + 1)
        } else {
            return 0
        }
    }

    private enum InfiniteCopyType {
        case Front, Back
    }

    private func setupImageViewCopy(copyType copyType: InfiniteCopyType) {
        switch copyType {
        case .Front:
            guard let lastView = pagingViewControllers?.last?.view else { return }
            frontImageView.image = UIImage.imageFromView(lastView)
        case .Back:
            guard let firstView = pagingViewControllers?.first?.view else { return }
            backImageView.image = UIImage.imageFromView(firstView)
        }
    }

    private func jumpToPage(page: InfiniteCopyType) {
        let viewController: UIViewController?
        
        switch page {
        case .Front:
            viewController = pagingViewControllers?.first
        case .Back:
            viewController = pagingViewControllers?.last
        }
        
        if let offsetX = viewController?.view.frame.origin.x {
            contentScrollView.contentOffset.x = offsetX
        }
    }
}

extension UIImage {
    class func imageFromView(view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        view.layer.renderInContext(context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
