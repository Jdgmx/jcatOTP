//
//  AppDelegate.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 7/31/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//
// See: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/SysServices/introduction.html

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
	@IBOutlet weak var window: NSWindow!

	var mainWindowController: NSWindowController? = nil

	func applicationDidFinishLaunching(_ aNotification: Notification)
	{
		// Insert code here to initialize your application

		openMainWindow()
	}

	func applicationWillTerminate(_ aNotification: Notification)
	{
		// Insert code here to tear down your application
	}

	// MARK: stuff

	func openMainWindow()
	{
		if mainWindowController == nil {
			mainWindowController = NSStoryboard(name: "MainWindow", bundle: nil).instantiateInitialController()

			/**/ NSLog("mainWindowController = \(String(describing: mainWindowController))")
		}

		mainWindowController?.showWindow(self)
	}

}
