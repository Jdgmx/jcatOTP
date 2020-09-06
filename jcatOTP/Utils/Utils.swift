//
//  Utils.swift
//  jcatOTP
//
//  Created by Joaquin Durand Gomez on 9/6/20.
//  Copyright © 2020 jCat.io. All rights reserved.
//

import Foundation

let fileName = "otps.jcat"

// Stores the OTPs in the array in a undisclosed location.
func store(otps: Array<OTPGenerator>) throws
{
	if let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
		let datas = try otps.compactMap { try $0.save() }
		let fileData = try PropertyListSerialization.data(fromPropertyList: datas, format: .binary, options: .zero)

		FileManager.default.createFile(atPath: dir.appendingPathComponent(fileName).path, contents: fileData, attributes: nil)
	}
}

// Restores an array of OTPs from a undisclosed location
func restoreOtps() throws -> Array<OTPGenerator>?
{
	if let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
		if let fileData = FileManager.default.contents(atPath: dir.appendingPathComponent(fileName).path) {
			if let datas = try PropertyListSerialization.propertyList(from: fileData, options: .mutableContainers, format: nil) as? Array<Data> {
				return datas.compactMap { OTPRestore(from: $0) }
			}
		}
	}

	return nil
}
