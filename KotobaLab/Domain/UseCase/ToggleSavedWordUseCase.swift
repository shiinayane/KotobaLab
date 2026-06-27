//
//  ToggleSavedWordUseCase.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/05/06.
//

struct ToggleSavedWordUseCase {
    let wordID: Int64
    private let userDataRepository: any UserDataRepositoryProtocol

    init(
        wordID: Int64,
        userDataRepository: any UserDataRepositoryProtocol
    ) {
        self.wordID = wordID
        self.userDataRepository = userDataRepository
    }

    func execute() throws -> Bool {
        guard try userDataRepository.isWordSaved(wordID: wordID) else {
            try userDataRepository.saveWord(wordID: wordID)
            return true
        }
        try userDataRepository.unsaveWord(wordID: wordID)
        return false
    }
}
