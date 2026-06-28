//
//  LoadWordDetailUseCase.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/05/06.
//

struct LoadWordDetailUseCase {
    let wordID: Int64
    private let dictionaryRepository: any DictionaryRepositoryProtocol
    private let userDataRepository: any UserDataRepositoryProtocol

    init(
        wordID: Int64,
        dictionaryRepository: any DictionaryRepositoryProtocol,
        userDataRepository: any UserDataRepositoryProtocol
    ) {
        self.wordID = wordID
        self.dictionaryRepository = dictionaryRepository
        self.userDataRepository = userDataRepository
    }

    func execute() async throws -> WordDetailDisplayData? {
        let fetchedDetail = try await dictionaryRepository.fetchWordDetail(wordID: wordID)

        guard let fetchedDetail else {
            return nil
        }
        let isSaved = (try? userDataRepository.isWordSaved(wordID: wordID)) ?? false
        return WordDetailDisplayData(
            detail: fetchedDetail,
            isSaved: isSaved
        )
    }
}
