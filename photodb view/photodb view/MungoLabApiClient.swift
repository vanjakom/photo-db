//
//  MungoLabApiClient.swift
//  photodb view
//
//  Created by Vanja Komadinovic on 1/23/16.
//  Copyright © 2016 mungolab.com. All rights reserved.
//

import Foundation

class MungLabApiClient {
    class func asyncApiRequest(url: String, request: Dictionary<String, AnyObject>, callback: Dictionary<String, AnyObject>? -> Void) throws -> Void {
        
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        
        urlRequest.HTTPMethod = "POST"
        urlRequest.timeoutInterval = 10.0
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let data: NSData = try NSJSONSerialization.dataWithJSONObject(request, options: NSJSONWritingOptions())
        urlRequest.HTTPBody = data
        
        NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in
            guard let _: NSData = data, let _: NSURLResponse = response where error == nil else {
                callback(nil)
                return
            }
            
            do {
                let responseDict = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions()) as? Dictionary<String, AnyObject>
                callback(responseDict)
            } catch {
                callback(nil)
            }}.resume()
    }
    
    class func asyncRenderRequest(url: String, request: Dictionary<String, AnyObject>, callback: NSData? -> Void) throws -> Void {
        
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        
        urlRequest.HTTPMethod = "POST"
        urlRequest.timeoutInterval = 10.0
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let data: NSData = try NSJSONSerialization.dataWithJSONObject(request, options: NSJSONWritingOptions())
        urlRequest.HTTPBody = data
        
        NSURLSession.sharedSession().dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in
            guard let _: NSData = data, let _: NSURLResponse = response where error == nil else {
                callback(nil)
                return
            }
            
            callback(data!)
            }.resume()
    }
}