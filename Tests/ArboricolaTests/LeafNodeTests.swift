//  
//  LeafNodeTests.swift
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

@testable
import Arboricola
import XCTest

class LeafNodeTests: XCTestCase {
    /// The storage type for this test case.
    typealias Storage = ArboricolaStorage<Int, Double>

    /// Asserts the iterator returns all expected leaves.
    /// 
    /// This test manually assembles a list of leaves to avoid using the insert method.
    func testIterator() {
        let leaf0 = Storage.Leaf(key: 0, value: 0.0)
        let leaf1 = Storage.Leaf(key: 1, value: 1.0)
        leaf0.next = .leaf(leaf1)
        let leaf2 = Storage.Leaf(key: 2, value: 2.0)
        leaf1.next = .leaf(leaf2)
        
        let node = Storage.LeafNode(first: leaf0, count: 3)

        var cursor = 0
        for leaf in node {
            switch cursor {
            case 0: 
                XCTAssertEqual(leaf, leaf0)
            case 1:
                XCTAssertEqual(leaf, leaf1)
            case 2: 
                XCTAssertEqual(leaf, leaf2)
            default:
                XCTFail("unexpected cursor value.")
            }
            cursor += 1
        }
    }

    /// Asserts the insert method inserts leaves as expected.
    /// 
    /// This test depends on `testIterator`.
    func testInsertOne() {
        let firstLeaf = Storage.Leaf(key: 0, value: 0.0)
        let node = Storage.LeafNode(first: firstLeaf, count: 1)

        let (inserted, exceeded) = node.insert(key: 1, value: 1.0)
        XCTAssertTrue(inserted)
        XCTAssertFalse(exceeded)

        var cursor = 0
        for leaf in node {
            if cursor == 0 {
                XCTAssertEqual(leaf, firstLeaf)
            } else if cursor == 1 {
                XCTAssertTrue(leaf == firstLeaf.next)
                XCTAssertNil(leaf.next)
                XCTAssertEqual(leaf.key, 1)
                XCTAssertEqual(leaf.value, 1.0)
            } else {
                XCTFail("undexpected cursor value")
            }
            cursor += 1
        }
    }
}
