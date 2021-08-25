//
//  main.swift
//  AsyncPractice
//
//  Created by Scott D. Bowen on 25/8/21.
//

import Foundation
import DataCompression

let MACRO_LOOPS = 16384
var GLOBAL_START = Date()

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

var randomUInt8s: [UInt8] = (0..<128*1024*1024).map( {_ in UInt8.random(in: 0x00...0xFF) })
let slicedRandomData: [[UInt8]] = randomUInt8s.chunked(into: 8192)

func attemptCompression() async -> Data {
    let compressedData = Data(randomUInt8s).compress(withAlgorithm: .lzfse)!
    return compressedData
}
func attemptMoreRandomCompression(_ i: Int) async -> Data {
    // randomUInt8s = (0..<1*64*1024).map( {_ in UInt8.random(in: 0x00...0xFF) })
    let compressedData = Data(slicedRandomData[i]).compress(withAlgorithm: .lzfse)!
    return compressedData
}
func attemptMoreRandomCompressionSync(_ i: Int) -> Data {
    // randomUInt8s = (0..<1*64*1024).map( {_ in UInt8.random(in: 0x00...0xFF) })
    let compressedData = Data(slicedRandomData[i]).compress(withAlgorithm: .lzfse)!
    return compressedData
}

let randomInts: [Int] = [Int.random(in: 0...Int.max), Int.random(in: 0...Int.max)]
func performCalculation(_ i: Int) async {
    var x = 4 * i &+ randomInts[0]
    let y = x / 2 &+ randomInts[1]
    x = 2 &* y
}

func benchmarkCode(text: String) {
    let value = -GLOBAL_START.timeIntervalSinceNow
    print("\(Int64(value * 1_000_000)) nanoseconds \(text)")
    GLOBAL_START = Date()
}

let dispatchGroup = DispatchGroup()
print("Hello, World!")
benchmarkCode(text: "BEGIN:")

func benchmark_0th() {
    dispatchGroup.enter()
    Task {
        for i in 0..<MACRO_LOOPS {
            let compressed = attemptMoreRandomCompressionSync(i)
        }
        dispatchGroup.leave()
    }
    dispatchGroup.wait()
    benchmarkCode(text: "for 0th benchmark")
}
benchmark_0th()

func benchmark_1st() {
    dispatchGroup.enter()
    Task {
        for await i in Counter(howHigh: MACRO_LOOPS) {
            let compressed = await attemptMoreRandomCompression(i-1)
        }
        dispatchGroup.leave()
    }
    dispatchGroup.wait()
    benchmarkCode(text: "for 1st benchmark")
}
benchmark_1st()

func benchmark_2nd() {
    dispatchGroup.enter()
    Task {
        await withTaskGroup(of: (Int, Crc32, Int).self) { group in
            for i in 0..<MACRO_LOOPS {
                group.addTask {
                    let compressed = await attemptMoreRandomCompression(i)
                    return (i, compressed.crc32(), compressed.count)
                }
            }
            for await triple in group {
                // print(triple)
                // print(".", terminator: "")
            }
            // print()
        }
        dispatchGroup.leave()
    }
    dispatchGroup.wait()
    benchmarkCode(text: "for 2nd benchmark")
}
benchmark_2nd()

func benchmark_3rd() {
    DispatchQueue.concurrentPerform(iterations: MACRO_LOOPS, execute: {i in
        let compressed = attemptMoreRandomCompressionSync(i)
    })
    benchmarkCode(text: "for 3rd benchmark")
}
benchmark_3rd()

print("Goodbye.")
sleep(300)
