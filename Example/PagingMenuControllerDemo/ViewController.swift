//
//  ViewController.swift
//  PagingMenuControllerDemo
//
//  Created by Yusuke Kita on 5/10/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit
import PagingMenuController

class ViewController: UIViewController, PagingMenuControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let usersViewController = self.storyboard?.instantiateViewControllerWithIdentifier("UsersViewController") as! UsersViewController
        let repositoriesViewController = self.storyboard?.instantiateViewControllerWithIdentifier("RepositoriesViewController") as! RepositoriesViewController
        let gistsViewController = self.storyboard?.instantiateViewControllerWithIdentifier("GistsViewController") as! GistsViewController
        let organizationsViewController = self.storyboard?.instantiateViewControllerWithIdentifier("OrganizationsViewController") as! OrganizationsViewController
        
        let viewControllers = [usersViewController, repositoriesViewController, gistsViewController, organizationsViewController]
        
        let options = PagingMenuOptions()
        options.menuHeight = 50
        
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        pagingMenuController.delegate = self
        pagingMenuController.setup(viewControllers: viewControllers, options: options)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - PagingMenuControllerDelegate
    
    func willMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController) {

    }
    
    func didMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController) {

    }
}

