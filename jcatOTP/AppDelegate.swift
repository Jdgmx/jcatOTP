//
//  AppDelegate.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 7/31/20.
//  Copyright © 2020 jCat.io. All rights reserved.

import Cocoa
import LocalAuthentication
import CryptoKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate
{
	static var decryptKey: SymmetricKey?
	
	@IBOutlet weak var preferencesWindow: NSWindow!
	@IBOutlet weak var onReturn: NSButton!
	@IBOutlet weak var onSelection: NSButton!

	var mainWindowController: NSWindowController? = nil

	private let context = LAContext()
	private let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .userPresence, nil)

	func applicationDidFinishLaunching(_ aNotification: Notification)
	{
		// Create the default preferences
		if !((UserDefaults.standard.value(forKey: "defaults") as? Bool) ?? false) {
			setDefaultPreferences()
		}

		NSWindow.allowsAutomaticWindowTabbing = false // we don't like tabs
		NSApp.servicesProvider = OTPService.shared // Our service provider
		ValueTransformer.setValueTransformer(OTPTransformer(), forName: OTPTransformer.name) // register otp transformer

		if authenticateApp() {
			try? OTPService.shared.restoreOtps() // load from file
			openMainWindow(self)
		} else {
			NSApp.terminate(self)
		}
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

// MARK: - Authentication

extension AppDelegate
{
	func authenticateApp() -> Bool
	{
		var success: Bool = false

		let query = [kSecClass: kSecClassKey,
						 kSecAttrAccessControl: access!,
						 kSecUseAuthenticationContext: context,
						 kSecAttrApplicationLabel: Bundle.main.bundleIdentifier!,
						 kSecAttrLabel: Bundle.main.object(forInfoDictionaryKey: "CFBundleName")!,
						 kSecMatchLimit: kSecMatchLimitOne,
						 kSecReturnData: true,
						 kSecUseOperationPrompt: "Authenticate to access your accounts."] as [String: Any]

		var item: CFTypeRef?
		let succ = SecItemCopyMatching(query as CFDictionary, &item)
		if succ == errSecSuccess {
			if let d = item as? Data {
				AppDelegate.decryptKey = SymmetricKey(data: d)
				success = AppDelegate.decryptKey != nil
			} else {
				success = createAndSaveKey()
			}
		} else {
			success = createAndSaveKey()
		}

		return success
	}

	private func createAndSaveKey() -> Bool
	{
		AppDelegate.decryptKey = SymmetricKey(size: .bits256) // create the key

		let key = AppDelegate.decryptKey!.withUnsafeBytes { Data($0) }
		let query = [kSecClass: kSecClassKey,
						 kSecAttrAccessControl: access!,
						 kSecUseAuthenticationContext: context,
						 kSecAttrApplicationLabel: Bundle.main.bundleIdentifier!,
						 kSecAttrLabel: Bundle.main.object(forInfoDictionaryKey: "CFBundleName")!,
						 kSecUseDataProtectionKeychain: true,
						 kSecValueData: key] as [String: Any]

		let succ = SecItemAdd(query as CFDictionary, nil)

		return succ == errSecSuccess
	}
}
