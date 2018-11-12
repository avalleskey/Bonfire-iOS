# Bonfire-iOS

This repo hosts the Bonfire iOS app source code.

## Prerequisites

You MUST have the following things properly installed and setup on your development device.

* [Git](https://git-scm.com/)
* [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12)
* [CocoaPods](https://cocoapods.org/)

## Setup

### 1) Xcode
* Launch Xcode
* Navigate in your Menu Bar to *Xcode* -> *Preferences* -> *Accounts*
* Click + in the bottom left corner to add your eligible Github account
* Close Preferences
* Select "Clone an existing project" on the Welcome to Xcode splash screen (accessible through ⌘ + Shift + 1)
* Choose Bonfire-iOS from the list and proceed to select a location to save the repo
* Great! Now close out of Xcode. Do not touch the .xcproject file that just opened!

### 2) CocoaPods
CocoaPods are essentially Rub gems for iOS. CocoaPods allow us to easily add and remove external libraries from our project. As such, be sure to *always* open the .xcworkspace file, _not_ the .xcproject file.
* Open Terminal
* `cd PROJECT_FOLDER` with PROJECT_FOLDER representing the Bonfire-iOS location from above
* `pod install`

### 3) Using GitHub in Xcode
_Commit:_
* Navigate in your Menu Bar to *Xcode* -> *Source Control* -> *Commit...*
* Select files in left sidebar to commit
* Add commit message on bottom
* Commit x Files

_Push:_
* Navigate in your Menu Bar to *Xcode* -> *Source Control* -> *Push...*

_Pull / Fetch & Refresh Status:_
* Navigate in your Menu Bar to *Xcode* -> *Source Control* -> *Fetch & Refresh Status...*
