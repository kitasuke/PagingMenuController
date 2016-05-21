//
//  RootViewController.swift
//  PagingMenuControllerDemo
//
//  Created by Yusuke Kita on 5/10/15.
//  Copyright (c) 2015 kitasuke. All rights reserved.
//

import UIKit
import PagingMenuController

private enum Section {
    case All(content: AllContent)
    case MenuView(content: MenuViewContent)
    case MenuController(content: MenuControllerContent)
    
    private enum AllContent: Int { case Standard, SegmentedControl, Infinite }
    private enum MenuViewContent: Int { case Underline, RoundRect }
    private enum MenuControllerContent: Int { case Standard, Infinite }
    
    init?(indexPath: NSIndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, let row):
            guard let content = AllContent(rawValue: row) else { return nil }
            self = .All(content: content)
        case (1, let row):
            guard let content = MenuViewContent(rawValue: row) else { return nil }
            self = .MenuView(content: content)
        case (2, let row):
            guard let content = MenuControllerContent(rawValue: row) else { return nil }
            self = .MenuController(content: content)
        default: return nil
        }
    }
    
    var options: PagingMenuOptions {
        let options = PagingMenuOptions()
        switch self {
        case .All(let content):
            switch content {
            case .Standard:
                options.menuDisplayMode = .Standard(widthMode: .Flexible, centerItem: false, scrollingMode: .PagingEnabled)
                options.menuItemMode = .None
                options.menuHeight = 60
            case .SegmentedControl:
                options.menuDisplayMode = .SegmentedControl
                options.menuControllerSet = .Single
            case .Infinite:
                options.menuDisplayMode = .Infinite(widthMode: .Fixed(width: 80), scrollingMode: .ScrollEnabled)
                options.menuItemMode = .None
                options.lazyLoadingPage = .Three
            }
        case .MenuView(let content):
            options.menuComponentType = .MenuView
            switch content {
            case .Underline:
                options.menuItemMode = .Underline(height: 3, color: UIColor.blueColor(), horizontalPadding: 10, verticalPadding: 0)
                options.menuDisplayMode = .SegmentedControl
            case .RoundRect:
                options.menuItemMode = .RoundRect(radius: 12, horizontalPadding: 8, verticalPadding: 8, selectedColor: UIColor.lightGrayColor())
                options.menuDisplayMode = .Infinite(widthMode: .Flexible, scrollingMode: .PagingEnabled)
            }
        case .MenuController(let content):
            options.menuComponentType = .MenuController
            switch content {
            case .Standard:
                options.defaultPage = 1
            case .Infinite:
                options.menuDisplayMode = .Infinite(widthMode: .Flexible, scrollingMode: .PagingEnabled)
            }
        }
        return options
    }
}

class RootViewController: UITableViewController {
    private var contents = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPathForCell(cell),
            let sectionType = Section(indexPath: indexPath),
            let viewController = segue.destinationViewController as? PagingMenuViewController else { return }
        
        viewController.title = cell.textLabel?.text
        switch sectionType {
        case .All(let content) where content == .Standard:
            viewController.menuItemDescription = "Description"
        default: break
        }
        viewController.options = sectionType.options
    }
}

