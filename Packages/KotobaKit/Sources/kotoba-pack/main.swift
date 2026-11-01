//
//  main.swift
//  kotoba-pack
//

// Imports Yomitan archives into dictionary packs and measures them on macOS.
//
//   kotoba-pack import <archive.zip> <output.sqlite> [--level 1-9] [--preset-size <bytes>]
//                      [--verify <count>]
//   kotoba-pack search <pack.sqlite> <prefix>... [--limit <count>] [--repeat <count>]

import Foundation
import KotobaKit

let usage = """
    usage: kotoba-pack import <archive.zip> <output.sqlite> [--level 1-9] \
    [--preset-size <bytes>] [--verify <count>]
           kotoba-pack search <pack.sqlite> <prefix>... [--limit <count>] [--repeat <count>]
    """

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func takeValue(after flag: String, from arguments: inout [String]) -> String? {
    guard let position = arguments.firstIndex(of: flag) else {
        return nil
    }
    guard position + 1 < arguments.count else {
        fail("\(flag) needs a value")
    }
    let value = arguments[position + 1]
    arguments.removeSubrange(position...(position + 1))
    return value
}

func takeCount(after flag: String, from arguments: inout [String], default value: Int) -> Int {
    guard let text = takeValue(after: flag, from: &arguments) else {
        return value
    }
    guard let count = Int(text), count >= 0 else {
        fail("\(flag) must be a count")
    }
    return count
}

func microseconds(_ duration: Duration) -> String {
    duration.formatted(.units(allowed: [.microseconds], width: .narrow))
}

func importArchive(_ arguments: [String]) async throws {
    var arguments = arguments
    var options = YomitanImporter.Options()
    if let level = takeValue(after: "--level", from: &arguments) {
        guard let level = Int32(level), (1...9).contains(level) else {
            fail("--level must be 1 to 9")
        }
        options.compressionLevel = level
    }
    if let size = takeValue(after: "--preset-size", from: &arguments) {
        guard let size = Int(size), (0...PresetDeflate.maximumDictionarySize).contains(size) else {
            fail("--preset-size must be 0 to \(PresetDeflate.maximumDictionarySize)")
        }
        options.presetDictionarySize = size
    }
    let verifyCount = takeCount(after: "--verify", from: &arguments, default: 2_000)
    guard arguments.count == 2 else {
        fail(usage)
    }
    let packURL = URL(fileURLWithPath: arguments[1])

    let report = try YomitanImporter(options: options).importArchive(
        at: URL(fileURLWithPath: arguments[0]),
        to: packURL
    )
    print(report)
    print("zlib level          \(options.compressionLevel)")

    let pack = try DictionaryPack(url: packURL)
    let count = Int64(try await pack.entryCount())
    if verifyCount > 0, count > 0 {
        let clock = ContinuousClock()
        let start = clock.now
        for _ in 0..<verifyCount {
            let reference = DictionaryEntryReference(
                importID: pack.info.importID,
                rowID: .random(in: 1...count)
            )
            guard let entry = try await pack.entry(reference) else {
                fail("entry \(reference.rowID) is missing")
            }
            _ = try JSONSerialization.jsonObject(with: entry.glossaryJSON)
        }
        let perEntry = microseconds((clock.now - start) / verifyCount)
        print("verify              \(verifyCount) random entries read and parsed, \(perEntry) each")
    }

    var resources = rusage()
    getrusage(RUSAGE_SELF, &resources)
    print(
        "peak memory         \(Int64(resources.ru_maxrss).formatted(.byteCount(style: .decimal)))"
    )
}

func search(_ arguments: [String]) async throws {
    var arguments = arguments
    let limit = takeCount(after: "--limit", from: &arguments, default: 20)
    let repeatCount = max(1, takeCount(after: "--repeat", from: &arguments, default: 100))
    guard arguments.count >= 2 else {
        fail(usage)
    }
    let pack = try DictionaryPack(url: URL(fileURLWithPath: arguments[0]))
    let clock = ContinuousClock()
    for prefix in arguments.dropFirst() {
        let firstStart = clock.now
        let results = try await pack.search(prefix: prefix, limit: limit)
        let first = clock.now - firstStart

        let start = clock.now
        for _ in 0..<repeatCount {
            _ = try await pack.search(prefix: prefix, limit: limit)
        }
        let average = (clock.now - start) / repeatCount

        print(
            "== \(prefix): \(results.count) results, first \(microseconds(first)), ",
            terminator: ""
        )
        print("average of \(repeatCount) \(microseconds(average))")
        for line in try await pack.searchQueryPlan(prefix: prefix, limit: limit) {
            print("   plan: \(line)")
        }
        let shown = results.map { "\($0.key.term)【\($0.key.reading)】\($0.score)" }
        print("   " + shown.joined(separator: " "))
    }
}

var arguments = Array(CommandLine.arguments.dropFirst())
guard !arguments.isEmpty else {
    fail(usage)
}
let command = arguments.removeFirst()
do {
    switch command {
    case "import":
        try await importArchive(arguments)
    case "search":
        try await search(arguments)
    default:
        fail(usage)
    }
} catch {
    fail("\(command) failed: \(error)")
}
