//
//  AppDependencies.swift
//  KotobaLab
//
//  Created by shiinayane on 2026/04/14.
//

import SwiftData

struct AppDependencies {
    let dictionaryRepository: any DictionaryRepositoryProtocol

    let userDataRepositoryFactory: UserDataRepositoryFactory
}

struct UserDataRepositoryFactory {
    let make: (ModelContext) -> any UserDataRepositoryProtocol
}
