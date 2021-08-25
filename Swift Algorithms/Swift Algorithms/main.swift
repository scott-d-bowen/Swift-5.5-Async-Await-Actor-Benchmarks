//
//  main.swift
//  Swift Algorithms
//
//  Created by Scott D. Bowen on 23/8/21.
//

import Foundation
import Algorithms
import BigInt

let concurrentQueue = DispatchQueue(label: "Concurrent Queue", attributes: .concurrent)
let serialQueue = DispatchQueue(label: "Serial Queue")

func factorial(_ n: UInt16) -> BigUInt {
    if (n > 1) {
        return (1 ... n).map { BigUInt($0) }.reduce(BigUInt(1), *)
    } else { // if (n == 1){
        return 1        // TODO: Test this case out more.
    }
}


print("Hello, World!")
var GLOBAL_START = Date()

func benchmarkCode(text: String) {
    let value = -GLOBAL_START.timeIntervalSinceNow
    print("\(Int64(value * 1_000_000)) nanoseconds \(text)")
    GLOBAL_START = Date()
}


actor GoGoGo { // : Sendable {
    
    private var factorialDict: [UInt16:BigUInt] = [:]
    
    func getDictCount() -> Int {
        return factorialDict.count
    }

     func fastFactorial(_ n: UInt16) -> BigUInt {

        if let factCache = factorialDict[n] {
                return factCache
        } else {
            // serialQueue.async(flags: .barrier) {
                // let series = (1 ... n)
                // let closure = series.map { BigUInt($0) }.reduce(BigUInt(1), *)
                factorialDict[n] = factorial(n)
            // }
        }
        if (n > 1) {
            return factorialDict[n] ??
                (1 ... n).map { BigUInt($0) }.reduce(BigUInt(1), *)
        } else { // if (n == 1){
            return 1        // TODO: Test this case out more.
        }
    }
    
     func performBenchmark() -> (UInt16, BigUInt) {
        let random = UInt16.random(in: 16...2048)
         let resultA = fastFactorial(random)
        return (random, resultA)
        // let resultB = await fastFactorial(UInt16.random(in: 16...2048))
        // let resultC = resultA / resultB
    }
}

var gogogo = GoGoGo()
let dispatchGroup = DispatchGroup()
dispatchGroup.enter()
Task.init() {
    for await _ in Counter(howHigh: 1024) {
        // print(await gogogo.performBenchmark().0 )
        let x = await gogogo.performBenchmark().0
    }
    await print("Fast Factorial Count: \(gogogo.getDictCount() )")
    dispatchGroup.leave()
    benchmarkCode(text: "for Fast Factorial Benchmark")
}
dispatchGroup.wait()



// DispatchQueue.concurrentPerform(iterations: 1024, execute: {_ in
//    gogogo.performBenchmark()
// })
// benchmarkCode()

dispatchGroup.enter()
Task.init() {
    for await i in Counter(howHigh: 1*1024*1024) {
        var x = 4 * i + Int.random(in: 0...255)
        let y = x / 2 + Int.random(in: 0...255)
        x = 2 * y
    }
    dispatchGroup.leave()
    benchmarkCode(text: "to leave Dispatch Group")
}
dispatchGroup.wait()
benchmarkCode(text: "to wait on Dispatch Group wrap up")
print("End of Main.")
sleep(300)
