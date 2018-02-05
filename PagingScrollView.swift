//
//  PagingScrollView.swift
//  Pods
//
//  Created by dudongge on 2018/2/5.
//

import UIKit
//Add the system's return gesture.
class PagingScrollView: UIScrollView {

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) {
            let pan: UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
            if pan.translation(in: self).x > 0.0 && self.contentOffset.x == 0.0 {
                return false
            }
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

}
