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
class LeafNode<Key: Comparable, Value>: Collection {
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
        let lastLeaf = self[lastLeafIndex]

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

        // Iterate through all the leaves in the node.
        for leaf in self {
            if newLeaf < leaf {
                // If the new leaf fits before the first one, insert it at the start.
                newLeaf.next = .leaf(first)
                first = newLeaf
                count += 1
                return (inserted: true, exceededCapacity: false)
            } else if newLeaf > leaf.next {
                // If the new leaf isn't contained between this leaf and the next, continue.
                continue
            } else if leaf == newLeaf {
                // If the new leaf matches this one, it already exists.
                return (inserted: false, exceededCapacity: false)
            } else {
                // If the leaf fits between this one and the next, insert it.
                // This also works if this key is the greatest in the node.
                newLeaf.next = leaf.next
                leaf.next = .leaf(newLeaf)
                count += 1
                return (inserted: true, exceededCapacity: false)
            }
        }
        fatalError("This should never happen.")
    }

    var startIndex: Int { 
        0
    }

    var endIndex: Int {
        count
    }

    func index(after i: Int) -> Int {
        i + 1
    }

    subscript(position: Int) -> Leaf<Key, Value> {
        var cursor = 0
        for leaf in self {
            guard cursor == position else { 
                cursor += 1
                continue
            }
            return leaf
        }
        fatalError("Index out of range.")
    }

    struct Iterator: IteratorProtocol {
        var currentLeaf: Leaf<Key, Value>

        init(node: LeafNode) {
            self.currentLeaf = node.first
        }

        mutating func next() -> Leaf<Key, Value>? {
            let leafToReturn = currentLeaf
            switch currentLeaf.next {
            case .leaf(let nextLeaf):
                currentLeaf = nextLeaf
            case .node(_), .none:
                return nil
            }
            return leafToReturn
        }
    }

    func makeIterator() -> Iterator {
        Iterator(node: self)
    }
}
