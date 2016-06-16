![](https://raw.githubusercontent.com/wiki/kitasuke/PagingMenuController/images/logo.png)

[![CI Status](http://img.shields.io/travis/kitasuke/PagingMenuController.svg?style=flat)](https://travis-ci.org/kitasuke/PagingMenuController)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/kitasuke/PagingMenuController)
[![Version](https://img.shields.io/cocoapods/v/PagingMenuController.svg?style=flat)](http://cocoapods.org/pods/PagingMenuController)
[![License](https://img.shields.io/cocoapods/l/PagingMenuController.svg?style=flat)](http://cocoapods.org/pods/PagingMenuController)
[![Platform](https://img.shields.io/cocoapods/p/PagingMenuController.svg?style=flat)](http://cocoapods.org/pods/PagingMenuController)
![Swift 2.2.x](https://img.shields.io/badge/Swift-2.2.x-orange.svg)

This library is inspired by [PageMenu](https://github.com/uacaps/PageMenu)

## Updates

See [CHANGELOG](https://github.com/kitasuke/PagingMenuController/blob/master/CHANGELOG.md) for details

## Description

### Standard mode with flexible item width

<img src="https://raw.githubusercontent.com/wiki/kitasuke/PagingMenuController/images/demo4.gif" width="160" height="284">

### Segmented control mode

<img src="https://raw.githubusercontent.com/wiki/kitasuke/PagingMenuController/images/demo2.gif" width="284" height="160">

### Infinite mode with fixed item width

<img src="https://raw.githubusercontent.com/wiki/kitasuke/PagingMenuController/images/demo3.gif" width="160" height="284">

## Customization

### PagingMenuControllerCustomizable

* default page index to show as a first view
```Swift
defaultPage: Int
```

* duration for paging view animation
```Swift
animationDuration: NSTimeInterval
```

* scrollEnabled for paging view. **Set false in case of using swipe-to-delete on your table view**
```swift
scrollEnabled: Bool
```

* background color for paging view
```Swift
backgroundColor: UIColor
```

* number of lazy loading pages
```swift
lazyLoadingPage: LazyLoadingPage
public enum LazyLoadingPage {
    case One // Currently sets false to scrollEnabled at this moment. Should be fixed in the future.
    case Three
}
```

* a set of menu controller
```swift
menuControllerSet: MenuControllerSet
public enum MenuControllerSet {
        case Single
        case Multiple
    }
```

* component type of PagingMenuController
```swift
componentType: ComponentType
public enum ComponentType {
    case MenuView(menuOptions: MenuViewCustomizable)
    case PagingController(pagingControllers: [UIViewController])
    case All(menuOptions: MenuViewCustomizable, pagingControllers: [UIViewController])
}
```

### MenuViewCustomizable

* background color for menu view
```Swift
backgroundColor: UIColor
```

* background color for selected menu item
```Swift
selectedBackgroundColor: UIColor
```

* height for menu view
```Swift
height: CGFloat
```

* duration for menu view animation
```Swift
animationDuration: NSTimeInterval
```

* decelerating rate for menu view
```swift
deceleratingRate: CGFloat
```

* menu item position
```swift
menuSelectedItemCenter: Bool
```

* menu mode and scrolling mode

```swift
displayMode: MenuDisplayMode

public enum MenuDisplayMode {
    case Standard(widthMode: MenuItemWidthMode, centerItem: Bool, scrollingMode: MenuScrollingMode)
    case SegmentedControl
    case Infinite(widthMode: MenuItemWidthMode, scrollingMode: MenuScrollingMode) // Requires three paging views at least
}

public enum MenuItemWidthMode {
    case Flexible
    case Fixed(width: CGFloat)
}

public enum MenuScrollingMode {
  case ScrollEnabled
  case ScrollEnabledAndBouces
  case PagingEnabled
}
```

if `centerItem` is true, selected menu item is always on center

if `MenuScrollingMode` is `ScrollEnabled` or `ScrollEnabledAndBouces`, menu view allows scrolling to select any menu item
if `MenuScrollingMode` is `PagingEnabled`, menu item should be selected one by one

* menu item focus mode
```Swift
focusMode: MenuFocusMode
public enum MenuFocusMode {
    case None
    case Underline(height: CGFloat, color: UIColor, horizontalPadding: CGFloat, verticalPadding: CGFloat)
    case RoundRect(radius: CGFloat, horizontalPadding: CGFloat, verticalPadding: CGFloat, selectedColor: UIColor)
}
```

* dummy item view number for Infinite mode
```swift
dummyItemViewsSet: Int
```

* menu position

```swift
menuPosition: MenuPosition

public enum MenuPosition {
    case Top
    case Bottom
}
```

* divider image to display right aligned in each menu item  

```swift
dividerImage: UIImage?
```

### MenuItemViewCustomizable

* horizontal margin for menu item
```swift
horizontalMargin: CGFloat
```

* menu item mode
```swift
displayMode: MenuItemDisplayMode
public enum MenuItemDisplayMode {
    case Text(title: MenuItemText)
    case MultilineText(title: MenuItemText, description: MenuItemText)
    case Image(image: UIImage, selectedImage: UIImage?)
    case Custom(view: UIView)
}
```

## Usage

`import PagingMenuController` to use PagingMenuController in your file.

### Using Storyboard

```Swift
struct MenuItem1: MenuItemViewCustomizable {}
struct MenuItem2: MenuItemViewCustomizable {}

struct MenuOptions: MenuViewCustomizable {
    var itemsOptions: [MenuItemViewCustomizable] {
        return [MenuItem1(), MenuItem2()]
    }
}

struct PagingMenuOptions: PagingMenuControllerCustomizable {
    var componentType: ComponentType {
        return .All(menuOptions: MenuOptions(), pagingControllers: [UIViewController(), UIViewController()])
    }
}

let pagingMenuController = self.childViewControllers.first as! PagingMenuController
pagingMenuController.delegate = self
pagingMenuController.setup(options)
```
* You should add `ContainerView` into your view controller's view and set `PagingMenuController` as the embedded view controller's class

See `PagingMenuControllerDemo` target in demo project for more details

### Coding only
```Swift
struct MenuItem1: MenuItemViewCustomizable {}
struct MenuItem2: MenuItemViewCustomizable {}

struct MenuOptions: MenuViewCustomizable {
    var itemsOptions: [MenuItemViewCustomizable] {
        return [MenuItem1(), MenuItem2()]
    }
}

struct PagingMenuOptions: PagingMenuControllerCustomizable {
    var componentType: ComponentType {
        return .All(menuOptions: MenuOptions(), pagingControllers: [UIViewController(), UIViewController()])
    }
}

let options = PagingMenuOptions()
let pagingMenuController = PagingMenuController(options: options)

addChildViewController(pagingMenuController)
view.addSubview(pagingMenuController.view)
pagingMenuController.didMoveToParentViewController(self)
```

See `PagingMenuControllerDemo2` target in demo project for more details

### Delegate methods (optional)

```Swift
pagingMenuController.delegate = self
```

```Swift
func willMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController) {
}

func didMoveToPageMenuController(menuController: UIViewController, previousMenuController: UIViewController) {
}

func willMoveToMenuItemView(menuItemView: MenuItemView, previousMenuItemView: MenuItemView) {
}

func didMoveToMenuItemView(menuItemView: MenuItemView, previousMenuItemView: MenuItemView) {
}
```

### Moving to a menu tag programmatically

```swift
// if you pass a nonexistent page number, it'll be ignored
pagingMenuController.moveToMenuPage(1, animated: true)
```

### Changing PagingMenuController's option

Call `setup` method with new options again.
It creates a new paging menu controller. Do not forget to cleanup properties in child view controller.

## Requirements

iOS8+  
Swift 2.2+  
Xcode 7.3+  

*Please use 0.8.0 tag for Swift 1.2*

## Installation

### CocoaPods
PagingMenuController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod "PagingMenuController"
```

Then, run `pod install`

In case you haven't installed CocoaPods yet, run the following command

```ruby
$ gem install cocoapods
```

### Carthage
PagingMenuController is available through [Carthage](https://github.com/Carthage/Carthage).

To install PagingMenuController into your Xcode project using Carthage, specify it in your Cartfile:

```ruby
github "kitasuke/PagingMenuController"
```

Then, run `carthage update`

You can see `Carthage/Build/iOS/PagingMenuController.framework` now, so drag and drop it to `Linked Frameworks and Libraries` in General menu tab with your project.
Add the following script to `New Run Script Phase` in Build Phases menu tab.
```ruby
/usr/local/bin/carthage copy-frameworks
```

Also add the following script in `Input Files`
```ruby
$(SRCROOT)/Carthage/Build/iOS/PagingMenuController.framework
```

In case you haven't installed Carthage yet, run the following command

```ruby
$ brew update
$ brew install carthage
```

### Manual

Copy all the files in `Pod/Classes` directory into your project.

## License

PagingMenuController is available under the MIT license. See the [LICENSE](https://github.com/kitasuke/PagingMenuController/blob/master/LICENSE) file for more info.
