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
    var options: PagingMenuControllerCustomizable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        pagingMenuController.delegate = self
        pagingMenuController.menuView?.viewDelegate = self
        pagingMenuController.setup(options)
    }
}

extension PagingMenuViewController: PagingMenuControllerDelegate {
    // MARK: - PagingMenuControllerDelegate

    func willMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController) {
        print(#function)
        print(previousMenuController)
        print(menuController)
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        print(pagingMenuController.currentPage)
    }

    func didMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController) {
        print(#function)
        print(previousMenuController)
        print(menuController)
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        print(pagingMenuController.currentPage)
    }
}

extension PagingMenuViewController: MenuViewDelegate {
    func willMoveToMenuItemView(menuItemView: MenuItemView, previousMenuItemView: MenuItemView) {
        print(#function)
        print(previousMenuItemView)
        print(menuItemView)
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        print(pagingMenuController.currentPage)
    }
    
    func didMoveToMenuItemView(menuItemView: MenuItemView, previousMenuItemView: MenuItemView) {
        print(#function)
        print(previousMenuItemView)
        print(menuItemView)
        let pagingMenuController = self.childViewControllers.first as! PagingMenuController
        print(pagingMenuController.currentPage)
    }
}