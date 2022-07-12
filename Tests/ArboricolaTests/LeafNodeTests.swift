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
    /// Asserts the iterator returns all expected leaves.
    /// 
    /// This test manually assembles a list of leaves to avoid using the insert method.
    func testIterator() {
        let first = Leaf(key: 0, value: 0.0)
        let next = Leaf(key: 1, value: 1.0)
        let last = Leaf(key: 2, value: 2.0)

        first.next = .leaf(next)
        next.next = .leaf(last)
        last.next = .none
        
        let node = LeafNode(first: first, count: 3)

        let iteratedLeaves = Array(node)
        XCTAssertEqual(iteratedLeaves[0].key, 0)
        XCTAssertEqual(iteratedLeaves[0].value, 0.0)
        XCTAssertEqual(iteratedLeaves[1].key, 1)
        XCTAssertEqual(iteratedLeaves[1].value, 1.0)
        XCTAssertEqual(iteratedLeaves[2].key, 2)
        XCTAssertEqual(iteratedLeaves[2].value, 2.0)
    }

    /// Asserts the insert method inserts leaves as expected.
    /// 
    /// This test depends on `testIterator`.
    func testInsertOne() {
        let firstLeaf = Leaf(key: 0, value: 0.0)
        let node = LeafNode(first: firstLeaf, count: 1)

        let (inserted, exceeded) = node.insert(key: 1, value: 1.0)
        XCTAssertTrue(inserted)
        XCTAssertFalse(exceeded)

        switch node.first.next {
        case .leaf(let insertedLeaf):
            XCTAssertEqual(insertedLeaf.key, 1)
        default:
            XCTFail("Unexpected end of node.")
        }
    }
}
