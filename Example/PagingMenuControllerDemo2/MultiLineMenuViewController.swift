//
//  MultiLineMenuViewController.swift
//  PagingMenuControllerDemo
//
//  Created by Cheng-chien Kuo on 5/17/16.
//  Copyright © 2016 kitasuke. All rights reserved.
//

import UIKit
import PagingMenuController

class MultiLineMenuViewController: UIViewController {
    var navigationBar: UINavigationBar?
    var navigationBarHeight = CGFloat(64)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.whiteColor()
        
        let viewController = ViewController1()
        viewController.title = "Multi 1"
        viewController.menuItemDescription = "Desc 1"
        
        let viewController3 = ViewController3()
        viewController3.title = "Multi 3"
        viewController3.menuItemDescription = "Desc 3"
        
        let viewControllers = [viewController, viewController3]
        
        let options = PagingMenuOptions()
        options.menuItemMargin = 5
        options.menuHeight = 60
        options.menuDisplayMode = .SegmentedControl

        let pagingMenuController = PagingMenuController(menuControllerTypes: viewControllers, options: options)
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

extension MultiLineMenuViewController: UINavigationBarDelegate {
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return UIBarPosition.TopAttached;
    }
}

