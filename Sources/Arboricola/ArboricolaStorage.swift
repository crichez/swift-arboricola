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

class ArboricolaStorage<Key, Value> where Key : Comparable {
    /// The root node of the storage tree.
    var rootNode: Node?

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
                let newNode = InternalNode(
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
                let newRecord = InternalNode.Record(
                    node: .branch(internalNode), 
                    separator: separator, 
                    next: .node(.branch(newNode))
                )
                let newRootNode = Node.branch(InternalNode(first: newRecord, count: 1))
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

    /// A key-value pair with a reference to the next leaf.
    class Leaf: Comparable {
        /// The key stored in this leaf.
        let key: Key

        /// The value stored in this leaf.
        let value: Value

        /// The location of the next element in the tree.
        /// 
        /// If this is the last element in the tree, this value is nil.
        var next: Next?

        /// An enumeration that defines the location of the next element in the tree.
        enum Next: Comparable {
            /// The next element is in the leaf attached to this case.
            case leaf(Leaf)

            /// The next element is in a the node attached to this case.
            case node(Node)

            static func < (lhs: Next, rhs: Next) -> Bool {
                switch (lhs, rhs) {
                case (.leaf(let lhs), .leaf(let rhs)):
                    return lhs.key < rhs.key
                default:
                    return false
                }
            }

            static func == (lhs: Next, rhs: Next) -> Bool {
                switch (lhs, rhs) {
                case (.leaf(let lhs), .leaf(let rhs)):
                    return lhs.key == rhs.key
                default:
                    return false
                }
            }
        }

        /// Initializes a new leaf.
        init(key: Key, value: Value, next: Next? = nil) {
            self.key = key
            self.value = value
            self.next = next
        }

        static func < (lhs: Leaf, rhs: Next?) -> Bool {
            switch rhs {
            case .leaf(let rhs):
                return lhs < rhs
            default:
                return false
            }
        } 

        static func > (lhs: Leaf, rhs: Next?) -> Bool {
            switch rhs {
            case .leaf(let rhs):
                return lhs > rhs
            default:
                return false
            }
        }

        static func == (lhs: Leaf, rhs: Next?) -> Bool {
            switch rhs {
            case .leaf(let rhs):
                return lhs == rhs
            default:
                return false
            }
        }

        static func == (lhs: Leaf, rhs: Leaf) -> Bool {
            lhs.key == rhs.key
        }

        static func < (lhs: Leaf, rhs: Leaf) -> Bool {
            lhs.key < rhs.key
        }
    }

    /// A linked list of leaves.
    class LeafNode: Collection {
        /// The first leaf in the node.
        var first: Leaf

        /// The number of leaves in the node.
        var count: Int

        init(first: Leaf, count: Int = 0) {
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
            let newNodeFirstLeaf: Leaf = {
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

        subscript(position: Int) -> Leaf {
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
            var currentLeaf: Leaf

            init(node: LeafNode) {
                self.currentLeaf = node.first
            }

            mutating func next() -> Leaf? {
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

    class InternalNode: Collection {
        class Record {
            let node: Node
            let separator: Key
            var next: Next

            enum Next {
                case record(Record)
                case node(Node)
            }

            init(node: Node, separator: Key, next: Next) {
                self.node = node
                self.separator = separator
                self.next = next
            }
        }

        var first: Record
        var count: Int

        init(first: Record, count: Int) {
            self.first = first
            self.count = count
        }

        /// Inserts a new child node into this internal node, with the provided key.
        /// 
        /// If `exceededCapacity` is false, the new child node was not inserted.
        /// 
        /// - Parameters:
        ///   - node: the child node to insert
        ///   - key: the first key of the child node
        /// 
        /// - Returns:
        /// A tuple where `inserted` reports whether the node was inserted, 
        /// and `exceededCapacity` reports whether this node was full before insertion.
        func insert(node: Node, separatedBy key: Key) -> (inserted: Bool, exceededCapacity: Bool) {
            // Ensure this node is not full.
            guard count < maxChildrenPerNode else {
                // If it is, return now.
                return (false, exceededCapacity: true)
            }
            // Store the previous and current record for iteration.
            var previousRecord: Record? = nil
            var currentRecord = first
            // Keep iterating until currentRecord is greater than the new node's separator.
            while currentRecord.separator < key {
                // Check whether the current record is the end of the chain.
                switch currentRecord.next {
                case .record(let nextRecord):
                    // If not, continue iterating.
                    previousRecord = currentRecord
                    currentRecord = nextRecord
                case .node(let lastNode):
                    // If so, insert the new node at the end of the chain.
                    // Create a record that references the final node and the new one.
                    let newRecord = Record(node: lastNode, separator: key, next: .node(node))
                    // Replace the next element of the current record.
                    currentRecord.next = .record(newRecord)
                    // Increment count.
                    count += 1
                    // Report a successful insertion.
                    return (inserted: true, false)
                }
            }
            // If we reach this point, 
            // we must insert the new node between the previous and current.
            // Check whether we even have a previous one.
            if let previousRecord = previousRecord {
                // Compose a new record that references the previous and new nodes.
                let newRecord = Record(
                    node: previousRecord.node, 
                    separator: key, 
                    next: .record(currentRecord))
                // Insert the new record.
                previousRecord.next = .record(newRecord)
                // Increment count.
                count += 1
                // Report a successful insertion.
                return (inserted: true, false)
            } else {
                // This is a debugging path.
                fatalError("we only insert nodes to the right, so this shouldn't happen.")
            }
        }

        /// Splits this node and returns its greater half and separator.
        func split() -> (newNode: InternalNode, separatedBy: Key) {
            // Ensure we only call this method when appropriate.
            guard count == maxChildrenPerNode else {
                fatalError("tried to split a node that isn't full.")
            }
            // The new node starts half way though the original one.
            let newNodeStart = self[maxChildrenPerNode / 2]
            // The new node's separator is its first key.
            let separator = newNodeStart.separator
            // Initialize the new node.
            let newNode = InternalNode(first: newNodeStart, count: maxChildrenPerNode / 2)
            // Decrement this node's count by the keys moved to the new node.
            count -= maxChildrenPerNode / 2
            // Return the new node and separator.
            return (newNode: newNode, separatedBy: separator)
        }

        /// Inserts the provided key-value pair into the tree.
        func insert(key: Key, value: Value) -> (inserted: Bool, exceededCapacity: Bool) {
            // Store the current record for iteration.
            var currentRecord = first
            while currentRecord.separator < key {
                switch currentRecord.next {
                case .record(let nextRecord):
                    // If currentRecord.next is also a record, keep iterating.
                    currentRecord = nextRecord
                case .node(let lastNode):
                    // If currentRecord.next is a node, insert the new pair at this node.
                    switch lastNode {
                    case .leaf(let leafNode):
                        let (inserted, exceeded) = leafNode.insert(key: key, value: value)
                        if inserted {
                            // If the child leaf node reports a successful insertion, do the same.
                            return (inserted: true, false)
                        } else if exceeded {
                            // If the child leaf node is full, split it.
                            let (newNode, separator) = leafNode.split()
                            // Insert the record to the new node into this node.
                            let (inserted, exceeded) = insert(
                                node: .leaf(newNode), 
                                separatedBy: separator
                            )
                            if inserted {
                                // If the node insertion succeeds, try inserting the pair again.
                                let (inserted, exceeded) = insert(key: key, value: value)
                                if inserted {
                                    // Propagate success.
                                    return (inserted: true, false)
                                } else if exceeded {
                                    fatalError("we just split the node, so it shouldn't be full.")
                                } else {
                                    // Propagate failure.
                                    return (inserted: false, false)
                                }
                            } else if exceeded {
                                // If this node is full, report so.
                                return (false, exceededCapacity: true)
                            } else {
                                fatalError("the key shouldn't already exist in this node.")
                            }
                        } else {
                            // This key already exists.
                            return (inserted: false, false)
                        }
                    case .branch(let internalNode):
                        // Try inserting the new pair into the node.
                        let (inserted, exceeded) = internalNode.insert(key: key, value: value)
                        if inserted {
                            return (true, false)
                        } else if exceeded {
                            let (newNode, separator) = internalNode.split()
                            let (inserted, exceeded) = insert(
                                node: .branch(newNode), 
                                separatedBy: separator
                            )
                            if inserted {
                                let (inserted, _) = insert(key: key, value: value)
                                return (inserted, false)
                            } else if exceeded {
                                return (false, true)
                            } else {
                                fatalError("the key exists, which shouldn't happen.")
                            }
                        } else {
                            return (false, false)
                        }
                    }
                }
            }
            // Check the nature of the selected node.
            switch currentRecord.node {
            case .leaf(let leafNode):
                // If it's a leaf node, try inserting the new key-value pair into it.
                let (inserted, exceeded) = leafNode.insert(key: key, value: value)
                if inserted {
                    // If that succeeds, report success.
                    return (inserted: true, false)
                } else if exceeded {
                    // if the leaf node is full, split it.
                    let (newNode, separator) = leafNode.split()
                    // Insert the second half of the split node.
                    let (inserted, exceeded) = insert(
                        node: .leaf(newNode), 
                        separatedBy: separator)
                    if inserted {
                        // If the new leaf node was inserted, try inserting the value again.
                        let (inserted, _) = insert(key: key, value: value)
                        // If that succeeds, report success.
                        return (inserted: inserted, false)
                    } else if exceeded {
                        // If this internal node is full, fail and report so.
                        return (false, exceededCapacity: true)
                    } else {
                        fatalError("the new split leaf node shouldn't already exist.")
                    }
                } else {
                    // If the key already exists, report so.
                    return (inserted: false, false)
                }
            case .branch(let internalNode):
                // If it's an internal node, delegate insertion to that node.
                let (inserted, exceeded) = internalNode.insert(key: key, value: value)
                if inserted {
                    // If the node reports success, do the same.
                    return (inserted: true, false)
                } else if exceeded {
                    // If that internal node is full, split it.
                    let (newNode, separator) = internalNode.split()
                    // Try inserting the new split node into this node.
                    let (inserted, exceeded) = insert(
                        node: .branch(newNode), 
                        separatedBy: separator)
                    if inserted {
                        let (inserted, _) = insert(key: key, value: value)
                        return (inserted, false)
                    } else if exceeded {
                        return (false, true)
                    } else {
                        fatalError("this should never happen")
                    }
                } else {
                    return (false, false)
                }
            }
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

        subscript(position: Int) -> Record {
            var record = first
            for _ in 0 ..< position {
                switch record.next {
                case .record(let nextRecord):
                    record = nextRecord
                case .node(_):
                    break
                }
            }
            return record
        }
    }

    enum Node {
        case leaf(LeafNode)
        case branch(InternalNode)
    }
}
