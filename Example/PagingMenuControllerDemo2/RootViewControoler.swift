//
//  RootViewControoler.swift
//  PagingMenuControllerDemo
//
//  Created by Cheng-chien Kuo on 5/14/16.
//  Copyright © 2016 kitasuke. All rights reserved.
//

import UIKit
import PagingMenuController

class RootViewControoler: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.whiteColor()
        
        let button = UIButton(type: UIButtonType.System)
        button.setTitle("Open Title Menu Controller", forState: UIControlState.Normal)
        button.frame = CGRectMake(80, 300, 300, 30)
        button.titleLabel!.textColor = UIColor.blackColor()
        view.addSubview(button)
        
        button.addTarget(self, action: #selector(RootViewControoler.buttonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        let multiLineButton = UIButton(type: UIButtonType.System)
        multiLineButton.setTitle("Open Multiline Menu Controller", forState: UIControlState.Normal)
        multiLineButton.frame = CGRectMake(80, 380, 300, 30)
        multiLineButton.titleLabel!.textColor = UIColor.blackColor()
        view.addSubview(multiLineButton)
        
        multiLineButton.addTarget(self, action: #selector(RootViewControoler.multiLineButtonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        let options = PagingMenuOptions()
        let navigationBarHeight = CGFloat(64)
        options.menuItemMargin = 5
        options.menuHeight = 40
        options.menuDisplayMode = .SegmentedControl
        options.menuItemMode = PagingMenuOptions.MenuItemMode.None

        let pagingMenuController = PagingMenuController(menuItemTypes: ["Viewable Menu1", "Viewable Menu 2"], options: options)
        pagingMenuController.view.frame.origin.y += navigationBarHeight
        pagingMenuController.view.frame.size.height -= navigationBarHeight
        view.addSubview(pagingMenuController.view)
    }
    
    func buttonTapped(sender: UIButton) {
        let vc = ViewController()
        vc.modalPresentationStyle = UIModalPresentationStyle.Popover
        presentViewController(vc, animated: true, completion: nil)
    }

    func multiLineButtonTapped(sender: UIButton) {
        let vc = MultiLineMenuViewController()
        vc.modalPresentationStyle = UIModalPresentationStyle.Popover
        presentViewController(vc, animated: true, completion: nil)
    }
}