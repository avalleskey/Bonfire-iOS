//
//  APIClient.swift
//  Bonfire
//
//  Created by James Dale on 20/6/20.
//  Copyright © 2020 James Dale. All rights reserved.
//

import Foundation

public typealias APICompletionHandler<APIResponse> = (Result<APIResponse, Error>) -> Void

public struct APIClient {
    
    public static let shared = APIClient()
    
    private let baseURL = URL(string: "https://api.bonfire.camp")
    
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
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // TODO: You'll need to add the below if you want to do some kind of keychain-based auth.
//        if request is RefreshToken {
//            if let refreshToken = Vault.refreshToken {
//                urlRequest.addValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
//            }
//        } else if let token = Vault.authToken {
//            urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        }

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
                completion(.success(decoded))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func urlForEndpoint<T: APIRequest>(_ request: T) -> URL? {
        return URL(string: request.resource, relativeTo: baseURL)
    }
    
}

