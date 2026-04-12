//
//  SwiftDataRepository.swift
//  KotobaLab
//
//  Created by 椎名アヤネ on 2026/04/10.
//

import Foundation
import SwiftUI

final class SwiftDataRepository: UserDataRepositoryProtocol {
    func isWordSaved(wordID: Int64) throws -> Bool {
        fatalError("Need to be completed")
    }
    
    func saveWord(wordID: Int64) throws {
        fatalError("Need to be completed")
    }
    
    func unsaveWord(wordID: Int64) throws {
        fatalError("Need to be completed")
    }
    
    func fetchSavedRecords() throws -> [SavedWordRecord] {
        fatalError("Need to be completed")
    }
}
