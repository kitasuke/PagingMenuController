//
//  PagingMenuControllerOptions.swift
//  PagingMenuControllerDemo
//
//  Created by Yusuke Kita on 6/9/16.
//  Copyright © 2016 kitasuke. All rights reserved.
//

import Foundation
import PagingMenuController

private var pagingControllers: [UIViewController] {
    let usersViewController = UsersViewController.instantiateFromStoryboard()
    let repositoriesViewController = RepositoriesViewController.instantiateFromStoryboard()
    let gistsViewController = GistsViewController.instantiateFromStoryboard()
    let organizationsViewController = OrganizationsViewController.instantiateFromStoryboard()
    return [usersViewController, repositoriesViewController, gistsViewController, organizationsViewController]
}

struct MenuItemUsers: MenuItemViewCustomizable {}
struct MenuItemRepository: MenuItemViewCustomizable {}
struct MenuItemGists: MenuItemViewCustomizable {}
struct MenuItemOrganization: MenuItemViewCustomizable {}

struct PagingMenuOptions1: PagingMenuControllerCustomizable {
    var componentType: ComponentType {
        return .All(menuOptions: MenuOptions(), pagingControllers: pagingControllers)
    }
    
    struct MenuOptions: MenuViewCustomizable {
        var mode: MenuViewMode {
            return .Standard(widthMode: .Flexible, centerItem: false, scrollingMode: .PagingEnabled)
        }
        var focusMode: MenuFocusMode {
            return .None
        }
        var height: CGFloat {
            return 60
        }
        var itemsOptions: [MenuItemViewCustomizable] {
            return [MenuItemUsers(), MenuItemRepository(), MenuItemGists(), MenuItemOrganization()]
        }
    }
    
    struct MenuItemUsers: MenuItemViewCustomizable {
        var mode: MenuItemMode {
            let title = MenuItemText(text: "Menu")
            let description = MenuItemText(text: String(self))
            return .MultilineText(title: title, description: description)
        }
    }
    struct MenuItemRepository: MenuItemViewCustomizable {
        var mode: MenuItemMode {
            let title = MenuItemText(text: "Menu")
            let description = MenuItemText(text: String(self))
            return .MultilineText(title: title, description: description)
        }
    }
    struct MenuItemGists: MenuItemViewCustomizable {
        var mode: MenuItemMode {
            let title = MenuItemText(text: "Menu")
            let description = MenuItemText(text: String(self))
            return .MultilineText(title: title, description: description)
        }
    }
    struct MenuItemOrganization: MenuItemViewCustomizable {
        var mode: MenuItemMode {
            let title = MenuItemText(text: "Menu")
            let description = MenuItemText(text: String(self))
            return .MultilineText(title: title, description: description)
        }
    }
}

struct PagingMenuOptions2: PagingMenuControllerCustomizable {
    var componentType: ComponentType {
        return .All(menuOptions: MenuOptions(), pagingControllers: pagingControllers)
    }
    var menuControllerSet: MenuControllerSet {
        return .Single
    }
    
    struct MenuOptions: MenuViewCustomizable {
        var mode: MenuViewMode {
            return .SegmentedControl
        }
        var itemsOptions: [MenuItemViewCustomizable] {
            return [MenuItemUsers(), MenuItemRepository(), MenuItemGists(), MenuItemOrganization()]
        }
    }
}

struct PagingMenuOptions3: PagingMenuControllerCustomizable {
    var componentType: ComponentType {
        return .All(menuOptions: MenuOptions(), pagingControllers: pagingControllers)
    }
    var lazyLoadingPage: LazyLoadingPage {
        return .Three
    }
    
    struct MenuOptions: MenuViewCustomizable {
        var mode: MenuViewMode {
            return .Infinite(widthMode: .Fixed(width: 80), scrollingMode: .ScrollEnabled)
        }
        var itemsOptions: [MenuItemViewCustomizable] {
            return [MenuItemUsers(), MenuItemRepository(), MenuItemGists(), MenuItemOrganization()]
        }
    }
}

struct PagingMenuOptions4: PagingMenuControllerCustomizable {
    var componentType: ComponentType {
        return .MenuView(menuOptions: MenuOptions())
    }
    
    struct MenuOptions: MenuViewCustomizable {
        var mode: MenuViewMode {
            return .SegmentedControl
        }
        var focusMode: MenuFocusMode {
            return .Underline(height: 3, color: UIColor.blueColor(), horizontalPadding: 10, verticalPadding: 0)
        }
        var itemsOptions: [MenuItemViewCustomizable] {
            return [MenuItemUsers(), MenuItemRepository(), MenuItemGists(), MenuItemOrganization()]
        }
    }
}

struct PagingMenuOptions5: PagingMenuControllerCustomizable {
    var componentType: ComponentType {
        return .MenuView(menuOptions: MenuOptions())
    }
    
    struct MenuOptions: MenuViewCustomizable {
        var mode: MenuViewMode {
            return .Infinite(widthMode: .Flexible, scrollingMode: .PagingEnabled)
        }
        var focusMode: MenuFocusMode {
            return .RoundRect(radius: 12, horizontalPadding: 8, verticalPadding: 8, selectedColor: UIColor.lightGrayColor())
        }
        var itemsOptions: [MenuItemViewCustomizable] {
            return [MenuItemUsers(), MenuItemRepository(), MenuItemGists(), MenuItemOrganization()]
        }
    }
}

struct PagingMenuOptions6: PagingMenuControllerCustomizable {
    var componentType: ComponentType {
        return .PagingController(pagingControllers: pagingControllers)
    }
    var defaultPage: Int {
        return 1
    }
}