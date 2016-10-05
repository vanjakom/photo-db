//
//  MungoLabApiClient.swift
//  photodb view
//
//  Created by Vanja Komadinovic on 1/23/16.
//  Copyright © 2016 mungolab.com. All rights reserved.
//

import Foundation

class MungLabApiClient {
    class func asyncApiRequest(_ url: String, request: Dictionary<String, AnyObject>, callback: @escaping (Dictionary<String, AnyObject>?) -> Void) throws -> Void {
        
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: URL(string: url)! as URL)
        
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 10.0
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let data: Data = try JSONSerialization.data(withJSONObject: request, options: JSONSerialization.WritingOptions())
        urlRequest.httpBody = data as Data
        
        URLSession.shared.dataTask(with: urlRequest as URLRequest) {
            (data, response, error) -> Void in
            guard let _: NSData = data as NSData?, let _: URLResponse = response , error == nil else {
                callback(nil)
                return
            }
            
            do {
                let responseDict = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions()) as? Dictionary<String, AnyObject>
                callback(responseDict)
            } catch {
                callback(nil)
            }}.resume()
    }
    
    class func asyncRenderRequest(_ url: String, request: Dictionary<String, AnyObject>, callback: @escaping (Data?) -> Void) throws -> Void {
        
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(url: URL(string: url)! as URL)
        
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 10.0
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let data: Data = try JSONSerialization.data(withJSONObject: request, options: JSONSerialization.WritingOptions())
        urlRequest.httpBody = data
        
        URLSession.shared.dataTask(with: urlRequest as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            guard let _: Data = data, let _: URLResponse = response , error == nil else {
                callback(nil)
                return
            }
            
            callback(data!)
            }) .resume()
    }
}
