//
//  LabelSizeCalculatable.swift
//  PagingMenuController
//
//  Created by Yusuke Kita on 6/10/16.
//  Copyright (c) 2016 kitasuke. All rights reserved.
//

import Foundation

protocol LabelSizeCalculatable {
    func labelWidth(_ widthMode: MenuItemWidthMode, estimatedSize: CGSize) -> CGFloat
    func estimatedLabelSize(_ label: UILabel) -> CGSize
    func calculateLabelSize(_ label: UILabel, maxWidth: CGFloat) -> CGSize
}
