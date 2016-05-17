//
//  ViewController1.swift
//  PagingMenuControllerDemo
//
//  Created by Yusuke Kita on 5/10/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit
import PagingMenuController

class ViewController1: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.lightGrayColor()
        
        let textLabel = UILabel(frame: CGRectMake(0, 0, 200, 30))
        textLabel.center = view.center
        textLabel.textAlignment = .Center
        textLabel.font = UIFont.systemFontOfSize(24)
        textLabel.text = "View Controller 1"
        view.addSubview(textLabel)
        
        let button = UIButton(type: UIButtonType.System)
        button.setTitle("Change Menu", forState: UIControlState.Normal)
        button.frame = CGRectMake(80, 300, 300, 30)
        button.titleLabel!.textColor = UIColor.blackColor()
        view.addSubview(button)
        
        button.addTarget(self, action: #selector(ViewController1.buttonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
    }

    func buttonTapped(sender: UIButton) {
        self.menuItemDesc = "Changed"
        self.updateMenuContent()
    }
}