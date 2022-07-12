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

class ArboricolaStorage<Element: Comparable> {
    /// The root node of the storage tree.
    var rootNode: Node<Element>?

    /// Initializes an empty storage tree.
    init() {
        self.rootNode = nil
    }

    /// The maximum number of leaves a leaf node can have before being split.
    static var maxChildrenPerNode: Int { 50 }

    /// Inserts the provided key-value pair into the tree.
    func insert(_ element: Element) -> Bool {
        // Check the nature of the root node.
        switch rootNode {
        case .leaf(let leafNode):
            // If it's a leaf, try inserting into that leaf.
            let (inserted, exceeded) = leafNode.insert(element)
            if inserted { 
                // If we succeed, return true.
                return true 
            } else if exceeded {
                // If the leaf is full, split it.
                let (newLeafNode, separator) = leafNode.split()
                // Create a new internal node to replace the root node.
                // This new node references the previous leaf and the new split leaf.
                let newNode = InternalNode<Element>(
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
                let (inserted, _) = newNode.insert(element)
                return inserted
            } else {
                // The key already exists, return false.
                return false
            }
        case .branch(let internalNode):
            let (inserted, exceeded) = internalNode.insert(element)
            if inserted {
                return true
            } else if exceeded {
                let (newNode, separator) = internalNode.split()
                let newRecord = InternalNode<Element>.Record(
                    node: .branch(internalNode), 
                    separator: separator, 
                    next: .node(.branch(newNode))
                )
                let newRootNode = Node<Element>
                    .branch(InternalNode<Element>(first: newRecord, count: 1))
                self.rootNode = newRootNode
                return insert(element)
            } else {
                return false
            }
        case .none:
            let newNode = LeafNode(first: Leaf(element: element, next: .none))
            self.rootNode = .leaf(newNode)
            return true
        }
    }
}
