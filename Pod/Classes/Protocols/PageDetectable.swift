//
//  PageDetectable.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 6/10/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import Foundation

enum PagingViewPosition {
    case Left, Center, Right, Unknown
    
    init(order: Int) {
        switch order {
        case 0: self = .Left
        case 1: self = .Center
        case 2: self = .Right
        default: self = .Unknown
        }
    }
}

protocol PageDetectable {
    var currentPagingViewPosition: PagingViewPosition { get }
    var nextPageFromCurrentPosition: Int { get }
    var nextPageFromCurrentPoint: Int { get }
}