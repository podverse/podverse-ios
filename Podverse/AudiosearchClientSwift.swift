//
//  Audiosearch.swift
//  AudiosearchClientSwift
//
//  Created by Anders Howerton on 1/28/16.
//  Copyright © 2016 Pop Up Archive. All rights reserved.
//

import Foundation
import Alamofire
import p2_OAuth2

// Audiosearch API Docs found at https://www.audiosear.ch/docs

class AudioSearchClientSwift {
    public typealias ServiceResponseAny = (AnyObject?, NSError?) -> Void
    
    static let base = "https://www.audiosear.ch/api/"
    
    static var oauth2 = OAuth2ClientCredentials(settings: [
        "client_id": "df0ec8d7ce31a8a5be833df0fe47a2e531bfa04e2081d64a5b24bdd6649908fb",
        "client_secret": "",
        "authorize_uri": "https://audiosear.ch/oauth/authorize",
        "token_uri": "https://audiosear.ch/oauth/token",
        "scope": "",
        "redirect_uris": ["urn:ietf:wg:oauth:2.0:oob"],
        "keychain": false,
        "secret_in_body": true,
        "verbose": "true"
        ] as OAuth2JSON)
    
    static let loader = OAuth2DataLoader(oauth2: oauth2)
    
    static func getAudiosearchAccessToken () {
        oauth2.authorize() { authParameters, error in
            if let params = authParameters {
                self.oauth2.accessToken = params["access_token"] as? String
            } else {
                print("Authorization Error: \(error)")
            }
        }
    }
    
    static func search(query: String, params: Dictionary<String,String>?, type: String, onCompletion: @escaping ServiceResponseAny) -> Void {
        var queryItems: [NSURLQueryItem] = []
        if let query = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let queryString = "https://www.audiosear.ch/api/search/\(type)/\(query)"
            let components = NSURLComponents(string: queryString)
            if params != nil {
                for (key, value) in params! {
                    queryItems.append(NSURLQueryItem(name: key, value: value as String))
                }
            }
            components?.queryItems = queryItems as [URLQueryItem]
            if let finalSearchUrl = URL(string: components!.string!) {
                let req = oauth2.request(forURL: finalSearchUrl)
                loader.perform(request: req) { response in
                    do {
                        if let result = try response.responseJSON() as? AnyObject {
                            onCompletion(result, nil)
                        }
                    }
                    catch {
                        onCompletion(nil, error as NSError)
                    }
                }
            }
        }
    }
    
    static func retrievePodcast(podcastId: Int64, onCompletion: @escaping ServiceResponseAny) -> Void {
        let urlString = "shows/" + String(podcastId)
        if let url = URL(string: urlString, relativeTo: AudiosearchBaseUrl) {
            let req = oauth2.request(forURL: url)
            loader.perform(request: req) { response in
                do {
                    if let result = try response.responseJSON() as? AnyObject {
                        onCompletion(result, nil)
                    }
                }
                catch {
                    onCompletion(nil, error as NSError)
                }
            }
        }
    }
    
    static func retrieveEpisodes(podcastId: String, onCompletion: @escaping ServiceResponseAny) -> Void {
        let urlString = "shows/" + podcastId + "/episodes"
        if let url = URL(string: urlString, relativeTo: AudiosearchBaseUrl) {
            let req = oauth2.request(forURL: url)
            loader.perform(request: req) { response in
                do {
                    if let result = try response.responseJSON() as? AnyObject {
                        onCompletion(result, nil)
                    }
                }
                catch {
                    onCompletion(nil, error as NSError)
                }
            }
        }
    }

}
