//
//  PageDetectable.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 6/10/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import Foundation

enum PagingViewPosition {
    case left, center, right, unknown
    
    init(order: Int) {
        switch order {
        case 0: self = .left
        case 1: self = .center
        case 2: self = .right
        default: self = .unknown
        }
    }
}

protocol PageDetectable {
    var currentPagingViewPosition: PagingViewPosition { get }
    var nextPageFromCurrentPosition: Int { get }
    var nextPageFromCurrentPoint: Int { get }
}
