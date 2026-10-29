//
//  FailingUserDataRepository.swift
//  KotobaLabTests
//
//  Created by shiinayane on 2026/10/29.
//

@testable import KotobaLab

/// A user data repository that fails reads, writes, or both.
///
/// When reads succeed, nothing is reported as saved.
final class FailingUserDataRepository: UserDataRepositoryProtocol {
    struct Failure: Error {}

    private let failsReads: Bool
    private let failsWrites: Bool

    init(failsReads: Bool = false, failsWrites: Bool = false) {
        self.failsReads = failsReads
        self.failsWrites = failsWrites
    }

    func isWordSaved(wordID: Int64) throws -> Bool {
        if failsReads { throw Failure() }
        return false
    }

    func saveWord(wordID: Int64) throws {
        if failsWrites { throw Failure() }
    }

    func unsaveWord(wordID: Int64) throws {
        if failsWrites { throw Failure() }
    }

    func fetchSavedWordIDs() throws -> [Int64] {
        if failsReads { throw Failure() }
        return []
    }
}
