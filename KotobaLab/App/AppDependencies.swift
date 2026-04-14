//
//  AppDependencies.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/14.
//

import SwiftData

struct AppDependencies {
    let dictionaryRepository: any DictionaryRepositoryProtocol
    
    let userDataRepositoryFactory: UserDataRepositoryFactory
}

struct UserDataRepositoryFactory {
    let make: (ModelContext) -> any UserDataRepositoryProtocol
}
