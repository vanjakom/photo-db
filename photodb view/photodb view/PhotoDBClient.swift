//
//  PhotoDBClient.swift
//  photodb view
//
//  Created by Vanja Komadinovic on 1/23/16.
//  Copyright © 2016 mungolab.com. All rights reserved.
//

import Foundation


protocol PhotoDBClient {
    // returns all possible tags
    func listTags(_ callback: @escaping (([Tag]?) -> Void)) -> Void
    
    // for given list of tags returns images
    func tagView(_ tags: [Tag], callback: @escaping (([ImageRef]?, [Tag]?) -> Void)) -> Void
    
    func imageMetadata(_ imageRef: ImageRef, callback: @escaping ((ImageMetadata?) -> Void)) -> Void
    
    func updateImageTags(_ imageRef: ImageRef, tags: [Tag], callback: @escaping ((ImageMetadata?) -> Void)) -> Void
    
    func thumbnailSquareImage(_ imageRef: ImageRef, callback: @escaping ((Data?) -> Void)) -> Void
    func previewImage(_ imageRef: ImageRef, callback: @escaping ((Data?) -> Void)) -> Void
    func originalImage(_ imageRef: ImageRef, callback: @escaping ((Data?) -> Void)) -> Void
}

class SimplePhotoDBClient: PhotoDBClient {
    let serverUri: String
    
    init(serverUri: String) {
        self.serverUri = serverUri
    }
    
    func listTags(_ callback: @escaping (([Tag]?) -> Void)) -> Void {
        do {
            try MungLabApiClient.asyncApiRequest("http://" + self.serverUri + "/api/tag/list", request: [String:AnyObject]()) { (response) -> Void in
                guard let _: Dictionary<String, AnyObject> = response else {
                    DispatchQueue.main.async(execute: {
                        callback(nil)
                    })
                    return
                }
            
                if let tagMaps = response!["tags"] as? [Dictionary<String, AnyObject>] {
                    let tags = tagMaps.map { (tagMap) -> Tag in
                        Tag(fromDict: tagMap)
                    }
                    DispatchQueue.main.async(execute: {
                        callback(tags)
                    })
                } else {
                    DispatchQueue.main.async(execute: {
                        callback(nil)
                    })
                }
            }
        } catch {
            DispatchQueue.main.async(execute: {
                callback(nil)
            })
        }
    }
    
    func tagView(_ tags: [Tag], callback: @escaping (([ImageRef]?, [Tag]?) -> Void)) -> Void {
        let tagArray: [String] = tags.map { (tag) -> String in
            tag.name
        }
        
        var request: Dictionary<String, AnyObject> = Dictionary()
        request["tags"] = tagArray as AnyObject?
        
        do {
            try MungLabApiClient.asyncApiRequest("http://" + self.serverUri + "/api/tag/view", request: request) { (response) -> Void in
                guard let _: Dictionary<String, AnyObject> = response else {
                    DispatchQueue.main.async(execute: {
                        callback(nil, nil)
                    })
                    return
                }
                
                var imageRefs: [ImageRef]?
                if let imageArray = response!["ids"] as? [String] {
                    imageRefs = imageArray.map { (image) -> ImageRef in
                        ImageRef(id: image)
                    }
                } else {
                    imageRefs = nil
                }
                
                var tags: [Tag]?
                if let tagsArray = response!["tags"] as? [String] {
                    tags = tagsArray.map { (tag) -> Tag in
                        Tag(name: tag)
                    }
                } else {
                    tags = nil
                }
                
                DispatchQueue.main.async(execute: {
                    callback(imageRefs, tags)
                })
            }
        } catch {
            DispatchQueue.main.async(execute: {
                callback(nil, nil)
            })
        }
    }
    
    func imageMetadata(_ imageRef: ImageRef, callback: @escaping ((ImageMetadata?) -> Void)) -> Void {
        var request: Dictionary<String, AnyObject> = Dictionary()
        request["id"] = imageRef.id as AnyObject?
        
        do {
            try MungLabApiClient.asyncApiRequest("http://" + self.serverUri + "/api/image/metadata", request: request) { (response) -> Void in
                guard let _: Dictionary<String, AnyObject> = response else {
                    DispatchQueue.main.async(execute: {
                        callback(nil)
                    })
                    return
                }
                
                if let tagsArray = response!["tags"] as? [String] {
                    // todo 
                    // better would be to cache tags and choose on client side from list instead of regenerating
                    let tags = tagsArray.map({ (tagName: String) -> Tag in
                        return Tag(name: tagName)
                    })
                    let imageMetadata = ImageMetadata(id: imageRef.id, tags: tags)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        callback(imageMetadata)
                    })
                } else {
                    DispatchQueue.main.async(execute: {
                        callback(nil)
                    })
                }
            }
        } catch {
            DispatchQueue.main.async(execute: {
                callback(nil)
            })
        }
    }
    
    func updateImageTags(_ imageRef: ImageRef, tags: [Tag], callback: @escaping ((ImageMetadata?) -> Void)) -> Void {
        var request: Dictionary<String, AnyObject> = Dictionary()
        request["id"] = imageRef.id as AnyObject?
        request["tags"] = tags.map { (tag: Tag) -> String in return tag.name } as AnyObject?
        
        do {
            try MungLabApiClient.asyncApiRequest("http://" + self.serverUri + "/api/image/update-tags", request: request) { (response) -> Void in
                guard let _: Dictionary<String, AnyObject> = response else {
                    DispatchQueue.main.async(execute: {
                        callback(nil)
                    })
                    return
                }
                
                // todo fix this
                // copied from image metadata retrieve
                if let tagsArray = response!["tags"] as? [String] {
                    // todo
                    // better would be to cache tags and choose on client side from list instead of regenerating
                    let tags = tagsArray.map({ (tagName: String) -> Tag in
                        return Tag(name: tagName)
                    })
                    let imageMetadata = ImageMetadata(id: imageRef.id, tags: tags)
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        callback(imageMetadata)
                    })
                } else {
                    DispatchQueue.main.async(execute: {
                        callback(nil)
                    })
                }
            }
        } catch {
            DispatchQueue.main.async(execute: {
                callback(nil)
            })
        }
    }
    
    func thumbnailSquareImage(_ imageRef: ImageRef, callback: @escaping ((Data?) -> Void)) {
        image(imageRef, type: "thumbnail-square", callback: callback)
    }
    
    func previewImage(_ imageRef: ImageRef, callback: @escaping ((Data?) -> Void)) {
        image(imageRef, type: "preview", callback: callback)
    }
    
    func originalImage(_ imageRef: ImageRef, callback: @escaping ((Data?) -> Void)) {
        image(imageRef, type: "original", callback: callback)
    }
    
    func image(_ imageRef: ImageRef, type: String, callback: @escaping ((Data?) -> Void)) {
        var request: Dictionary<String, AnyObject> = Dictionary()
        request["id"] = imageRef.id as AnyObject?
        request["type"] = type as AnyObject?
        
        do {
            try MungLabApiClient.asyncRenderRequest("http://" + self.serverUri + "/render/photo", request: request) { (data: Data?) -> Void in
                DispatchQueue.main.async(execute: {
                    callback(data)
                })
            }
        } catch {
            DispatchQueue.main.async(execute: {
                callback(nil)
            })
        }
    }
}




