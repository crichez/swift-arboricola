//  
//  ArboricolaStorage.swift
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

var maxChildrenPerNode: Int { 50 }

class ArboricolaStorage<Key, Value> where Key : Comparable {
    /// The root node of the storage tree.
    var rootNode: Node<Key, Value>?

    /// Initializes an empty storage tree.
    init() {
        self.rootNode = nil
    }

    /// The maximum number of leaves a leaf node can have before being split.
    static var maxChildrenPerNode: Int { 50 }

    /// Inserts the provided key-value pair into the tree.
    func insert(key: Key, value: Value) -> Bool {
        // Check the nature of the root node.
        switch rootNode {
        case .leaf(let leafNode):
            // If it's a leaf, try inserting into that leaf.
            let (inserted, exceeded) = leafNode.insert(key: key, value: value)
            if inserted { 
                // If we succeed, return true.
                return true 
            } else if exceeded {
                // If the leaf is full, split it.
                let (newLeafNode, separator) = leafNode.split()
                // Create a new internal node to replace the root node.
                // This new node references the previous leaf and the new split leaf.
                let newNode = InternalNode<Key, Value>(
                    first: InternalNode.Record(
                        node: .leaf(leafNode), 
                        separator: separator, 
                        next: .node(.leaf(newLeafNode))
                    ),
                    count: 1
                )
                // Replace the root node.
                self.rootNode = .branch(newNode)
                // Try inserting the key-value pair again and report success or failure.
                // This method will return false only if the key already exists in either leaf.
                let (inserted, _) = newNode.insert(key: key, value: value)
                return inserted
            } else {
                // The key already exists, return false.
                return false
            }
        case .branch(let internalNode):
            let (inserted, exceeded) = internalNode.insert(key: key, value: value)
            if inserted {
                return true
            } else if exceeded {
                let (newNode, separator) = internalNode.split()
                let newRecord = InternalNode<Key, Value>.Record(
                    node: .branch(internalNode), 
                    separator: separator, 
                    next: .node(.branch(newNode))
                )
                let newRootNode = Node<Key, Value>.branch(InternalNode<Key, Value>(first: newRecord, count: 1))
                self.rootNode = newRootNode
                return insert(key: key, value: value)
            } else {
                return false
            }
        case .none:
            let newNode = LeafNode(first: Leaf(key: key, value: value, next: .none))
            self.rootNode = .leaf(newNode)
            return true
        }
    }
}
