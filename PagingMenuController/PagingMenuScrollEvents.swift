//
//  PagingMenuScrollEvents.swift
//  PagingMenuController
//
//  Created by Solomon Sammy on 29/Dec/2016.
//  Copyright © 2016 kitasuke. All rights reserved.
//

import Foundation

/**
 * Use like:
 *   let pagingMenuScrollEvents = PagingMenuScrollEvents.sharedInstance
 *   pagingMenuScrollEvents.addScrollEventsDelegate(self.appDelegate.driveController)
 *
 *   ...
 *
 *   pagingMenuScrollEvents.addScrollEventsDelegate(this)
 *
 *   ...
 */

public class PagingMenuScrollEvents {

    // Can't init is singleton
    private init() {
    }

    //MARK: Shared Instance

    public static let sharedInstance: PagingMenuScrollEvents = PagingMenuScrollEvents()
    
    //MARK: Local Variable
    public var scrollEventsDelegates = [PagingMenuScrollEventsDelegate]()

    /**
     * Add a delegate to the list of delgates to be informed of scrolling events.
     *
     *  - parameter delegate: the callback to be invoked when scrolling is started or stopped.
     */
    public func addScrollEventsDelegate(_ delegate: PagingMenuScrollEventsDelegate) {
        scrollEventsDelegates.append(delegate)
    }

    /**
     * Remove a delegate from the list of delgates to be informed of scrolling events.
     *
     *  - parameter delegate: the callback to be invoked when scrolling is started or stopped.
     */
    public func removeScrollEventsDelegate(_ delegate: PagingMenuScrollEventsDelegate) {
        for (index, value) in scrollEventsDelegates.enumerated() {
            if (value === delegate) {
                scrollEventsDelegates.remove(at: index)
            }
        }
    }

    /**
     * Remove all delegates from the list of delgates to be informed of scrolling events.
     */
    public func removeAllScrollEventsDelegates() {
        scrollEventsDelegates.removeAll()
    }

}
