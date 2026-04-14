//
//  PreviewHelpers.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/02.
//

extension SearchStore {
    static func previewWithResults() -> SearchStore {
        let store = SearchStore(
            dictionaryRepository: MockDictionaryRepository()
        )
        store.query = "食"
        store.search()
        return store
    }
}
