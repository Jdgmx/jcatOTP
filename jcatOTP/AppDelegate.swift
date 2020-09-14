//
//  AppDelegate.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 7/31/20.
//  Copyright © 2020 jCat.io. All rights reserved.

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
		// Create the default preferences
		if !((UserDefaults.standard.value(forKey: "defaults") as? Bool) ?? false) {
			setDefaultPreferences()
		}

		// Our service provider
		NSApp.servicesProvider = OTPService.shared

		// register otp transformer
		ValueTransformer.setValueTransformer(OTPTransformer(), forName: OTPTransformer.name)

		// load from file
		try? OTPService.shared.restoreOtps()
		openMainWindow(self)
	}

	func applicationWillTerminate(_ aNotification: Notification)
	{
		try? OTPService.shared.store() // save to file
	}

	// MARK: Stuff

	@IBAction func openMainWindow(_ sender: Any?)
	{
		if mainWindowController == nil {
			mainWindowController = NSStoryboard(name: "TableWindow", bundle: nil).instantiateInitialController()
		}

		mainWindowController?.showWindow(self)
	}

	@IBAction func orderFrontJCatAboutPanel(_ sender: Any?)
	{
		NSApp.orderFrontStandardAboutPanel(options: [NSApplication.AboutPanelOptionKey.applicationIcon: NSImage(named: "jcat")!]) // gato negro gato blanco
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

	// Action of both radios in the preferences
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
