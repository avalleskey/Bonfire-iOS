//
//  APIClient.swift
//  Bonfire
//
//  Created by James Dale on 20/6/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import Foundation

public typealias APICompletionHandler<APIResponse> = (Result<APIResponse, Error>) -> Void

public final class APIClient {

    public static let shared = APIClient()
    
    private var retryCount = 0

    private let baseURL = URL(string: "https://api.bonfire.camp/v1/")

    private let session = URLSession(configuration: .default)

    public func send<T: APIRequest>(
        _ request: T, completion: @escaping APICompletionHandler<T.Response>
    ) {
        guard let endpointURL = urlForEndpoint(request) else {
            completion(.failure(APIError.invalidEndpoint))
            return
        }

        print("[HTTP]", request.resource)

        var urlRequest = URLRequest(url: endpointURL)
        urlRequest.httpBody = request.body
        urlRequest.httpMethod = request.method
        urlRequest.addValue(
            "application/json",
            forHTTPHeaderField: "Content-Type")
        urlRequest.addValue(
            "iosClient/2.0 b3/release",
            forHTTPHeaderField: "X-Bonfire-Client")

        if request.authenticationType == .appAuth {
            urlRequest.addValue(
                "Bearer c82f5645-8836-48d0-e4c2-4a2151317b97",
                forHTTPHeaderField: "Authorization")
        } else if request.authenticationType == .userAuth {
            if let token = KeychainVault.accessToken {
                urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                completion(.failure(APIError.unauthenticated))
                return
            }
        }

        session.dataTask(with: urlRequest) { [self] (data, response, error) in
            guard error == nil else {
                let error = error ?? APIError.unknown
                completion(.failure(error))
                return
            }

            if let httpResp = response as? HTTPURLResponse {
                let code = httpResp.statusCode
                print("[HTTP]", code, String(data: data ?? Data(), encoding: .utf8) ?? "--")
                
                if code == 401 && retryCount < 3 {
                    KeychainVault.accessToken = nil
                    //TODO: Refresh
                    retryCount += 1
                    send(request, completion: completion)
                    return
                } else if code == 200 {
                    self.retryCount = 0
                }
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
