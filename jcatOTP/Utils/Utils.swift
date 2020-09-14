//
//  Utils.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 9/6/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Foundation

class OTPFormatter: Formatter
{
	override func string(for obj: Any?) -> String?
	{
		if let str = obj as? String {
			if str.count <= 3 {
				return str
			} else {
				let h = str.index(str.startIndex, offsetBy: str.count/2)
				let lhs = str.prefix(upTo: h)
				let rhs = str.suffix(from: h)

				return self.string(for: String(lhs))! + " " + self.string(for: String(rhs))!
			}
		} else {
			return nil
		}
	}
}

class OTPTransformer: ValueTransformer
{
	static let name = NSValueTransformerName(rawValue: "OTPTransformer")

	override class func transformedValueClass() -> AnyClass
	{
		return NSString.self
	}

	override class func allowsReverseTransformation() -> Bool
	{
		return false
	}

	override func transformedValue(_ value: Any?) -> Any?
	{
		if let s = value as? String {
			return OTPFormatter().string(for: s)
		} else {
			return nil
		}
	}
}
