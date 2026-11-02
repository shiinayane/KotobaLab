//
//  AppGroup.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/11/01.
//

import Foundation

/// The container the app shares with its extensions.
enum AppGroup {
    static let identifier = "group.com.shiinayane.kotobalab"

    /// Where installed dictionary packs live, or `nil` without the App Group entitlement.
    static var dictionariesDirectory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)?
            .appending(
                path: "Library/Application Support/Dictionaries",
                directoryHint: .isDirectory
            )
    }
}
