//
//  NSString+Validation.m
//  Pulse
//
//  Created by Austin Valleskey on 12/12/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "NSString+Validation.h"

@implementation NSString (Validation)

- (BFValidationError)validateBonfireEmail {
    NSString *regExPattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,63}";
    
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:regExPattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger regExMatches = [regEx numberOfMatchesInString:self options:0 range:NSMakeRange(0, [self length])];
    
    if (regExMatches == 1) return BFValidationErrorNone;
    
    return BFValidationErrorInvalidEmail;
}

- (BFValidationError)validateBonfirePassword {
    if (self.length < 6) return BFValidationErrorTooShort;
    if (self.length > MAX_PASSWORD_LENGTH) return BFValidationErrorTooLong;
    
    return BFValidationErrorNone;
}

- (BFValidationError)validateBonfireDisplayName {
    if (self.length == 0) return BFValidationErrorTooShort;
    if (self.length > MAX_USER_DISPLAY_NAME_LENGTH) return BFValidationErrorTooLong;
    
    // To protect our community, we maintain a list of words that cannot be used in display names
    NSArray *invalidWords = @[@"bonfire", @"admin", @"moderator", @"mod"];
    for (NSString *invalidWord in invalidWords) {
        for (NSString *word in [self componentsSeparatedByString:@" "]) {
            if ([[word lowercaseString] isEqualToString:[invalidWord lowercaseString]]) {
                return BFValidationErrorContainsInvalidWords;
            }
        }
    }
    
    return BFValidationErrorNone;
}

- (BFValidationError)validateBonfireUsername {
    NSString *string = self;
    if ([string hasPrefix:@"@"] && [string length] > 1) {
        string = [string substringFromIndex:1];
    }
    
    if (string.length < 3) return BFValidationErrorTooShort;
    if (string.length > MAX_USER_USERNAME_LENGTH) return BFValidationErrorTooLong;
    
    NSString *regExPattern = @"^[A-Za-z0-9\\_]+$";
    BOOL matches = [string rx_matchesPattern:regExPattern];
    if (!matches) return BFValidationErrorContainsInvalidCharacters;
    
    // To protect our community, we maintain a list of words that cannot be included be used as usernames
    // all usernames in this list must be lowercase
    NSArray *invalidUsernames = @[@"mod"];
    if ([invalidUsernames containsObject:[string lowercaseString]])
        return BFValidationErrorContainsInvalidWords;
    
    // To protect our community, we maintain a list of words that cannot be included anywhere in a username
    NSArray *invalidWords = @[@"bonfire", @"admin", @"moderator"];
    for (NSString *invalidWord in invalidWords) {
        if ([[string lowercaseString] containsString:[invalidWord lowercaseString]]) {
            return BFValidationErrorContainsInvalidWords;
        }
    }

    return BFValidationErrorNone;
}

- (BFValidationError)validateBonfireBio {
    if (self.length > MAX_USER_BIO_LENGTH) return BFValidationErrorTooLong;
    
    return BFValidationErrorNone;
}

- (BFValidationError)validateBonfireLocation {
    if (self.length > MAX_USER_LOCATION_LENGTH) return BFValidationErrorTooLong;
    
    return BFValidationErrorNone;
}

- (BFValidationError)validateBonfireWebsite {
    if (self.length > MAX_USER_WEBSITE_LENGTH) return BFValidationErrorTooLong;
    
    NSString *website = self;
    if ([self rangeOfString:@"http://"].length == 0 && [self rangeOfString:@"https://"].length == 0) {
        website = [@"http://" stringByAppendingString:website];
    }
    else if (([self rangeOfString:@"http://"].length > 0 && [self rangeOfString:@"http://"].location > 0) || ([self rangeOfString:@"https://"].length > 0 && [self rangeOfString:@"https://"].location > 0)) {
        return BFValidationErrorInvalidURL;
    }
    
    NSURL *url = [NSURL URLWithString:website];
    BOOL validURL = url && url.host;
    if (!validURL) return BFValidationErrorInvalidURL;
    
    return BFValidationErrorNone;
}

- (BFValidationError)validateBonfireRoomTitle {
    if (self.length < 1) return BFValidationErrorTooShort;
    if (self.length > MAX_ROOM_TITLE_LENGTH) return BFValidationErrorTooShort;
    
    return BFValidationErrorNone;
}

- (BFValidationError)validateBonfireRoomTag {
    NSString *string = self;
    if ([string hasPrefix:@"#"] && [string length] > 1) {
        string = [string substringFromIndex:1];
    }
    
    if (string.length < 1) return BFValidationErrorTooShort; // at least 1 character long
    if (string.length > MAX_ROOM_TAG_LENGTH) return BFValidationErrorTooLong;
    
    NSString *regExPattern = @"^[A-Za-z0-9\\_]+$";
    BOOL matches = [string rx_matchesPattern:regExPattern];
    if (!matches) return BFValidationErrorContainsInvalidCharacters;
    
    return BFValidationErrorNone;
}

- (BFValidationError)validateBonfireRoomDescription {
    if (self.length > MAX_ROOM_DESC_LENGTH) return BFValidationErrorTooLong;
    
    return BFValidationErrorNone;
}

@end
