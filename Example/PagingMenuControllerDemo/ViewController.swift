//
//  ViewController.swift
//  PagingMenuControllerDemo
//
//  Created by Yusuke Kita on 5/10/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit
import PagingMenuController

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let viewController1 = self.storyboard?.instantiateViewControllerWithIdentifier("ViewController1") as! ViewController1
        viewController1.title = "First"
        let viewController2 = self.storyboard?.instantiateViewControllerWithIdentifier("ViewController2") as! ViewController2
        viewController2.title = "Second"
        let viewController3 = self.storyboard?.instantiateViewControllerWithIdentifier("ViewController3") as! ViewController3
        viewController3.title = "Third"
        let viewController4 = self.storyboard?.instantiateViewControllerWithIdentifier("ViewController4") as! ViewController4
        viewController4.title = "Fourth"
        let viewController5 = self.storyboard?.instantiateViewControllerWithIdentifier("ViewController5") as! ViewController5
        viewController5.title = "Fifth"
        
        let viewControllers = [viewController1, viewController2, viewController3, viewController4, viewController5]
        
        let options = PagingMenuOptions()
        
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        pagingMenuController.setup(viewControllers: viewControllers, options: options)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

