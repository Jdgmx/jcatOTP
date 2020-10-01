//
//  Utils.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 9/6/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published
//  by the Free Software Foundation, either version 3 of the License, or
//  any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  You should have received a copy of the GNU Affero General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.
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

// MARK: -

private let c = Calendar.current

func nextDateFor(period p: Int) -> Date?
{
	let date = Date()
	var dc = c.dateComponents([.minute, .second], from: date)

	// want to have the next moment where the time should fire
	if (dc.second! + p) > 60 {
		dc.second = 0
		dc.minute = (dc.minute! < 59) ? dc.minute! + 1 : 0
	} else {
		dc.second = p // BUG: we are skipping one case: p=20, second=30, fire at 40 should be valid
	}
	dc.nanosecond = 250000000 // want to be 1/4 a second ahead

	return c.nextDate(after: date, matching: dc, matchingPolicy: .nextTime)
}
