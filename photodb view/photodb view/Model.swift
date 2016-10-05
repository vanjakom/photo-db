//
//  Model.swift
//  photodb view
//
//  Created by Vanja Komadinovic on 2/6/16.
//  Copyright © 2016 mungolab.com. All rights reserved.
//

import Foundation

open class Tag: Hashable {
    let name: String
    
    init(fromDict: Dictionary<String, AnyObject>) {
        self.name = fromDict["name"] as! String
    }
    
    init(name: String) {
        self.name = name
    }
    
    open var hashValue: Int {
        get {
            return self.name.hashValue
        }
    }
}

public func ==(lhs: Tag, rhs: Tag) -> Bool {
    return lhs.name == rhs.name
}

class ImageRef {
    let id: String
    
    init(fromDict: Dictionary<String, AnyObject>) {
        self.id = fromDict["id"] as! String
    }
    
    init(id: String) {
        self.id = id;
    }
}

class ImageMetadata {
    let id: String
    let tags: [Tag]
    
    init (id: String, tags: [Tag]) {
        self.id = id
        self.tags = tags
    }
}
