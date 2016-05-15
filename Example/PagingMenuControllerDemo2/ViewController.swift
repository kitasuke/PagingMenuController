//
//  ViewController.swift
//  PagingMenuControllerDemo2
//
//  Created by Yusuke Kita on 7/12/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit
import PagingMenuController

class ViewController: UIViewController {
    var navigationBar: UINavigationBar?
    var navigationBarHeight = CGFloat(64)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.whiteColor()
        
        let viewController = ViewController1()
        viewController.title = "First title"
        
        let viewController2 = ViewController2()
        viewController2.title = "Second title"
        
        let viewControllers = [viewController, viewController2]
        
        let options = PagingMenuOptions()
        options.menuItemMargin = 5
        options.menuHeight = 60
        options.menuDisplayMode = .SegmentedControl
        options.menuItemViewContent = .MultilineText
        let pagingMenuController = PagingMenuController(viewControllers: viewControllers, options: options)
        pagingMenuController.view.frame.origin.y += navigationBarHeight
        pagingMenuController.view.frame.size.height -= navigationBarHeight
        
        addChildViewController(pagingMenuController)
        view.addSubview(pagingMenuController.view)
        
        addNavigationBar()
        pagingMenuController.didMoveToParentViewController(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func addNavigationBar() {
        navigationBar = UINavigationBar(frame: CGRectMake(0, 0, self.view.frame.size.width, navigationBarHeight))
        navigationBar!.delegate = self
        
        let navigationItem = UINavigationItem()
        navigationItem.title = "Navigation Bar"
        
        let btnDone = UIBarButtonItem(title: "Done", style: .Done, target: self, action: #selector(ViewController.dismiss))
        navigationItem.rightBarButtonItem = btnDone
        
        navigationBar!.items = [navigationItem]
        self.view.addSubview(navigationBar!)
    }

    func dismiss() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension ViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached;
    }
}

