//
//  main.swift
//  kotoba-pack
//

// Imports a Yomitan archive into a dictionary pack on macOS and prints measurements.
//
// Usage: kotoba-pack <archive.zip> <output.sqlite> [--level 1-9] [--preset-size <bytes>] [--verify <count>]

import Foundation
import KotobaKit

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

var arguments = Array(CommandLine.arguments.dropFirst())
var options = YomitanImporter.Options()
var verifyCount = 2_000

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
if let count = takeValue(after: "--verify", from: &arguments) {
    guard let count = Int(count), count >= 0 else {
        fail("--verify must be a count")
    }
    verifyCount = count
}
guard arguments.count == 2 else {
    fail(
        "usage: kotoba-pack <archive.zip> <output.sqlite> [--level 1-9] [--preset-size <bytes>] [--verify <count>]"
    )
}

let archiveURL = URL(fileURLWithPath: arguments[0])
let packURL = URL(fileURLWithPath: arguments[1])

func megabytes(_ bytes: Int) -> String {
    String(format: "%.1f MB", Double(bytes) / 1_000_000)
}

do {
    let report = try YomitanImporter(options: options).importArchive(at: archiveURL, to: packURL)
    print(report)
    print("zlib level          \(options.compressionLevel)")

    if verifyCount > 0 {
        let reader = try DictionaryPackReader(url: packURL)
        let count = try reader.entryCount()
        var generator = SystemRandomNumberGenerator()
        let ids = (0..<min(verifyCount, count)).map { _ in
            Int64.random(in: 1...Int64(count), using: &generator)
        }
        let clock = ContinuousClock()
        let start = clock.now
        for id in ids {
            guard let json = try reader.glossaryJSON(entryID: id) else {
                fail("entry \(id) is missing")
            }
            _ = try JSONSerialization.jsonObject(with: json)
        }
        let elapsed = clock.now - start
        let perEntry =
            Double(elapsed.components.attoseconds) / 1e12 / Double(ids.count)
            + Double(elapsed.components.seconds) * 1e6 / Double(ids.count)
        print(
            String(
                format: "verify              %d random entries decoded and parsed, %.0f µs each",
                ids.count,
                perEntry
            )
        )
    }

    var usage = rusage()
    getrusage(RUSAGE_SELF, &usage)
    print("peak memory         \(megabytes(Int(usage.ru_maxrss)))")
} catch {
    fail("import failed: \(error)")
}
