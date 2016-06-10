//
//  GestureHandler.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 6/10/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import Foundation

@objc protocol GestureHandler {
    func addTapGestureHandler()
    func addSwipeGestureHandler()
    optional func handleTapGesture(recognizer: UITapGestureRecognizer)
    optional func handleSwipeGesture(recognizer: UISwipeGestureRecognizer)
}

extension GestureHandler {
    var tapGestureRecognizer: UITapGestureRecognizer {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PagingMenuController.handleTapGesture(_:)))
        gestureRecognizer.numberOfTapsRequired = 1
        return gestureRecognizer
    }
    
    var leftSwipeGestureRecognizer: UISwipeGestureRecognizer {
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(PagingMenuController.handleSwipeGesture(_:)))
        gestureRecognizer.direction = .Left
        return gestureRecognizer
    }
    
    var rightSwipeGestureRecognizer: UISwipeGestureRecognizer {
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(PagingMenuController.handleSwipeGesture(_:)))
        gestureRecognizer.direction = .Right
        return gestureRecognizer
    }
}