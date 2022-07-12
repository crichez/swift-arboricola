//  
//  LeafNode.swift
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

/// A linked list of leaves.
class LeafNode<Key: Comparable, Value> {
    /// The first leaf in the node.
    var first: Leaf<Key, Value>

    /// The number of leaves in the node.
    var count: Int

    init(first: Leaf<Key, Value>, count: Int = 0) {
        self.first = first
        self.count = count
    }

    /// Splits this node in half and returns the new half.
    /// 
    /// This method points the last leaf of this node to the new node to maintain
    /// a contiguous linked list accross the split.
    /// 
    /// - Returns:
    /// A tuple that contains the new node and the key at which the new node starts.
    func split() -> (newNode: LeafNode, separatedBy: Key) {
        #if DEBUG
        guard count == maxChildrenPerNode else {
            fatalError("Requested a split on a node that isn't full yet.")
        }
        #endif

        // Get the last leaf.
        let lastLeafIndex = maxChildrenPerNode / 2 - 1
        let lastLeaf: Leaf<Key, Value> = {
            var cursor = 0
            var leafToReturn: Leaf<Key, Value>? = nil
            for leaf in self {
                guard cursor == lastLeafIndex else { 
                    cursor += 1
                    continue 
                }
                leafToReturn = leaf
            }
            return leafToReturn!
        }()

        // Get the first leaf of the next node.
        let newNodeFirstLeaf: Leaf<Key, Value> = {
            switch lastLeaf.next {
            case .leaf(let nextLeaf):
                return nextLeaf
            default:
                // The node was not split yet, and we know that there are more leaves.
                fatalError("We know this won't happen.")
            }
        }()

        // Initialize the new leaf node.
        let newNode = LeafNode(first: newNodeFirstLeaf, count: lastLeafIndex + 1)

        // Point the last leaf of this node to the new node.
        lastLeaf.next = .node(.leaf(newNode))
        
        // Decrement count by the number of elements in the new node.
        count -= lastLeafIndex + 1

        // Return the new node and separator.
        return (newNode: newNode, separatedBy: newNodeFirstLeaf.key)
    }

    /// Inserts the provided leaf after another leaf but before its next pointer.
    /// 
    /// If no previous leaf was provided, the leaf is inserted at the start of the node.
    /// If no next pointer was provided, the leaf is inserted at the end of the node.
    func fit(
        _ new: Leaf<Key, Value>, 
        after previous: Leaf<Key, Value>? = nil, 
        before next: Leaf<Key, Value>.Next? = nil
    ) {
        let preconditionFailure = "Both the previous and next values cannot be nil."
        precondition(previous != nil || next != nil, preconditionFailure)
        // Check whether a preceding leaf was provided.
        if let previous = previous {
            // If so, point it to the new leaf.
            previous.next = .leaf(new)
        } else {
            // If not, replace the first leaf.
            first = new
        }
        // Check whether a next value was provided.
        if let next = next {
            // If so, point the new leaf to it.
            new.next = next
        }
    }

    /// Inserts the provided key-value pair into the leaf node.
    /// 
    /// - Returns:
    /// If the key already exists, `inserted` will be false.
    /// If the capacity of the node would be exceeded, `inserted` is false and
    /// `exceededCapacity` is true.
    func insert(key: Key, value: Value) -> (inserted: Bool, exceededCapacity: Bool) {
        // Check whether the node is full.
        guard count < maxChildrenPerNode else { 
            // If so, report failure and request a split.
            return (false, exceededCapacity: true) 
        }

        /// Compose the new leaf without a next pointer.
        let newLeaf = Leaf(key: key, value: value)

        // Check the first leaf separately, prepending is a bit of a special case.
        if first.key > newLeaf.key {
            fit(newLeaf, before: .leaf(first))
            count += 1
            return (inserted: true, exceededCapacity: false)
        } else if first.key == newLeaf.key {
            // If the new leaf's key already exists, do nothing.
            return (inserted: false, exceededCapacity: false)
        }
        
        // If the first leaf's key is before the new one, iterate until we find a greater leaf.
        for currentLeaf in self {
            switch currentLeaf.next {
            case .leaf(let nextLeaf):
                // If the next leaf's key matches the new one, return failure.
                guard nextLeaf.key != newLeaf.key else {
                    return (inserted: false, exceededCapacity: false)
                }
                // If the next leaf's key is still lesser than the new one, continue iterating.
                guard nextLeaf.key > newLeaf.key else { continue }
                // If the next leaf's key is greater than the new one, fit it in between.
                fit(newLeaf, after: currentLeaf, before: .leaf(nextLeaf))
                // Increment count and report success.
                count += 1
                return (inserted: true, exceededCapacity: false)
            case .node(let nextNode):
                // If we reach the end of this node, append it.
                fit(newLeaf, after: currentLeaf, before: .node(nextNode))
                // Increment count and report success.
                count += 1
                return (inserted: true, exceededCapacity: false)
            case .none:
                // If we reach the end of the tree, append it.
                fit(newLeaf, after: currentLeaf)
                // Increment count and report success.
                count += 1
                return (inserted: true, exceededCapacity: false)
            }
        }

        // If we haven't returned by now, something is wrong.
        fatalError("This should never happen.")
    }
}

extension LeafNode: Sequence {
    struct Iterator: IteratorProtocol {
        var currentLeaf: Leaf<Key, Value>?

        init(node: LeafNode) {
            self.currentLeaf = node.first
        }

        mutating func next() -> Leaf<Key, Value>? {
            // Check whether we have a leaf to return.
            if let currentLeaf = currentLeaf {
                switch currentLeaf.next {
                case .leaf(let nextLeaf):
                    self.currentLeaf = nextLeaf
                case .node(_), .none:
                    self.currentLeaf = nil
                }
                return currentLeaf
            } else {
                return nil
            }
        }
    }

    func makeIterator() -> Iterator {
        Iterator(node: self)
    }
}
