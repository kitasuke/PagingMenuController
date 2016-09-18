//
//  GestureHandler.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 6/10/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import Foundation

protocol GestureHandler {
    func addTapGestureHandler()
    func addSwipeGestureHandler()
    func handleTapGesture(_ recognizer: UITapGestureRecognizer)
    func handleSwipeGesture(_ recognizer: UISwipeGestureRecognizer)
}

extension GestureHandler {
    var tapGestureRecognizer: UITapGestureRecognizer {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PagingMenuController.handleTapGesture))
        gestureRecognizer.numberOfTapsRequired = 1
        return gestureRecognizer
    }
    
    var leftSwipeGestureRecognizer: UISwipeGestureRecognizer {
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(PagingMenuController.handleSwipeGesture))
        gestureRecognizer.direction = .left
        return gestureRecognizer
    }
    
    var rightSwipeGestureRecognizer: UISwipeGestureRecognizer {
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(PagingMenuController.handleSwipeGesture))
        gestureRecognizer.direction = .right
        return gestureRecognizer
    }
}
