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
    func listTags(callback: ([Tag]? -> Void)) -> Void
    
    // for given list of tags returns images
    func tagView(tags: [Tag], callback: ([ImageRef]? -> Void)) -> Void
    
    func imageMetadata(imageRef: ImageRef, callback: (ImageMetadata? -> Void)) -> Void
    
    func updateImageTags(imageRef: ImageRef, tags: [Tag], callback: (ImageMetadata? -> Void)) -> Void
    
    func thumbnailSquareImage(imageRef: ImageRef, callback: (NSData? -> Void)) -> Void
    func previewImage(imageRef: ImageRef, callback: (NSData? -> Void)) -> Void
}

class SimplePhotoDBClient: PhotoDBClient {
    let serverUri: String
    
    init(serverUri: String) {
        self.serverUri = serverUri
    }
    
    func listTags(callback: ([Tag]? -> Void)) {
        do {
            try MungLabApiClient.asyncApiRequest("http://" + self.serverUri + "/api/tag/list", request: [String:AnyObject]()) { (response) -> Void in
                guard let _: Dictionary<String, AnyObject> = response else {
                    dispatch_async(dispatch_get_main_queue(), {
                        callback(nil)
                    })
                    return
                }
            
                if let tagMaps = response!["tags"] as? [Dictionary<String, AnyObject>] {
                    let tags = tagMaps.map { (tagMap) -> Tag in
                        Tag(fromDict: tagMap)
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        callback(tags)
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        callback(nil)
                    })
                }
            }
        } catch {
            dispatch_async(dispatch_get_main_queue(), {
                callback(nil)
            })
        }
    }
    
    func tagView(tags: [Tag], callback: ([ImageRef]? -> Void)) {
        let tagArray: [String] = tags.map { (tag) -> String in
            tag.name
        }
        
        var request: Dictionary<String, AnyObject> = Dictionary()
        request["tags"] = tagArray
        
        do {
            try MungLabApiClient.asyncApiRequest("http://" + self.serverUri + "/api/tag/view", request: request) { (response) -> Void in
                guard let _: Dictionary<String, AnyObject> = response else {
                    dispatch_async(dispatch_get_main_queue(), {
                        callback(nil)
                    })
                    return
                }
                
                if let imageArray = response!["images"] as? [String] {
                    let imageRefs = imageArray.map { (image) -> ImageRef in
                        ImageRef(id: image)
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        callback(imageRefs)
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        callback(nil)
                    })
                }
            }
        } catch {
            dispatch_async(dispatch_get_main_queue(), {
                callback(nil)
            })
        }
    }
    
    func imageMetadata(imageRef: ImageRef, callback: (ImageMetadata? -> Void)) {
        var request: Dictionary<String, AnyObject> = Dictionary()
        request["id"] = imageRef.id
        
        do {
            try MungLabApiClient.asyncApiRequest("http://" + self.serverUri + "/api/image/metadata", request: request) { (response) -> Void in
                guard let _: Dictionary<String, AnyObject> = response else {
                    dispatch_async(dispatch_get_main_queue(), {
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
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        callback(imageMetadata)
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        callback(nil)
                    })
                }
            }
        } catch {
            dispatch_async(dispatch_get_main_queue(), {
                callback(nil)
            })
        }
    }
    
    func updateImageTags(imageRef: ImageRef, tags: [Tag], callback: (ImageMetadata? -> Void)) -> Void {
        var request: Dictionary<String, AnyObject> = Dictionary()
        request["id"] = imageRef.id
        request["tags"] = tags.map { (tag: Tag) -> String in return tag.name }
        
        do {
            try MungLabApiClient.asyncApiRequest("http://" + self.serverUri + "/api/image/update-tags", request: request) { (response) -> Void in
                guard let _: Dictionary<String, AnyObject> = response else {
                    dispatch_async(dispatch_get_main_queue(), {
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
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        callback(imageMetadata)
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        callback(nil)
                    })
                }
            }
        } catch {
            dispatch_async(dispatch_get_main_queue(), {
                callback(nil)
            })
        }
    }
    
    func thumbnailSquareImage(imageRef: ImageRef, callback: (NSData? -> Void)) {
        // todo
    }
    
    func previewImage(imageRef: ImageRef, callback: (NSData? -> Void)) {
        image(imageRef, type: "preview", callback: callback)
    }
    
    func image(imageRef: ImageRef, type: String, callback: (NSData? -> Void)) {
        var request: Dictionary<String, AnyObject> = Dictionary()
        request["id"] = imageRef.id
        request["type"] = type
        
        do {
            try MungLabApiClient.asyncRenderRequest("http://" + self.serverUri + "/render/photo", request: request) { (data: NSData?) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    callback(data)
                })
            }
        } catch {
            dispatch_async(dispatch_get_main_queue(), {
                callback(nil)
            })
        }
    }
}




