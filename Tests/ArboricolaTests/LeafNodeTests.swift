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
        let first = Leaf(element: 0)
        let next = Leaf(element: 1)
        let last = Leaf(element: 2)

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
        XCTAssertEqual(iteratedLeaves[0].element, 0)
        XCTAssertEqual(iteratedLeaves[1].element, 1)
        XCTAssertEqual(iteratedLeaves[2].element, 2)
    }

    /// Asserts inserting a leaf at the end of a leaf node succeeds as expected.
    func testInsertOneAtEnd() {
        // Initialize a node with a single leaf.
        let firstLeaf = Leaf(element: 0)
        let node = LeafNode(first: firstLeaf, count: 1)

        // Insert a new key-value pair that should fit after the first leaf.
        let (inserted, exceeded) = node.insert(1)
        XCTAssertTrue(inserted)
        XCTAssertFalse(exceeded)
        XCTAssertEqual(node.count, 2)

        switch node.first.next {
        case .leaf(let insertedLeaf):
            // Assert the leaf was inserted at the right position with the right key and value.
            XCTAssertEqual(insertedLeaf.element, 1)
            XCTAssertNil(insertedLeaf.next)
        default:
            XCTFail("Unexpected end of node.")
        }
    }

    /// Asserts inserting a leaf at the beginning of a leaf node succeeds as expected.
    func testInsertOneAtStart() {
        // Initialize a node with a single leaf.
        let firstLeaf = Leaf(element: 1)
        let node = LeafNode(first: firstLeaf, count: 1)

        // Insert a new key-value pair that should fit before the first leaf.
        let (inserted, exceeded) = node.insert(0)
        XCTAssertTrue(inserted)
        XCTAssertFalse(exceeded)
        XCTAssertEqual(node.count, 2)

        // Assert the leaf was inserted at the start of the node with the correct key and value.
        XCTAssertEqual(node.first.element, 0)
        
        // Assert the inserted leaf points to the original first leaf.
        switch node.first.next {
        case .leaf(let original):
            XCTAssertEqual(original.element, 1)
        default:
            XCTFail("Unexpected end of node.")
        }
    }

    /// Asserts inserting a leaf between two existing leaves behaves as expected.
    func testInsertOneInMiddle() {
        // Initialize two leaves and a node.
        let first = Leaf(element: 0)
        let last = Leaf(element: 2)
        first.next = .leaf(last)
        let node = LeafNode(first: first, count: 2)

        // Insert a new leaf that should fit between the two existing ones.
        let (inserted, exceeded) = node.insert(1)
        XCTAssertTrue(inserted)
        XCTAssertFalse(exceeded)
        XCTAssertEqual(node.count, 3)

        // Assert the leaf was inserted between the two leaves.
        switch node.first.next {
        case .leaf(let insertedLeaf):
            XCTAssertEqual(insertedLeaf.element, 1)
            switch insertedLeaf.next {
            case .leaf(let nextLeaf):
                XCTAssertEqual(nextLeaf.element, last.element)
                XCTAssertNil(nextLeaf.next)
            default:
                XCTFail("Unexpected end of node.")
            }
        default:
            XCTFail("Unexpected end of node.")
        }
    }

    /// Asserts inserting a duplicate key into a leaf node with a single leaf reports failure
    /// and does not mutate the node.
    func testInsertDuplicateIntoSingleElementNode() {
        // Initialize a node with a single leaf.
        let leaf = Leaf(element: 0)
        let node = LeafNode(first: leaf, count: 1)

        // Insert a leaf with the same key, but a different value.
        let (inserted, exceeded) = node.insert(0)
        XCTAssertFalse(inserted)
        XCTAssertFalse(exceeded)
        XCTAssertEqual(node.count, 1)
    }

    /// Asserts inserting a duplicate key into a leaf node with multiple leaves reports failure
    /// and does not mutate the node.
    func testInsertDuplicateIntoMultiElementNode() {
        // Initialize a node with three leaves.
        let first = Leaf(element: 0)
        let next = Leaf(element: 1)
        let last = Leaf(element: 2)
        first.next = .leaf(next)
        next.next = .leaf(last)
        let node = LeafNode(first: first, count: 3)

        // Insert a leaf with an existing key, but a different value.
        let (inserted, exceeded) = node.insert(1)
        XCTAssertFalse(inserted)
        XCTAssertFalse(exceeded)
        XCTAssertEqual(node.count, 3)

        // Check that the value of the existing leaf has not changed.
        switch node.first.next {
        case .leaf(let insertedLeaf):
            XCTAssertEqual(insertedLeaf.element, 1)
        default:
            XCTFail("Unexpected end of node.")
        }
    }

    /// Asserts inserting a new leaf into a full node fails and responds as expected.
    func testInsertIntoFullNode() {
        // Initialize and chain the maximum number of leaves in a node, and initialize the node.
        let first = Leaf(element: 0)
        var previous = first
        for number in 1..<maxChildrenPerNode {
            let current = Leaf(element: number)
            previous.next = .leaf(current)
            previous = current
        }
        let node = LeafNode(first: first, count: maxChildrenPerNode)

        // Insert a new leaf with a unique key.
        let (inserted, exceeded) = node.insert(maxChildrenPerNode)
        XCTAssertFalse(inserted)
        XCTAssertTrue(exceeded)
        XCTAssertEqual(node.count, maxChildrenPerNode)

        // Ensure the contents of the node have not changed.
        var cursor = 0
        for leaf in node {
            XCTAssertEqual(leaf.element, cursor)
            cursor += 1
        }
        XCTAssertEqual(cursor, maxChildrenPerNode)
    }
    
    /// Asserts removing a key contained in a full leaf node succeeds 
    /// and mutates the node as expected.
    func testRemoveOneFromFullNode() {
        // Initialize and chain the maximum number of leaves in a node, and initialize the node.
        let first = Leaf(element: 0)
        var previous = first
        for number in 1..<maxChildrenPerNode {
            let current = Leaf(element: number)
            previous.next = .leaf(current)
            previous = current
        }
        let node = LeafNode(first: first, count: maxChildrenPerNode)

        // Remove the second leaf in that node.
        let (removed, unbalanced) = node.remove(1)
        XCTAssertTrue(removed)
        XCTAssertFalse(unbalanced)
        XCTAssertEqual(node.count, maxChildrenPerNode - 1)

        // Check that the leaf was actually removed.
        switch node.first.next {
        case .leaf(let next):
            XCTAssertEqual(next.element, 2)
        default:
            XCTFail("Unexpected end of node.")
        }
    }

    /// Asserts removing a leaf from a node that is exactly half full reports failure and does
    /// not mutate the node.
    func testRemoveOneFromHalfFullNode() {
        // Initialize and chain the maximum number of leaves in a node, and initialize the node.
        let first = Leaf(element: 0)
        var previous = first
        for number in 1..<maxChildrenPerNode / 2 {
            let current = Leaf(element: number)
            previous.next = .leaf(current)
            previous = current
        }
        let node = LeafNode(first: first, count: maxChildrenPerNode / 2)

        // Remove the second leaf in that node.
        let (removed, unbalanced) = node.remove(1)
        XCTAssertFalse(removed)
        XCTAssertTrue(unbalanced)
        XCTAssertEqual(node.count, maxChildrenPerNode / 2)
        
        // Ensure the contents of the node have not changed.
        var cursor = 0
        for leaf in node {
            XCTAssertEqual(leaf.element, cursor)
            cursor += 1
        }
        XCTAssertEqual(cursor, maxChildrenPerNode / 2)
    }
}
