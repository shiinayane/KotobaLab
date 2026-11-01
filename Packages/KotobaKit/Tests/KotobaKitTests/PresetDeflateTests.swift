//
//  PresetDeflateTests.swift
//  KotobaKitTests
//

import Foundation
import Testing

@testable import KotobaKit

struct PresetDeflateTests {
    private let entries = (0..<50).map { number in
        Data(#"[{"tag":"div","data":{"content":"sense"},"content":"meaning \#(number)"}]"#.utf8)
    }

    @Test(arguments: [0, 64, PresetDeflate.maximumDictionarySize])
    func compressedEntry_shouldDecompressToTheOriginal(dictionarySize: Int) throws {
        let dictionary = PresetDictionaryBuilder.build(from: entries, size: dictionarySize)
        let compressor = try PresetCompressor(dictionary: dictionary, level: 6)
        let decompressor = try PresetDecompressor(dictionary: dictionary)

        for entry in entries + [Data(), Data(repeating: 7, count: 200_000)] {
            #expect(try decompressor.decompress(compressor.compress(entry)) == entry)
        }
    }

    @Test func presetDictionary_shouldShrinkEntries() throws {
        let dictionary = PresetDictionaryBuilder.build(from: entries)
        let plain = try PresetCompressor(dictionary: Data(), level: 6)
        let preset = try PresetCompressor(dictionary: dictionary, level: 6)

        let entry = Data(#"[{"tag":"div","data":{"content":"sense"},"content":"new"}]"#.utf8)
        #expect(try preset.compress(entry).count < plain.compress(entry).count)
    }

    @Test func truncatedEntry_shouldThrow() throws {
        let compressor = try PresetCompressor(dictionary: Data(), level: 6)
        let compressed = try compressor.compress(Data(repeating: 1, count: 1_000))

        #expect(throws: PresetDeflateError.truncatedInput) {
            try PresetDecompressor(dictionary: Data()).decompress(compressed.prefix(2))
        }
    }

    @Test func builder_shouldStayWithinSizeAndSkipUniqueBytes() {
        let dictionary = PresetDictionaryBuilder.build(from: entries, size: 100)
        #expect(dictionary.count <= 100)
        #expect(!dictionary.isEmpty)

        let unique = [Data("abcdefghij".utf8), Data("klmnopqrst".utf8)]
        #expect(PresetDictionaryBuilder.build(from: unique).isEmpty)
        #expect(PresetDictionaryBuilder.build(from: []).isEmpty)
    }
}
