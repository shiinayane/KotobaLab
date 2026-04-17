//
//  LoadSavedWordsUseCase.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/18.
//

struct LoadSavedWordsUseCase {
    private let dictionaryRepository: any DictionaryRepositoryProtocol
    private let userDataRepository: any UserDataRepositoryProtocol
    
    init(
        dictionaryRepository: any DictionaryRepositoryProtocol,
        userDataRepository: any UserDataRepositoryProtocol
    ) {
        self.dictionaryRepository = dictionaryRepository
        self.userDataRepository = userDataRepository
    }
    
    func execute() throws -> [WordSummary] {
        let savedWordIDs = try userDataRepository.fetchSavedWordIDs()
        return try dictionaryRepository.fetchWordSummaries(wordIDs: savedWordIDs)
    }
}
