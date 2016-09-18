//
//  PageLoadable.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 6/10/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import Foundation

protocol PageLoadable {
    func shouldLoad(page: Int) -> Bool
    func isVisible(controller: UIViewController) -> Bool
    func showVisibleControllers()
    func hideVisibleControllers()
}
