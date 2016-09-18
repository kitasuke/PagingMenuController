//
//  MenuItemMultipliable.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 6/10/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import Foundation

protocol MenuItemMultipliable {
    var menuItemCount: Int { get }
    func rawPage(_ page: Int) -> Int
}
