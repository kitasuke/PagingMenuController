![](https://raw.githubusercontent.com/wiki/kitasuke/PagingMenuController/images/logo.png)

[![CI Status](http://img.shields.io/travis/kitasuke/PagingMenuController.svg?style=flat)](https://travis-ci.org/kitasuke/PagingMenuController)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/kitasuke/PagingMenuController)
[![Version](https://img.shields.io/cocoapods/v/PagingMenuController.svg?style=flat)](http://cocoapods.org/pods/PagingMenuController)
[![License](https://img.shields.io/cocoapods/l/PagingMenuController.svg?style=flat)](http://cocoapods.org/pods/PagingMenuController)
[![Platform](https://img.shields.io/cocoapods/p/PagingMenuController.svg?style=flat)](http://cocoapods.org/pods/PagingMenuController)

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

* default page index to show as a first view
```Swift
defaultPage: Int
```
* scrollEnabled for paging view. **Set false in case of using swipe-to-delete on your table view**
```swift
scrollEnabled: Bool
```
* background color for menu view
```Swift
backgroundColor: UIColor
```
* background color for selected menu item
```Swift
selectedBackgroundColor: UIColor
```
* text color for menu item
```Swift
textColor: UIColor
```
* text color for selected menu item
```Swift
selectedTextColor: UIColor
```
* font for menu item text
```Swift
font: UIFont
```
* font for selected menu item text
```Swift
selectedFont: UIFont
```
* menu position
```Swift
menuPosition: MenuPosition

public enum MenuPosition {
    case Top
    case Bottom
}
```
* height for menu view
```Swift
menuHeight: CGFloat
```
* margin for each menu item
```Swift
menuItemMargin: CGFloat
```
* duration for menu item view animation
```Swift
animationDuration: NSTimeInterval
```
* decelerating rate for menu view
```swift
deceleratingRate: CGFloat
```
* menu display mode and scrolling mode
```Swift
menuDisplayMode: MenuDisplayMode

public enum MenuDisplayMode {
    case Standard(widthMode: MenuItemWidthMode, centerItem: Bool, scrollingMode: MenuScrollingMode)
    case SegmentedControl
    case Infinite(widthMode: MenuItemWidthMode) // Requires three paging views at least
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

* menu item mode
```Swift
public var menuItemMode = MenuItemMode.Underline(height: 3, color: UIColor.whiteColor(), horizontalPadding: 0, verticalPadding: 0)
public enum MenuItemMode {
    case None
    case Underline(height: CGFloat, color: UIColor, horizontalPadding: CGFloat, verticalPadding: CGFloat)
    case RoundRect(radius: CGFloat, horizontalPadding: CGFloat, verticalPadding: CGFloat, selectedColor: UIColor)
}
```

## Usage

`import PagingMenuController` to use PagingMenuController in your file.

### Using Storyboard

```Swift
let viewController = self.storyboard?.instantiateViewControllerWithIdentifier("ViewController") as! ViewController
viewController.title = "Menu title"
let viewControllers = [viewController]

let pagingMenuController = self.childViewControllers.first as! PagingMenuController

let options = PagingMenuOptions()
options.menuHeight = 60
options.menuDisplayMode = .Standard(widthMode: .Flexible, centerItem: true, scrollingMode: .PagingEnabled)
pagingMenuController.setup(viewControllers: viewControllers, options: options)
```
* You should add `ContainerView` into your view controller's view and set `PagingMenuController` as the embedded view controller's class

See `PagingMenuControllerDemo` target in demo project for more details

### Coding only
```Swift
let viewController = UIViewController()
viewController.title = "Menu title"
let viewControllers = [viewController]

let options = PagingMenuOptions()
options.menuItemMargin = 5
options.menuDisplayMode = .SegmentedControl
let pagingMenuController = PagingMenuController(viewControllers: viewControllers, options: options)

self.addChildViewController(pagingMenuController)
self.view.addSubview(pagingMenuController.view)
pagingMenuController.didMoveToParentViewController(self)
```

See `PagingMenuControllerDemo2` target in demo project for more details

### Delegate methods (optional)

```Swift
pagingMenuController.delegate = self
```

```Swift
func willMoveToMenuPage(page: Int) {
}

func didMoveToMenuPage(page: Int) {
}
```

### Moving to a menu tag programatically 

```swift
// if you pass a nonexistent page number, it'll be ignored
pagingMenuController.moveToMenuPage(1, animated: true)
```

## Requirements

iOS8+  
Swift 1.2+  
Xcode 6.3+  

*For iOS7 support*  
Follow [Manual Installation](#manual)

*Swift 1.2*   
Please use swift_1.2 branch, but it doesn't have full features. **It's no longer maintained...**

Podfile  
`pod 'PagingMenuController', :git => 'https://github.com/kitasuke/PagingMenuController', :branch => 'swift_1.2'
`

Carfile  
`github "kitasuke/PagingMenuController" "swift_1.2"
`

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
