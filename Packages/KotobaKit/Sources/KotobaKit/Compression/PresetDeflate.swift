//
//  PresetDeflate.swift
//  KotobaKit
//

import Foundation
import zlib

/// Raw deflate streams that share one preset dictionary.
///
/// Every entry is compressed on its own so lookup can decode one entry at a time. The preset
/// dictionary supplies the markup the entries have in common. Raw deflate omits the zlib header and
/// checksum, which would add 10 bytes to every entry; SQLite already guards the stored bytes.
public enum PresetDeflate {
    /// The largest dictionary deflate can use: its 32 KB window.
    public static let maximumDictionarySize = 32 * 1024

    /// Raw deflate with the largest window.
    fileprivate static let windowBits: Int32 = -15

    fileprivate static let memoryLevel: Int32 = 9
}

enum PresetDeflateError: Error, Equatable {
    case zlib(operation: String, code: Int32)
    case truncatedInput
}

/// Compresses entries with a preset dictionary, reusing one zlib stream.
///
/// Not thread-safe: use one compressor per task.
final class PresetCompressor {
    private var stream = z_stream()
    private let dictionary: [UInt8]
    private var output: [UInt8] = []

    init(dictionary: Data, level: Int32) throws {
        self.dictionary = Array(dictionary.suffix(PresetDeflate.maximumDictionarySize))
        let status = deflateInit2_(
            &stream,
            level,
            Z_DEFLATED,
            PresetDeflate.windowBits,
            PresetDeflate.memoryLevel,
            Z_DEFAULT_STRATEGY,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )
        guard status == Z_OK else {
            throw PresetDeflateError.zlib(operation: "deflateInit2", code: status)
        }
    }

    deinit {
        deflateEnd(&stream)
    }

    func compress(_ input: Data) throws -> Data {
        var status = deflateReset(&stream)
        guard status == Z_OK else {
            throw PresetDeflateError.zlib(operation: "deflateReset", code: status)
        }
        if !dictionary.isEmpty {
            status = dictionary.withUnsafeBufferPointer {
                deflateSetDictionary(&stream, $0.baseAddress, uInt($0.count))
            }
            guard status == Z_OK else {
                throw PresetDeflateError.zlib(operation: "deflateSetDictionary", code: status)
            }
        }

        let bound = Int(deflateBound(&stream, uLong(input.count)))
        if output.count < bound {
            output = [UInt8](repeating: 0, count: bound)
        }

        let written = try input.withUnsafeBytes { inputBuffer in
            try output.withUnsafeMutableBufferPointer { outputBuffer in
                stream.next_in = UnsafeMutablePointer(
                    mutating: inputBuffer.bindMemory(to: Bytef.self).baseAddress
                )
                stream.avail_in = uInt(input.count)
                stream.next_out = outputBuffer.baseAddress
                stream.avail_out = uInt(bound)
                let status = deflate(&stream, Z_FINISH)
                guard status == Z_STREAM_END else {
                    throw PresetDeflateError.zlib(operation: "deflate", code: status)
                }
                return bound - Int(stream.avail_out)
            }
        }
        return Data(output[0..<written])
    }
}

/// Decompresses entries written by ``PresetCompressor`` with the same dictionary.
///
/// Not thread-safe: use one decompressor per task.
final class PresetDecompressor {
    private var stream = z_stream()
    private let dictionary: [UInt8]
    private var output = [UInt8](repeating: 0, count: 64 * 1024)

    init(dictionary: Data) throws {
        self.dictionary = Array(dictionary.suffix(PresetDeflate.maximumDictionarySize))
        let status = inflateInit2_(
            &stream,
            PresetDeflate.windowBits,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )
        guard status == Z_OK else {
            throw PresetDeflateError.zlib(operation: "inflateInit2", code: status)
        }
    }

    deinit {
        inflateEnd(&stream)
    }

    func decompress(_ input: Data) throws -> Data {
        var status = inflateReset(&stream)
        guard status == Z_OK else {
            throw PresetDeflateError.zlib(operation: "inflateReset", code: status)
        }
        if !dictionary.isEmpty {
            // Raw inflate takes the dictionary up front instead of reporting Z_NEED_DICT.
            status = dictionary.withUnsafeBufferPointer {
                inflateSetDictionary(&stream, $0.baseAddress, uInt($0.count))
            }
            guard status == Z_OK else {
                throw PresetDeflateError.zlib(operation: "inflateSetDictionary", code: status)
            }
        }

        var result = Data()
        try input.withUnsafeBytes { inputBuffer in
            stream.next_in = UnsafeMutablePointer(
                mutating: inputBuffer.bindMemory(to: Bytef.self).baseAddress
            )
            stream.avail_in = uInt(input.count)
            while true {
                let produced = try output.withUnsafeMutableBufferPointer { outputBuffer in
                    stream.next_out = outputBuffer.baseAddress
                    stream.avail_out = uInt(outputBuffer.count)
                    let status = inflate(&stream, Z_NO_FLUSH)
                    switch status {
                    case Z_OK, Z_STREAM_END:
                        return (
                            count: outputBuffer.count - Int(stream.avail_out),
                            finished: status == Z_STREAM_END
                        )
                    case Z_BUF_ERROR:
                        throw PresetDeflateError.truncatedInput
                    default:
                        throw PresetDeflateError.zlib(operation: "inflate", code: status)
                    }
                }
                result.append(contentsOf: output[0..<produced.count])
                if produced.finished {
                    return
                }
            }
        }
        return result
    }
}
