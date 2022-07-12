//  
//  InternalNode.swift
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

class InternalNode<Element: Comparable>: Collection {
    class Record {
        let node: Node<Element>
        let separator: Element
        var next: Next

        enum Next {
            case record(Record)
            case node(Node<Element>)
        }

        init(node: Node<Element>, separator: Element, next: Next) {
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
    func insert(
        node: Node<Element>, 
        separatedBy separator: Element
    ) -> (inserted: Bool, exceededCapacity: Bool) {
        // Ensure this node is not full.
        guard count < maxChildrenPerNode else {
            // If it is, return now.
            return (false, exceededCapacity: true)
        }
        // Store the previous and current record for iteration.
        var previousRecord: Record? = nil
        var currentRecord = first
        // Keep iterating until currentRecord is greater than the new node's separator.
        while currentRecord.separator < separator {
            // Check whether the current record is the end of the chain.
            switch currentRecord.next {
            case .record(let nextRecord):
                // If not, continue iterating.
                previousRecord = currentRecord
                currentRecord = nextRecord
            case .node(let lastNode):
                // If so, insert the new node at the end of the chain.
                // Create a record that references the final node and the new one.
                let newRecord = Record(node: lastNode, separator: separator, next: .node(node))
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
                separator: separator, 
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
    func split() -> (newNode: InternalNode, separatedBy: Element) {
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
    func insert(_ element: Element) -> (inserted: Bool, exceededCapacity: Bool) {
        // Store the current record for iteration.
        var currentRecord = first
        while currentRecord.separator < element {
            switch currentRecord.next {
            case .record(let nextRecord):
                // If currentRecord.next is also a record, keep iterating.
                currentRecord = nextRecord
            case .node(let lastNode):
                // If currentRecord.next is a node, insert the new pair at this node.
                switch lastNode {
                case .leaf(let leafNode):
                    let (inserted, exceeded) = leafNode.insert(element)
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
                            let (inserted, exceeded) = insert(element)
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
                    let (inserted, exceeded) = internalNode.insert(element)
                    if inserted {
                        return (true, false)
                    } else if exceeded {
                        let (newNode, separator) = internalNode.split()
                        let (inserted, exceeded) = insert(
                            node: .branch(newNode), 
                            separatedBy: separator
                        )
                        if inserted {
                            let (inserted, _) = insert(element)
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
            let (inserted, exceeded) = leafNode.insert(element)
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
                    let (inserted, _) = insert(element)
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
            let (inserted, exceeded) = internalNode.insert(element)
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
                    let (inserted, _) = insert(element)
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
