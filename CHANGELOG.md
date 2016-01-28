# 0.7.9 Release notes (2016/01-28)

### Bug fixed

- Fix crash when PagingMenuController is initialized asynchronously

# 0.7.8 Release notes (2016/01-07)

### Enhancements

- Crash fixes thanks to @patricks

# 0.7.7 Release notes (2015/12-20)

### Enhancements

- Make `moveToMenuPage` method public

# 0.7.6 Release notes (2015/11-30)

### Enhancements

- Enable override classes
- Memory performance improvements thanks to @benrudhart

# 0.7.5 Release notes (2015/11-2)

### Enhancements

- Significant improvements thanks to @ikesyo
- Make some properties public read only

# 0.7.4 Release notes (2015/10-24)

### Enhancements

- Small improvements

### Bug fixed

- `selectedFont`

# 0.7.3 Release notes (2015/10-19)

### Bug fixed

- Fix `backgroundColor` with `RoundRect` mode thanks to fabianpimminger
- `selectedFont` didn't work properly

# 0.7.2 Release notes (2015/10-18)

### Enhancements

- Add `deceleratingRate` for menu view

### Bug fixed

- Fix incorrect reload of content view

### Breaking changes

- Not allowed to subclass PagingMenuController any more

# 0.7.1 Release notes (2015/10-04)

### Enhancements

- Add `scrollEnabled` for paging view in case you want to swipe-to-delete on your table view

### Bug fixed

- lazy load of paging view works fine

# 0.7.0 Release notes (2015/09-30)

### Enhancements

- Add `Infinite` mode

### Breaking changes

- `Normal` display mode renamed to `Standard`

### Bug fixed

- `defaultPage` didn't work with specific options

# 0.6.1 Release notes (2015/09-20)

### Enhancements

- Supported `selectedFont`

### Bug fixed

- Significant bug fixes

# 0.6.0 Release notes (2015/09-15)

### Enhancements

- Big performance improvements. Won't load all the view controllers anymore.

### Bug fixed 

- Fix incorrect behaviour of delegate method

# 0.5.1 Release notes (2015/09-14)

### Enhancements

- Support animated `RoundRect`

### Breaking changes

- `RoundRect` associated values changed

# 0.5.0 Release notes (2015/09-06)

### Enhancements

- Support adding/deleting menu. Use `rebuild` method.

# 0.4.7 Release notes (2015/09-05)

### Enhancements

- Support onve view controller usage

# 0.4.6 Release notes (2015/09-01)

### Enhancements

- Underline view's width and height can be changed by using horizontal and vertical paddings
- Improve behaviour of example project

### Bug fixed

- Now copying all the files into your project works fine
- First step to support single view controller usage 

# 0.4.5 Release notes (2015/07-25)

### Enhancements

- Underline view is now animated with content view

# 0.4.4 Release notes (2015/07-15)

#### Bug fixed

- `centerItem` didn't work on device

# 0.4.3 Release notes (2015/07-13)

### Enhancements

- Menu position option (top or bottom)

# 0.4.2 Release notes (2015/07-12)

### Bug fixed

- Set appropriate contentInset for menu view in case implemented programmatically

# 0.4.1 Release notes (2015-07-05)

### Bug fixed

- Change option class to struct to change property value

# 0.4.0 Release notes (2015-07-04)

### Enhancements

- Change PagingMenuOptions structure from class to struct
- Support delegate methods to handle menu transition state

### Breaking changes

- Merge validator into PagingMenuController class

# 0.3.4 Release notes (2015-06-05)

### Enhancements

- Displaying only two menu items is now supported thanks to jeksys
- Small improvements

### Bugfixes

- Changed framework's deployment target to 8.0 for Carthage users thanks to alexcurylo
- Fixed AutoLayout constraints bug for rotating with SegmentedControl

# 0.3.3 Release notes (2015-05-29)

### Enhancements

- Separate RoundRect scale into horizontal and vertical one
- Add Validator class to validate options value

# 0.3.2 Release notes (2015-05-29)

### Enhancements

- Added new item mode, RoundRect
- Revert animation duration default value to 0.3
- Added CHANGELOG.md

# 0.3.1 Release notes (2015-05-17)

### Enhancements

- Created `PagingMenuOptions.swift` to separate class declaration from `PagingMenuController.swift`
- Added validator for `default page` option

### Bugfixes

- Fixed unexpected behavior of `default page` option

# 0.3.0 Release notes (2015-05-16)

### Enhancements

- Added `MenuItemMode` to change menu item design (`RoundRect` mode is not supported yet at this time)

# 0.2.3 Release notes (2015-05-15)

### Bugfixes

- Fixed `self` in closure to resolve strong reference cycle

# 0.2.2 Release notes (2015-05-11)

### Bugfixes

- Fixed incorrect accessors for some methods

# 0.2.1 Release notes (2015-05-11)

### Bugfixes

- Added some files for Carthage

# 0.2.0 Release notes (2015-05-11)

### Enhancements

- Support Carthage

# 0.1.0 Release notes (2015-05-10)

### Enhancements

- Support CocoaPods
- Created demo project
