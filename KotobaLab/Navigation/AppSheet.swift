//
//  AppSheet.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/03/29.
//

import Foundation

enum AppSheet: Identifiable {
    case settings
    
    var id: String {
        switch self {
        case .settings:
            return "settings"
        }
    }
}
