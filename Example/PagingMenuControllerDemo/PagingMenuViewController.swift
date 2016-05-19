//
//  PagingMenuViewController.swift
//  PagingMenuControllerDemo
//
//  Created by Yusuke Kita on 5/17/16.
//  Copyright © 2016 kitasuke. All rights reserved.
//

import UIKit
import PagingMenuController

class PagingMenuViewController: UIViewController {
    var options = PagingMenuOptions()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let usersViewController = UsersViewController.instantiateFromStoryboard()
        let repositoriesViewController = RepositoriesViewController.instantiateFromStoryboard()
        let gistsViewController = GistsViewController.instantiateFromStoryboard()
        let organizationsViewController = OrganizationsViewController.instantiateFromStoryboard()
        
        let viewControllers = [usersViewController, repositoriesViewController, gistsViewController, organizationsViewController]
        
        options.menuHeight = 50
        
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        pagingMenuController.delegate = self
        pagingMenuController.setup(viewControllers, options: options)
    }
}

extension PagingMenuViewController: PagingMenuControllerDelegate {
    // MARK: - PagingMenuControllerDelegate

    func willMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController) {

    }

    func didMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController) {

    }
}