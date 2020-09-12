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
	@IBOutlet weak var preferencesWindow: NSWindow!
	@IBOutlet weak var onReturn: NSButton!
	@IBOutlet weak var onSelection: NSButton!

	var mainWindowController: NSWindowController? = nil

	func applicationDidFinishLaunching(_ aNotification: Notification)
	{
		// Insert code here to initialize your application
		if !((UserDefaults.standard.value(forKey: "defaults") as? Bool) ?? false) {
			setDefaultPreferences()
		}

		NSApp.servicesProvider = OTPService.shared

		try? OTPService.shared.restoreOtps()
		openMainWindow(self)
	}

	func applicationWillTerminate(_ aNotification: Notification)
	{
		// Insert code here to tear down your application
		try? OTPService.shared.store()
	}

	// MARK: Stuff

	@IBAction func openMainWindow(_ sender: Any?)
	{
		if mainWindowController == nil {
			mainWindowController = NSStoryboard(name: "TableWindow", bundle: nil).instantiateInitialController()
		}

		mainWindowController?.showWindow(self)
	}
}

	// MARK: - Preferences

extension AppDelegate: NSWindowDelegate // we are the delegate of the preferences window
{
	@IBAction func openPreferences(_ sender: Any)
	{
		preferencesWindow?.makeKeyAndOrderFront(self)
	}

	func setDefaultPreferences()
	{
		let defaults = UserDefaults.standard

		defaults.setValue(true, forKey: "defaults")
		defaults.setValue(true, forKey: "copyOnReturn")
	}

	@IBAction func copyRadios(_ sender: NSButton)
	{
		if sender.tag == 100 { // on return
			UserDefaults.standard.setValue(true, forKey: "copyOnReturn")
		} else if sender.tag == 200 { // on select
			UserDefaults.standard.setValue(false, forKey: "copyOnReturn")
		}
	}

	func windowDidBecomeMain(_ notification: Notification)
	{
		let onr = UserDefaults.standard.value(forKey: "copyOnReturn") as? Bool ?? false

		onReturn.state = onr ? .on : .off
		onSelection.state = onr ? .off : .on
	}
}
