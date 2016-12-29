//
//  PagingMenuScrollEventsDelegate.swift
//  PagingMenuController
//
//  Created by Solomon Sammy on 29/Dec/2016.
//  Copyright © 2016 kitasuke. All rights reserved.
//

import Foundation

public protocol PagingMenuScrollEventsDelegate: class {

    /**
     * PagingMenuController calls this when scrolling has started.
     * Use it to disable background tasks when scrolling.
     */
    func scrollingStarted()

    /**
     * PagingMenuController calls this when scrolling has ended.
     * Use it to enable background tasks when scrolling.
     */
    func scrollingEnded()
}
