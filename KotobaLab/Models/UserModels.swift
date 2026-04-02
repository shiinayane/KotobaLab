//
//  UserModels.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

import Foundation

//  For the future structure.
struct FavoriteItem: Identifiable, Hashable {
    let id: Int
    let title: String
    let url: URL
}
