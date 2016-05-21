//
//  ViewController3.swift
//  PagingMenuControllerDemo
//
//  Created by Cheng-chien Kuo on 5/18/16.
//  Copyright © 2016 kitasuke. All rights reserved.
//

import UIKit
import PagingMenuController

class ViewController3: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.lightGrayColor()
        
        let textLabel = UILabel(frame: CGRectMake(0, 0, 200, 30))
        textLabel.center = view.center
        textLabel.textAlignment = .Center
        textLabel.font = UIFont.systemFontOfSize(24)
        textLabel.text = "View Controller 3"
        view.addSubview(textLabel)
        
        let button = UIButton(type: UIButtonType.System)
        button.setTitle("Change Menu", forState: UIControlState.Normal)
        button.frame = CGRectMake(80, 300, 300, 30)
        button.titleLabel!.textColor = UIColor.blackColor()
        view.addSubview(button)
        
        button.addTarget(self, action: #selector(ViewController3.buttonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    func buttonTapped(sender: UIButton) {
        self.menuItemDescription = "Changed"
        self.updateMenuContent()
    }
}
