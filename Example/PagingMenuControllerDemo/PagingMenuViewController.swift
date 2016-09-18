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
        pagingMenuController.setup(options)
    }
}

extension PagingMenuViewController: PagingMenuControllerDelegate {
    // MARK: - PagingMenuControllerDelegate
    func willMove(toMenu menuController: UIViewController, fromMenu previousMenuController: UIViewController) {
    }
    
    func didMove(toMenu menuController: UIViewController, fromMenu previousMenuController: UIViewController) {
    }
    
    func willMove(toMenuItem menuItemView: MenuItemView, fromMenuItem previousMenuItemView: MenuItemView) {
    }
    
    func didMove(toMenuItem menuItemView: MenuItemView, fromMenuItem previousMenuItemView: MenuItemView) {
    }
}
