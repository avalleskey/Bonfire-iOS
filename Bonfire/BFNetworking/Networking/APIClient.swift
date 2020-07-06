//
//  APIClient.swift
//  Bonfire
//
//  Created by James Dale on 20/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public typealias APICompletionHandler<APIResponse> = (Result<APIResponse, Error>) -> Void

public struct APIClient {
    
    public static let shared = APIClient()
    
    private let baseURL = URL(string: "https://api.bonfire.camp/v1/")
    
    private let session = URLSession(configuration: .default)
    
    public func send<T: APIRequest>(_ request: T, completion: @escaping APICompletionHandler<T.Response> ) {
        guard let endpointURL = urlForEndpoint(request) else {
            completion(.failure(APIError.invalidEndpoint))
            return
        }
        
        print("[HTTP]", request.resource)
        
        var urlRequest = URLRequest(url: endpointURL)
        urlRequest.httpBody = request.body
        urlRequest.httpMethod = request.method
        urlRequest.addValue("application/json",
                            forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("iosClient/2.0 b3/release",
                            forHTTPHeaderField: "X-Bonfire-Client")
        
        if request.authenticationType == .appAuth {
            urlRequest.addValue("Bearer c82f5645-8836-48d0-e4c2-4a2151317b97",
                                forHTTPHeaderField: "Authorization")
        } else if request.authenticationType == .userAuth {
            urlRequest.addValue("Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImp0aSI6IjAtNjE2LTQ1NjQyLTE1OTQwNTMyNTc1OTAxODY2MDc2NjQxMTU2NjYwIn0.eyJpc3MiOiJSb29tcy1BUEktSW50ZXJuYWwtQWNjZXNzIiwiYXVkIjoiYzgyZjU2NDUtODgzNi00OGQwLWU0YzItNGEyMTUxMzE3Yjk3IiwiaWF0IjoxNTk0MDUzMjU3LCJqdGkiOiIwLTYxNi00NTY0Mi0xNTk0MDUzMjU3NTkwMTg2NjA3NjY0MTE1NjY2MCIsImV4cCI6MTU5NDEzOTY1NywidWlkIjo2MTYsImxpZCI6MjM5ODUsImF0aWQiOjQ1NjQyLCJ0eXBlIjoiYWNjZXNzIiwic2NvcGUiOiJ1c2Vycyxwb3N0cyxjYW1wcyIsInYiOjF9.6oZHkdfz1AuzyQIYUw0Y6qXlgb6rOcmMObwRpU-UPPA",
                                forHTTPHeaderField: "Authorization")
        }

        session.dataTask(with: urlRequest) { (data, response, error) in
            guard error == nil else {
                let error = error ?? APIError.unknown
                completion(.failure(error))
                return
            }
            
            if let httpResp = response as? HTTPURLResponse {
                let code = httpResp.statusCode
                print("[HTTP]", code, String(data: data ?? Data(), encoding: .utf8) ?? "--")
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let decoded = try decoder.decode(T.Response.self, from: data)
                print("[Decoder]", "Success:", decoded)
                completion(.success(decoded))
            } catch {
                print("[Decoder] [Error]", T.Response.self, error.localizedDescription)
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func urlForEndpoint<T: APIRequest>(_ request: T) -> URL? {
        return URL(string: request.resource, relativeTo: baseURL)
    }
    
}
