//  
//  Record.swift
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

class Record<Element: Comparable> {
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
