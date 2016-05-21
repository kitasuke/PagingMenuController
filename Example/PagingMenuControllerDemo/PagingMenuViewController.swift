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
        usersViewController.menuItemDescription = menuItemDescription
        let repositoriesViewController = RepositoriesViewController.instantiateFromStoryboard()
        repositoriesViewController.menuItemDescription = menuItemDescription
        let gistsViewController = GistsViewController.instantiateFromStoryboard()
        gistsViewController.menuItemDescription = menuItemDescription
        let organizationsViewController = OrganizationsViewController.instantiateFromStoryboard()
        organizationsViewController.menuItemDescription = menuItemDescription
        
        let viewControllers = [usersViewController, repositoriesViewController, gistsViewController, organizationsViewController]
        
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        pagingMenuController.delegate = self
        
        switch options.menuComponentType {
        case .All, .MenuController:
            pagingMenuController.setup(viewControllers, options: options)
        case .MenuView:
            pagingMenuController.setup(viewControllers.map { $0.title! }, options: options)
        }
    }
}

extension PagingMenuViewController: PagingMenuControllerDelegate {
    // MARK: - PagingMenuControllerDelegate

    func willMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController) {

    }

    func didMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController) {

    }
}