//
//  PagingMenuController.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 3/18/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit

class PagingMenuOptions {
    internal var defaultPage = 0
    internal var backgroundColor = UIColor.whiteColor()
    internal var selectedBackgroundColor = UIColor.whiteColor()
    internal var textColor = UIColor.lightGrayColor()
    internal var selectedTextColor = UIColor.darkGrayColor()
    internal var font = UIFont.systemFontOfSize(12)
    internal var menuHeight: CGFloat = 30
    internal var menuItemMargin: CGFloat = 20
    internal var animationDuration: NSTimeInterval = 0.3
    internal var menuDisplayMode = MenuDisplayMode.FlexibleItemWidth(centerItem: false, scrollingMode: MenuScrollingMode.PagingEnabled)
    internal var menuItemCount = 0
    
    enum MenuScrollingMode {
        case ScrollEnabled
        case ScrollEnabledAndBouces
        case PagingEnabled
    }
    
    enum MenuDisplayMode {
        case FlexibleItemWidth(centerItem: Bool, scrollingMode: MenuScrollingMode)
        case FixedItemWidth(width: CGFloat, centerItem: Bool, scrollingMode: MenuScrollingMode)
        case SegmentedControl
    }
}

class PagingMenuController: UIViewController, UIScrollViewDelegate {
    
    private var options: PagingMenuOptions!
    private var menuView: MenuView!
    private var scrollView: UIScrollView!
    private var contentView: UIView!
    private var pagingViewControllers = [UIViewController]()
    private var currentPage: Int = 0
    private var currentViewController: UIViewController!
    private var menuHeightConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle
    
    init(viewControllers: [UIViewController], options: PagingMenuOptions) {
        super.init(nibName: nil, bundle: nil)
        
        self.setup(viewControllers: viewControllers, options: options)
    }
    
    convenience init(viewControllers: [UIViewController]) {
        self.init(viewControllers: viewControllers, options: PagingMenuOptions())
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.menuView.moveToMenu(page: currentPage, animated: false)
        self.menuViewDidScroll(index: currentPage, animated: false)
    }
    
    internal func setup(#viewControllers: [UIViewController], options: PagingMenuOptions) {
        pagingViewControllers = viewControllers
        self.options = options
        options.menuItemCount = pagingViewControllers.count
        
        self.constructMenuView()
        self.layoutMenuView()
        self.constructScrollView()
        self.layoutScrollView()
        self.constructContentView()
        self.layoutContentView()
        self.constructPagingViewControllers()
        self.layoutPagingViewControllers()
        
        self.menuView.moveToMenu(page: options.defaultPage, animated: false)
        self.menuViewDidScroll(index: options.defaultPage, animated: false)
    }
    
    // MARK: - UISCrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let page = self.currentPagingViewPage()
        if currentPage == page {
            self.scrollView.contentOffset = scrollView.contentOffset
        } else {
            currentPage = page
            menuView.moveToMenu(page: currentPage, animated: true)
        }
    }
    
    // MARK: - HomeMenuViewDelegate
    
    func menuViewDidScroll(#index: Int, animated: Bool) {
        currentPage = index
        currentViewController = pagingViewControllers[index]
        
        let duration = animated ? options.animationDuration : 0
        UIView.animateWithDuration(duration, animations: { () -> Void in
            self.scrollView.contentOffset.x = CGRectGetWidth(self.scrollView.frame) * CGFloat(index)
        })
    }
    
    // MARK: - UIGestureRecognizer
    
    func handleTapGesture(recognizer: UITapGestureRecognizer) {
        let tappedMenuView = recognizer.view as! MenuItemView
        if let tappedIndex = find(menuView.menuItemViews, tappedMenuView) where tappedIndex != currentPage {
            let index = self.targetIndex(tappedIndex: tappedIndex)
            menuView.moveToMenu(page: index, animated: true)
            self.menuViewDidScroll(index: index, animated: true)
        }
    }
    
    func handleSwipeGesture(recognizer: UISwipeGestureRecognizer) {
        var newPageIndex = currentPage
        if recognizer.direction == .Left {
            newPageIndex = min(++newPageIndex, menuView.menuItemViews.count - 1)
        } else if recognizer.direction == .Right {
            newPageIndex = max(--newPageIndex, 0)
        }
        menuView.moveToMenu(page: newPageIndex, animated: true)
        self.menuViewDidScroll(index: newPageIndex, animated: true)
    }
    
    // MARK: - Private method
    
    private func constructMenuView() {
        menuView = MenuView(menuItemTitles: self.menuItemTitles(), options: options)
        menuView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addSubview(menuView)
        
        for menuItemView in menuView.menuItemViews {
            menuItemView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "handleTapGesture:"))
        }
        
        self.addSwipeGestureHandlersIfNeeded()
    }
    
    private func layoutMenuView() {
        let viewsDictionary = ["menuView": self.menuView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[menuView]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[menuView]", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDictionary)
        
        self.view.addConstraints(horizontalConstraints)
        self.view.addConstraints(verticalConstraints)
        
        menuHeightConstraint = NSLayoutConstraint(item: menuView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1.0, constant: options.menuHeight)
        view.addConstraint(menuHeightConstraint!)
    }
    
    private func constructScrollView() {
        self.scrollView = UIScrollView(frame: CGRectZero)
        self.scrollView.delegate = self
        self.scrollView.pagingEnabled = true
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        self.scrollView.scrollsToTop = false
        self.scrollView.bounces = false
        self.scrollView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.view.addSubview(self.scrollView)
    }
    
    private func layoutScrollView() {
        let viewsDictionary = ["scrollView": self.scrollView, "menuView": self.menuView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[scrollView]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:[menuView][scrollView]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDictionary)
        
        self.view.addConstraints(horizontalConstraints)
        self.view.addConstraints(verticalConstraints)
    }
    
    private func constructContentView() {
        self.contentView = UIView(frame: CGRectZero)
        self.contentView.setTranslatesAutoresizingMaskIntoConstraints(false)
        self.scrollView.addSubview(self.contentView)
    }
    
    private func layoutContentView() {
        let viewsDictionary = ["contentView": self.contentView, "scrollView": self.scrollView]
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDictionary)
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView(==scrollView)]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDictionary)
        
        self.scrollView.addConstraints(horizontalConstraints)
        self.scrollView.addConstraints(verticalConstraints)
    }
    
    private func constructPagingViewControllers() {
        for (index, pagingViewController) in enumerate(self.pagingViewControllers) {
            pagingViewController.view!.frame = CGRectZero
            pagingViewController.view!.setTranslatesAutoresizingMaskIntoConstraints(false)

            self.contentView.addSubview(pagingViewController.view!)
            self.addChildViewController(pagingViewController as UIViewController)
            pagingViewController.didMoveToParentViewController(self)
        }
    }
    
    private func layoutPagingViewControllers() {
        var contentWidth: CGFloat = 0.0
        var viewsDictionary: [String: AnyObject] = ["scrollView": self.scrollView]
        for (index, pagingViewController) in enumerate(self.pagingViewControllers) {
            contentWidth += CGRectGetWidth(self.view.frame)
            
            viewsDictionary["pagingView"] = pagingViewController.view!
            let horizontalVisualFormat: String
            if (index == 0) {
                horizontalVisualFormat = "H:|[pagingView(==scrollView)]"
            } else if (index == self.pagingViewControllers.count - 1) {
                horizontalVisualFormat = "H:[pagingView(==scrollView)]|"
            } else {
                horizontalVisualFormat = "H:[previousPagingView][pagingView(==scrollView)][nextPagingView]"
                viewsDictionary["previousPagingView"] = self.pagingViewControllers[index - 1].view
                viewsDictionary["nextPagingView"] = self.pagingViewControllers[index + 1].view
            }
            
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(horizontalVisualFormat, options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDictionary)
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[pagingView(==scrollView)]|", options: NSLayoutFormatOptions.allZeros, metrics: nil, views: viewsDictionary)
            
            self.scrollView.addConstraints(horizontalConstraints)
            self.scrollView.addConstraints(verticalConstraints)
        }
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
    }
    
    // MARK: - Private method
    
    private func menuItemTitles() -> [String] {
        var titles = [String]()
        for (index, viewController) in enumerate(self.pagingViewControllers) {
            if let title = viewController.title {
                titles.append(title)
            } else {
                titles.append("Menu \(index)")
            }
        }
        return titles
    }
    
    private func addSwipeGestureHandlersIfNeeded() {
        switch options.menuDisplayMode {
        case .FlexibleItemWidth(let centerItem, let scrollingMode):
            switch scrollingMode {
            case .PagingEnabled:
                break
            default:
                return
            }
        case .FixedItemWidth(let width, let centerItem, let scrollingMode):
            switch scrollingMode {
            case .PagingEnabled:
                break
            default:
                return
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
    
    private func currentPagingViewPage() -> Int {
        let pageWidth = CGRectGetWidth(self.scrollView.frame)
        
        return Int(floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth)) + 1
    }
    
    private func targetIndex(#tappedIndex: Int) -> Int {
        switch options.menuDisplayMode {
        case .FlexibleItemWidth(let centerItem, let scrollingMode):
            switch scrollingMode {
            case .PagingEnabled:
                return tappedIndex < currentPage ? currentPage-1 : currentPage+1
            default:
                return tappedIndex
            }
        case .FixedItemWidth(let width, let centerItem, let scrollingMode):
            switch scrollingMode {
            case .PagingEnabled:
                return tappedIndex < currentPage ? currentPage-1 : currentPage+1
            default:
                return tappedIndex
            }
        case .SegmentedControl:
            return tappedIndex
        }
    }
}