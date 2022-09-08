//
//  NextcloudKit+Comments.swift
//  NextcloudKit
//
//  Created by Marino Faggiana on 21/05/2020.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import Alamofire

extension NextcloudKit {

    @objc public func getComments(fileId: String,
                                  options: NKRequestOptions = NKRequestOptions(),
                                  completion: @escaping (_ account: String, _ items: [NKComments]?, _ error: NKError) -> Void) {
           
        let account = NKCommon.shared.account

        let serverUrlEndpoint = NKCommon.shared.urlBase + "/" + NKCommon.shared.dav + "/comments/files/" + fileId
            
        guard let url = serverUrlEndpoint.encodedToUrl else {

            return options.queue.async { completion(account, nil, .urlError) }
        }
        
        let method = HTTPMethod(rawValue: "PROPFIND")
        let headers = NKCommon.shared.getStandardHeaders(options.customHeader, customUserAgent: options.customUserAgent, contentType: "application/xml")

        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            urlRequest.httpBody = NKDataFileXML().requestBodyComments.data(using: .utf8)
        } catch {
            return options.queue.async { completion(account, nil, NKError(error: error)) }
        }
          
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).responseData(queue: NKCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NKError(error: error, afResponse: response)
                options.queue.async { completion(account, nil, error) }
            case .success( _):
                if let data = response.data {
                    let items = NKDataFileXML().convertDataComments(data: data)
                    options.queue.async { completion(account, items, .success) }
                } else {
                    options.queue.async { completion(account, nil, .invalidData) }
                }
            }
        }
    }

    @objc public func putComments(fileId: String,
                                  message: String,
                                  options: NKRequestOptions = NKRequestOptions(),
                                  completion: @escaping (_ account: String, _ error: NKError) -> Void) {
        
        let account = NKCommon.shared.account

        let serverUrlEndpoint = NKCommon.shared.urlBase + "/" + NKCommon.shared.dav + "/comments/files/" + fileId
        
        guard let url = serverUrlEndpoint.encodedToUrl else {
            return options.queue.async { completion(account, .urlError) }
        }

        let headers = NKCommon.shared.getStandardHeaders(options: options)

        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: .post, headers: headers)
            let parameters = "{\"actorType\":\"users\",\"verb\":\"comment\",\"message\":\"" + message + "\"}"
            urlRequest.httpBody = parameters.data(using: .utf8)
        } catch {
            options.queue.async { completion(account, NKError(error: error)) }
            return
        }
        
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).response(queue: NKCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NKError(error: error, afResponse: response)
                options.queue.async { completion(account, error) }
            case .success( _):
                options.queue.async { completion(account, .success) }
            }
        }
    }
    
    @objc public func updateComments(fileId: String,
                                     messageId: String,
                                     message: String,
                                     options: NKRequestOptions = NKRequestOptions(),
                                     completion: @escaping (_ account: String, _ error: NKError) -> Void) {
        
        let account = NKCommon.shared.account

        let serverUrlEndpoint = NKCommon.shared.urlBase + "/" + NKCommon.shared.dav + "/comments/files/" + fileId + "/" + messageId
        
        guard let url = serverUrlEndpoint.encodedToUrl else {
            return options.queue.async { completion(account, .urlError) }
        }
        
        let method = HTTPMethod(rawValue: "PROPPATCH")
        let headers = NKCommon.shared.getStandardHeaders(options.customHeader, customUserAgent: options.customUserAgent, contentType: "application/xml")

        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            let parameters = String(format: NKDataFileXML().requestBodyCommentsUpdate, message)
            urlRequest.httpBody = parameters.data(using: .utf8)
        } catch {
            options.queue.async { completion(account, NKError(error: error)) }
            return
        }
        
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).response(queue: NKCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NKError(error: error, afResponse: response)
                options.queue.async { completion(account, error) }
            case .success( _):
                options.queue.async{ completion(account, .success) }
            }
        }
    }
    
    @objc public func deleteComments(fileId: String,
                                     messageId: String,
                                     options: NKRequestOptions = NKRequestOptions(),
                                     completion: @escaping (_ account: String, _ error: NKError) -> Void) {
        
        let account = NKCommon.shared.account
        
        let serverUrlEndpoint = NKCommon.shared.urlBase + "/" + NKCommon.shared.dav + "/comments/files/" + fileId + "/" + messageId
        
        guard let url = serverUrlEndpoint.encodedToUrl else {
            return options.queue.async { completion(account, .urlError) }
        }

        let headers = NKCommon.shared.getStandardHeaders(options: options)

        sessionManager.request(url, method: .delete, parameters: nil, encoding: URLEncoding.default, headers: headers, interceptor: nil).validate(statusCode: 200..<300).response(queue: NKCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NKError(error: error, afResponse: response)
                options.queue.async { completion(account, error) }
            case .success( _):
                options.queue.async { completion(account, .success) }
            }
        }
    }
    
    @objc public func markAsReadComments(fileId: String,
                                         options: NKRequestOptions = NKRequestOptions(),
                                         completion: @escaping (_ account: String, _ error: NKError) -> Void) {
        
        let account = NKCommon.shared.account
        
        let serverUrlEndpoint = NKCommon.shared.urlBase + "/" + NKCommon.shared.dav + "/comments/files/" + fileId
        
        guard let url = serverUrlEndpoint.encodedToUrl else {
            return options.queue.async { completion(account, .urlError) }
        }
        
        let method = HTTPMethod(rawValue: "PROPPATCH")
        let headers = NKCommon.shared.getStandardHeaders(options.customHeader, customUserAgent: options.customUserAgent, contentType: "application/xml")

        var urlRequest: URLRequest
        do {
            try urlRequest = URLRequest(url: url, method: method, headers: headers)
            let parameters = String(format: NKDataFileXML().requestBodyCommentsMarkAsRead)
            urlRequest.httpBody = parameters.data(using: .utf8)
        } catch {
            options.queue.async { completion(account, NKError(error: error)) }
            return
        }
        
        sessionManager.request(urlRequest).validate(statusCode: 200..<300).response(queue: NKCommon.shared.backgroundQueue) { (response) in
            debugPrint(response)
            
            switch response.result {
            case .failure(let error):
                let error = NKError(error: error, afResponse: response)
                options.queue.async { completion(account, error) }
            case .success( _):
                options.queue.async { completion(account, .success) }
            }
        }
    }
}
