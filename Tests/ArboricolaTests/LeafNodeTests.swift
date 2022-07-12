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
    func testIterator() {
        // Initialize each leaf separately.
        let first = Leaf(key: 0, value: 0.0)
        let next = Leaf(key: 1, value: 1.0)
        let last = Leaf(key: 2, value: 2.0)

        // Chain the leaves together.
        first.next = .leaf(next)
        next.next = .leaf(last)
        last.next = .none
        
        // Initialize a node that points to the first leaf.
        let node = LeafNode(first: first, count: 3)

        // Move the leaves to an Array.
        // This uses the LeafNode.Iterator type to populate the Array,
        // so is equivalent to a for loop.
        let iteratedLeaves = Array(node)

        // Check the contents of each leaf against expectations.
        XCTAssertEqual(iteratedLeaves[0].key, 0)
        XCTAssertEqual(iteratedLeaves[0].value, 0.0)
        XCTAssertEqual(iteratedLeaves[1].key, 1)
        XCTAssertEqual(iteratedLeaves[1].value, 1.0)
        XCTAssertEqual(iteratedLeaves[2].key, 2)
        XCTAssertEqual(iteratedLeaves[2].value, 2.0)
    }

    /// Asserts inserting a leaf at the end of a leaf node succeeds as expected.
    func testInsertOneAtEnd() {
        // Initialize a node with a single leaf.
        let firstLeaf = Leaf(key: 0, value: 0.0)
        let node = LeafNode(first: firstLeaf, count: 1)

        // Insert a new key-value pair that should fit after the first leaf.
        let (inserted, exceeded) = node.insert(key: 1, value: 1.0)
        XCTAssertTrue(inserted)
        XCTAssertFalse(exceeded)

        switch node.first.next {
        case .leaf(let insertedLeaf):
            // Assert the leaf was inserted at the right position with the right key and value.
            XCTAssertEqual(insertedLeaf.key, 1)
            XCTAssertEqual(insertedLeaf.value, 1.0)
            XCTAssertNil(insertedLeaf.next)
        default:
            XCTFail("Unexpected end of node.")
        }
    }

    /// Asserts inserting a leaf at the beginning of a leaf node succeeds as expected.
    func testInsertOneAtStart() {
        // Initialize a node with a single leaf.
        let firstLeaf = Leaf(key: 1, value: 1.0)
        let node = LeafNode(first: firstLeaf, count: 1)

        // Insert a new key-value pair that should fit before the first leaf.
        let (inserted, exceeded) = node.insert(key: 0, value: 0.0)
        XCTAssertTrue(inserted)
        XCTAssertFalse(exceeded)

        // Assert the leaf was inserted at the start of the node with the correct key and value.
        XCTAssertEqual(node.first.key, 0)
        XCTAssertEqual(node.first.value, 0.0)
        
        // Assert the inserted leaf points to the original first leaf.
        switch node.first.next {
        case .leaf(let original):
            XCTAssertEqual(original.key, 1)
            XCTAssertEqual(original.value, 1.0)
        default:
            XCTFail("Unexpected end of node.")
        }
    }
}
