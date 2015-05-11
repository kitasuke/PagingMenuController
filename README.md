![](https://raw.githubusercontent.com/wiki/kitasuke/PagingMenuController/images/logo.png)

[![CI Status](http://img.shields.io/travis/kitasuke/PagingMenuController.svg?style=flat)](https://travis-ci.org/kitasuke/PagingMenuController)
[![Version](https://img.shields.io/cocoapods/v/PagingMenuController.svg?style=flat)](http://cocoapods.org/pods/PagingMenuController)
[![License](https://img.shields.io/cocoapods/l/PagingMenuController.svg?style=flat)](http://cocoapods.org/pods/PagingMenuController)
[![Platform](https://img.shields.io/cocoapods/p/PagingMenuController.svg?style=flat)](http://cocoapods.org/pods/PagingMenuController)

## Display Mode

### Flexible menu item label width based mode

<img src="https://raw.githubusercontent.com/wiki/kitasuke/PagingMenuController/images/demo1.gif" width="160" height="284">

### Fixed menu item label width based mode

<img src="https://raw.githubusercontent.com/wiki/kitasuke/PagingMenuController/images/demo2.gif" width="284" height="160">

### Segmented control like menu mode

<img src="https://raw.githubusercontent.com/wiki/kitasuke/PagingMenuController/images/demo3.gif" width="160" height="284">

## Customization

* default page index to show as a first view
```Swift
defaultPage: Int
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
* menu display mode and scrolling mode
```Swift
menuDisplayMode: MenuDisplayMode

public enum MenuDisplayMode {
  case FlexibleItemWidth(centerItem: Bool, scrollingMode: MenuScrollingMode)
  case FixedItemWidth(width: CGFloat, centerItem: Bool, scrollingMode: MenuScrollingMode)
  case SegmentedControl
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

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

PagingMenuController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "PagingMenuController"
```

## Author

kitasuke, yusuke2759@gmail.com

## License

PagingMenuController is available under the MIT license. See the LICENSE file for more info.
