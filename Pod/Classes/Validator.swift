//
//  Validator.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 5/29/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import Foundation

public class Validator {
    static func validate(options: PagingMenuOptions) {
        self.validateDefaultPage(options)
        self.validateRoundRectScaleIfNeeded(options)
    }
    
    private static func validateDefaultPage(options: PagingMenuOptions) {
        if options.defaultPage >= options.menuItemCount || options.defaultPage < 0 {
            NSException(name: ExceptionName, reason: "default page is invalid", userInfo: nil).raise()
        }
    }
    
    private static func validateRoundRectScaleIfNeeded(options: PagingMenuOptions) {
        switch options.menuItemMode {
        case .RoundRect(let radius, let horizontalScale, let verticalScale, let selectedColor):
            if horizontalScale < 0 || horizontalScale > 1 || verticalScale < 0 || verticalScale > 1 {
                NSException(name: ExceptionName, reason: "scale value should be between 0 and 1", userInfo: nil).raise()
            }
        default: break
        }
    }
}