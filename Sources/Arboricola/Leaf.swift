//  
//  Leaf.swift
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

/// A key-value pair with a reference to the next leaf.
class Leaf<Key: Comparable, Value>: Comparable {
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
        case node(Node<Key, Value>)

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
