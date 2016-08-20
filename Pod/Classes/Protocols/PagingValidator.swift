//
//  PagingValidator.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 6/9/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import Foundation

protocol PagingValidator {
    func validate(_ options: PagingMenuControllerCustomizable)
}

extension PagingValidator {
    func validate(_ options: PagingMenuControllerCustomizable) {
        validateDefaultPage(options)
        validateContentsCount(options)
        validateInfiniteMenuItemNumbers(options)
    }
    
    fileprivate func validateContentsCount(_ options: PagingMenuControllerCustomizable) {
        switch options.componentType {
        case .all(let menuOptions, let pagingControllers):
            guard menuOptions.itemsOptions.count == pagingControllers.count else {
                raise("number of menu items and view controllers doesn't match")
                return
            }
        default: break
        }
    }
    
    fileprivate func validateDefaultPage(_ options: PagingMenuControllerCustomizable) {
        let maxCount: Int
        switch options.componentType {
        case .pagingController(let pagingControllers): maxCount = pagingControllers.count
        case .all(_, let pagingControllers):
            maxCount = pagingControllers.count
        case .menuView(let menuOptions): maxCount = menuOptions.itemsOptions.count
        }
        
        guard options.defaultPage >= maxCount || options.defaultPage < 0 else { return }
        
        raise("default page is invalid")
    }
    
    fileprivate func validateInfiniteMenuItemNumbers(_ options: PagingMenuControllerCustomizable) {
        guard case .all(let menuOptions, _) = options.componentType,
            case .infinite = menuOptions.displayMode else { return }
        guard menuOptions.itemsOptions.count < VisiblePagingViewNumber else { return }
        
        raise("number of view controllers should be more than three with Infinite display mode")
    }
    
    fileprivate var exceptionName: String {
        return "PMCException"
    }
    
    fileprivate func raise(_ reason: String) {
        NSException(name: NSExceptionName(rawValue: exceptionName), reason: reason, userInfo: nil).raise()
    }
}
