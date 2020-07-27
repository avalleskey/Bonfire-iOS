//
//  String+Extensions.swift
//  Bonfire
//
//  Created by Austin Valleskey on 7/14/20.
//  Copyright © 2020 Ingenious. All rights reserved.
//

import UIKit

extension String {
    init?(htmlEncodedString: String) {

        guard let data = htmlEncodedString.data(using: .utf8) else {
            return nil
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        guard
            let attributedString = try? NSAttributedString(
                data: data, options: options, documentAttributes: nil)
        else {
            return nil
        }

        self.init(attributedString.string)

    }
    
    func timeAgoDisplay() -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.date(from: self)!
        
        let calendar = Calendar.current
        let minuteAgo = calendar.date(byAdding: .minute, value: -1, to: Date())!
        let hourAgo = calendar.date(byAdding: .hour, value: -1, to: Date())!
        let dayAgo = calendar.date(byAdding: .day, value: -1, to: Date())!
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        if minuteAgo < date {
            let diff = Calendar.current.dateComponents([.second], from: date, to: Date()).second ?? 0
            return "\(diff)s ago"
        } else if hourAgo < date {
            let diff = Calendar.current.dateComponents([.minute], from: date, to: Date()).minute ?? 0
            return "\(diff)m ago"
        } else if dayAgo < date {
            let diff = Calendar.current.dateComponents([.hour], from: date, to: Date()).hour ?? 0
            return "\(diff)h ago"
        } else if weekAgo < date {
            let diff = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
            return "\(diff)d ago"
        }
        let diff = Calendar.current.dateComponents([.weekOfYear], from: date, to: Date()).weekOfYear ?? 0
        return "\(diff)w ago"
    }
}
