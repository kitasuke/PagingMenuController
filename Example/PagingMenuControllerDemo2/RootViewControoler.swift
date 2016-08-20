//
//  RootViewControoler.swift
//  PagingMenuControllerDemo
//
//  Created by Cheng-chien Kuo on 5/14/16.
//  Copyright © 2016 kitasuke. All rights reserved.
//

import UIKit
import PagingMenuController

private struct PagingMenuOptions: PagingMenuControllerCustomizable {
    fileprivate var componentType: ComponentType {
        return .all(menuOptions: MenuOptions(), pagingControllers: pagingControllers)
    }
    
    fileprivate var pagingControllers: [UIViewController] {
        let viewController1 = ViewController1()
        let viewController2 = ViewController2()
        return [viewController1, viewController2]
    }
    
    fileprivate struct MenuOptions: MenuViewCustomizable {
        var displayMode: MenuDisplayMode {
            return .segmentedControl
        }
        var itemsOptions: [MenuItemViewCustomizable] {
            return [MenuItem1(), MenuItem2()]
        }
    }
    
    fileprivate struct MenuItem1: MenuItemViewCustomizable {
        var displayMode: MenuItemDisplayMode {
            return .text(title: MenuItemText(text: "First Menu"))
        }
    }
    fileprivate struct MenuItem2: MenuItemViewCustomizable {
        var displayMode: MenuItemDisplayMode {
            return .text(title: MenuItemText(text: "Second Menu"))
        }
    }
}

class RootViewControoler: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.white
        
        let options = PagingMenuOptions()
        let pagingMenuController = PagingMenuController(options: options)
        pagingMenuController.view.frame.origin.y += 64
        pagingMenuController.view.frame.size.height -= 64
        
        addChildViewController(pagingMenuController)
        view.addSubview(pagingMenuController.view)
        pagingMenuController.didMove(toParentViewController: self)
    }
}
