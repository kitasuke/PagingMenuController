//
//  PagingValidator.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 6/9/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import Foundation

protocol PagingValidator {
    func validate(options: PagingMenuControllerCustomizable)
}

extension PagingValidator {
    func validate(options: PagingMenuControllerCustomizable) {
        validateDefaultPage(options)
        validateContentsCount(options)
        validateInfiniteMenuItemNumbers(options)
    }
    
    private func validateContentsCount(options: PagingMenuControllerCustomizable) {
        switch options.componentType {
        case .All(let menuOptions, let pagingControllers):
            guard menuOptions.itemsOptions.count == pagingControllers.count else {
                raise("number of menu items and view controllers doesn't match")
                return
            }
        default: break
        }
    }
    
    private func validateDefaultPage(options: PagingMenuControllerCustomizable) {
        let maxCount: Int
        switch options.componentType {
        case .PagingController(let pagingControllers): maxCount = pagingControllers.count
        case .All(_, let pagingControllers):
            maxCount = pagingControllers.count
        case .MenuView(let menuOptions): maxCount = menuOptions.itemsOptions.count
        }
        
        guard options.defaultPage >= maxCount || options.defaultPage < 0 else { return }
        
        raise("default page is invalid")
    }
    
    private func validateInfiniteMenuItemNumbers(options: PagingMenuControllerCustomizable) {
        guard case .All(let menuOptions, _) = options.componentType,
            case .Infinite = menuOptions.displayMode else { return }
        guard menuOptions.itemsOptions.count < VisiblePagingViewNumber else { return }
        
        raise("number of view controllers should be more than three with Infinite display mode")
    }
    
    private var exceptionName: String {
        return "PMCException"
    }
    
    private func raise(reason: String) {
        NSException(name: exceptionName, reason: reason, userInfo: nil).raise()
    }
}