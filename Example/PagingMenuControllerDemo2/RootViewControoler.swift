//
//  RootViewControoler.swift
//  PagingMenuControllerDemo
//
//  Created by Cheng-chien Kuo on 5/14/16.
//  Copyright © 2016 kitasuke. All rights reserved.
//

import UIKit

class RootViewControoler: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.whiteColor()
        
        let button = UIButton(type: UIButtonType.System)
        button.setTitle("Open Menu Controller", forState: UIControlState.Normal)
        button.frame = CGRectMake(0, 0, 200, 30)
        button.center = view.center
        button.titleLabel!.textColor = UIColor.blackColor()
        view.addSubview(button)
        
        button.addTarget(self, action: #selector(RootViewControoler.buttonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    func buttonTapped(sender: UIButton) {
        let vc = ViewController()
        vc.modalPresentationStyle = UIModalPresentationStyle.Popover
        presentViewController(vc, animated: true, completion: nil)
    }
}