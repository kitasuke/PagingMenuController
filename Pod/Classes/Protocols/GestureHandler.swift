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
    @objc optional func handleTapGesture(_ recognizer: UITapGestureRecognizer)
    @objc optional func handleSwipeGesture(_ recognizer: UISwipeGestureRecognizer)
}

extension GestureHandler {
    var tapGestureRecognizer: UITapGestureRecognizer {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PagingMenuController.handleTapGesture(_:)))
        gestureRecognizer.numberOfTapsRequired = 1
        return gestureRecognizer
    }
    
    var leftSwipeGestureRecognizer: UISwipeGestureRecognizer {
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(PagingMenuController.handleSwipeGesture(_:)))
        gestureRecognizer.direction = .left
        return gestureRecognizer
    }
    
    var rightSwipeGestureRecognizer: UISwipeGestureRecognizer {
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(PagingMenuController.handleSwipeGesture(_:)))
        gestureRecognizer.direction = .right
        return gestureRecognizer
    }
}
