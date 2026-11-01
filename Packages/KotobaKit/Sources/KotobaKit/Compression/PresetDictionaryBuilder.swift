//
//  PresetDictionaryBuilder.swift
//  KotobaKit
//

import Foundation

/// Builds a preset dictionary on the device from a sample of entry payloads.
///
/// Deflate can only refer back into the dictionary, so the dictionary should hold the byte
/// sequences that recur across entries. This is a greedy cover, after the idea behind zstd's COVER
/// trainer: split the samples into segments, score each segment by how many samples share its
/// 8-byte substrings, and repeatedly take the best segment, not counting substrings already taken.
/// The best segments go last, nearest the data they compress. On 2026-11-01 it came within 5% of a
/// zstd-trained dictionary; see `docs/dictionary.md`.
enum PresetDictionaryBuilder {
    static let segmentSize = 256

    static func build(
        from samples: [Data],
        size: Int = PresetDeflate.maximumDictionarySize
    ) -> Data {
        guard size > 0 else {
            return Data()
        }
        let frequency = sampleFrequency(of: samples)

        var candidates: [Candidate] = []
        for sample in samples {
            var start = sample.startIndex
            while start < sample.endIndex {
                let end = min(start + segmentSize, sample.endIndex)
                let segment = sample[start..<end]
                let score = Self.score(segment, frequency: frequency, covered: [])
                if score > 0 {
                    candidates.append(Candidate(segment: segment, score: score))
                }
                start = end
            }
        }
        // Lazy greedy: scores only fall as substrings get covered, so a candidate whose fresh score
        // still beats the next stale score is the best one.
        candidates.sort { $0.score < $1.score }

        var covered = Set<UInt64>()
        var chosen: [Data] = []
        var total = 0
        while total < size, var candidate = candidates.popLast() {
            candidate.score = score(candidate.segment, frequency: frequency, covered: covered)
            guard candidate.score > 0 else {
                continue
            }
            if let next = candidates.last, candidate.score < next.score {
                let position = candidates.partitioningIndex { $0.score >= candidate.score }
                candidates.insert(candidate, at: position)
                continue
            }
            chosen.append(candidate.segment)
            total += candidate.segment.count
            forEachKey(in: candidate.segment) { covered.insert($0) }
        }

        var dictionary = Data()
        dictionary.reserveCapacity(total)
        for segment in chosen.reversed() {
            dictionary.append(segment)
        }
        return dictionary.suffix(size)
    }

    private struct Candidate {
        let segment: Data
        var score: Int
    }

    private static let keyLength = 8

    /// The number of samples that contain each 8-byte substring.
    private static func sampleFrequency(of samples: [Data]) -> [UInt64: Int] {
        var frequency: [UInt64: Int] = [:]
        for sample in samples {
            var seen = Set<UInt64>()
            forEachKey(in: sample) { seen.insert($0) }
            for key in seen {
                frequency[key, default: 0] += 1
            }
        }
        return frequency
    }

    /// Substrings found in only one sample cannot help other entries, so they score nothing.
    private static func score(
        _ segment: Data,
        frequency: [UInt64: Int],
        covered: Set<UInt64>
    ) -> Int {
        var score = 0
        forEachKey(in: segment) { key in
            if let count = frequency[key], count > 1, !covered.contains(key) {
                score += count
            }
        }
        return score
    }

    private static func forEachKey(in bytes: Data, _ body: (UInt64) -> Void) {
        guard bytes.count >= keyLength else {
            return
        }
        bytes.withUnsafeBytes { buffer in
            for offset in 0...(buffer.count - keyLength) {
                body(buffer.loadUnaligned(fromByteOffset: offset, as: UInt64.self))
            }
        }
    }
}

extension Array {
    /// The first index whose element satisfies `predicate`, for an array partitioned so that every
    /// element failing it comes first.
    fileprivate func partitioningIndex(where predicate: (Element) -> Bool) -> Int {
        var low = 0
        var high = count
        while low < high {
            let middle = (low + high) / 2
            if predicate(self[middle]) {
                high = middle
            } else {
                low = middle + 1
            }
        }
        return low
    }
}
