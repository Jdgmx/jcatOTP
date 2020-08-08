//
//  NewOtpViewController.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 8/2/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Cocoa
import CryptoKit

class NewOtpViewController: NSViewController
{
	@IBOutlet dynamic var outlineVC: OutlineViewController?

	@objc dynamic var otpName: String?
	@objc dynamic var secret: String?
	@objc dynamic var digits: Int = 6
	@objc dynamic var period: Int = 30

	weak var ovc: OutlineViewController? = nil

	var encoding: DecodingScheme = .base32
	var algorithm: Int = 1

	override func viewDidLoad()
	{
		super.viewDidLoad()

		// tests
		otpName = "Staging"
		secret = "7OH6HVLLVW6VZRP7"
	}

	@IBAction func setEncoding(_ sender: Any?)
	{
		if let tag = (sender as? NSButton)?.tag {
			switch tag {
				case 100:
					encoding = .base32
				case 200:
					encoding = .zBase32
				case 300:
					encoding = .base64
				default:
					encoding = .none
			}
		}
	}

	@IBAction func setAlgorithm(_ sender: Any?)
	{
		if let tag = (sender as? NSButton)?.tag {
			switch tag {
				case 400:
					algorithm = 1
				case 500:
					algorithm = 2
				case 600:
					algorithm = 3
				default:
					algorithm = -1
			}
		}
	}

	@IBAction func ok(_ sender: Any)
	{
		guard (otpName != nil) && (secret != nil) else { return }
		guard ovc != nil else { return } // we must know the outline view controller
		
		switch algorithm {
			case 1:
				if let otp = OTP<Insecure.SHA1>(name: otpName!, secret: secret!, scheme: encoding, digits: digits, period: period) {
					ovc!.addOtp(otp)
			}
			case 2:
				if let otp = OTP<SHA256>(name: otpName!, secret: secret!, scheme: encoding, digits: digits, period: period) {
					ovc!.addOtp(otp)
			}
			case 3:
				if let otp = OTP<SHA512>(name: otpName!, secret: secret!, scheme: encoding, digits: digits, period: period) {
					ovc!.addOtp(otp)
			}
			default:
				break
		}
		
		dismiss(self)
	}

	@IBAction func cancel(_ sender: Any)
	{
		dismiss(self)
	}
}
