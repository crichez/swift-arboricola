//  
//  SortedDictionaryTests.swift
//  swift-arboricola
//
//  Copyright 2022 Christopher Richez
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//      http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
import Arboricola

class SortedDictionaryTests: XCTestCase {
    /// The default initialized capacity of a sorted dictionary.
    var defaultCapacity: Int { 64 }

    /// Asserts initializing an empty dictionary succeeds with the expected capacity, count
    /// and elements.
    func testInitializeEmpty() {
        let dict = SortedDictionary<Int, Bool>()
        XCTAssertEqual(dict.capacity, defaultCapacity)
        XCTAssertEqual(dict.count, 0)
        XCTAssertTrue(dict.elements.isEmpty)
    }

    /// Asserts inserting a single key-value pair into an empty dictionary succeeds with 
    /// the expected count, capacity and elements.
    func testInsertOne() {
        var dict = SortedDictionary<Int, Bool>()
        dict[0] = false
        XCTAssertEqual(dict.capacity, defaultCapacity)
        XCTAssertEqual(dict.count, 1)
        XCTAssertEqual(dict[0], false)
        XCTAssertNil(dict[1])
    }

    /// Asserts initializing a dictionary from a literal succeeds with the expected capacity,
    /// count and elements.
    func testInitializeFromDictionaryLiteral() {
        let dict: SortedDictionary = [
            "test": 1,
        ]
        XCTAssertEqual(dict.capacity, defaultCapacity)
        XCTAssertEqual(dict.count, 1)
        XCTAssertEqual(dict["test"], 1)
        XCTAssertNil(dict["otherTest"])
    }

    /// Asserts the dictionary iterator returns all elements in the expected order.
    func testIteratorReturnsAllElementsInOrder() {
        let dict: SortedDictionary = [
            "2": "two",
            "0": "zero",
            "1": "one",
        ]
        let expectedContents = [
            (key: 0, value: "zero"),
            (key: 1, value: "one"),
            (key: 2, value: "two"),
        ]
        XCTAssertEqual(Array(dict), expectedContents)
    }

    /// Asserts removing an element from a dictionary with more than one element succeeds with
    /// the expected capacity, count and elements.
    func testRemoveOne() {
        var dict: SortedDictionary = [
            0: 1.295,
            1: -0.001,
        ]
        dict[0] = nil
        XCTAssertEqual(dict.capacity, defaultCapacity)
        XCTAssertEqual(dict.count, 1)
        XCTAssertEqual(dict[1], 1.295)
        XCTAssertNil(dict[0])
        XCTAssertTrue(dict.elements.allSatisfy { $0.key == 0 && $0.value == -0.001 })
    }
}
