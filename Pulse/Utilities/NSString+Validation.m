//
//  NSString+Validation.m
//  Pulse
//
//  Created by Austin Valleskey on 12/12/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "NSString+Validation.h"
#import "GTMNSString+HTML.h"

@implementation NSString (Validation)

- (BFValidationError)validateBonfireEmail {
    NSString *regExPattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,63}";
    
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:regExPattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger regExMatches = [regEx numberOfMatchesInString:self options:0 range:NSMakeRange(0, [self length])];
    
    if (regExMatches == 1) return BFValidationErrorNone;
    
    return BFValidationErrorInvalidEmail;
}

- (BFValidationError)validateBonfirePassword {
    if (self.length < MIN_PASSWORD_LENGTH) return BFValidationErrorTooShort;
    if (self.length > MAX_PASSWORD_LENGTH) return BFValidationErrorTooLong;
    
    return BFValidationErrorNone;
}

- (BFValidationError)validateBonfireDisplayName {
    if (self == nil || self.length == 0) return BFValidationErrorTooShort;
    if (self.length > MAX_USER_DISPLAY_NAME_LENGTH) return BFValidationErrorTooLong;
    if (self.length == 0) return BFValidationErrorTooShort;
    
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
    NSLog(@"validateBonfireUsername");
    NSString *string = self;
    if ([string hasPrefix:@"@"] && [string length] > 1) {
        string = [string substringFromIndex:1];
    }
    
    NSLog(@"string: %@", string);
    
    if (string.length < 3) {
        NSLog(@"BFValidationErrorTooShort");
        return BFValidationErrorTooShort;
    }
    if (string.length > MAX_USER_USERNAME_LENGTH) {
        NSLog(@"BFValidationErrorTooLong");
        return BFValidationErrorTooLong;
    }
    
    NSString *regExPattern = @"^[A-Za-z0-9\\_]+$";
    BOOL matches = [string rx_matchesPattern:regExPattern];
    if (!matches) {
        NSLog(@"BFValidationErrorContainsInvalidCharacters");
        return BFValidationErrorContainsInvalidCharacters;
    }
    
    // To protect our community, we maintain a list of words that cannot be included be used as usernames
    // all usernames in this list must be lowercase
    NSArray *invalidUsernames = @[@"mod"];
    if ([invalidUsernames containsObject:[string lowercaseString]]) {
        NSLog(@"BFValidationErrorContainsInvalidWords 1");
        return BFValidationErrorContainsInvalidWords;
    }
    
    // To protect our community, we maintain a list of words that cannot be included anywhere in a username
    NSArray *invalidWords = @[@"bonfire", @"admin", @"moderator"];
    for (NSString *invalidWord in invalidWords) {
        if ([[string lowercaseString] containsString:[invalidWord lowercaseString]]) {
            NSLog(@"BFValidationErrorContainsInvalidWords 2");
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

- (BFValidationError)validateBonfireCampTitle {
    NSLog(@"soft length: %lu", (unsigned long)self.length);
    NSLog(@"hard length: %lu", (unsigned long)[self gtm_stringByEscapingForAsciiHTML].length);
    
    if (self.length < 1) return BFValidationErrorTooShort;
    if (self.length > MAX_CAMP_TITLE_SOFT_LENGTH || [self gtm_stringByEscapingForAsciiHTML].length > MAX_CAMP_TITLE_HARD_LENGTH) return BFValidationErrorTooLong;
    
    return BFValidationErrorNone;
}

- (BFValidationError)validateBonfireCampTag {
    NSString *string = self;
    if ([string hasPrefix:@"#"] && [string length] > 1) {
        string = [string substringFromIndex:1];
    }
    
    if (string.length < 1) return BFValidationErrorTooShort; // at least 1 character long
    if (string.length > MAX_CAMP_TAG_LENGTH) return BFValidationErrorTooLong;
    
    NSString *regExPattern = @"^[A-Za-z0-9\\_]+$";
    BOOL matches = [string rx_matchesPattern:regExPattern];
    if (!matches) return BFValidationErrorContainsInvalidCharacters;
    
    return BFValidationErrorNone;
}

- (BFValidationError)validateBonfireCampDescription {
    if (self.length > MAX_CAMP_DESC_SOFT_LENGTH || [self gtm_stringByEscapingForAsciiHTML].length > MAX_CAMP_DESC_HARD_LENGTH) return BFValidationErrorTooLong;
    
    return BFValidationErrorNone;
}

//

- (NSArray *)rangesForUsernameMatches {
    NSMutableArray *matchRanges = [[NSMutableArray alloc] init];
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"(?!\\b)@([A-Za-z0-9_]{1,%i})(?=\\s|\\W|$)(?!@)", MAX_USER_USERNAME_LENGTH] options:NSRegularExpressionCaseInsensitive error:nil];
    [regEx enumerateMatchesInString:self options:0 range:NSMakeRange(0, self.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        [matchRanges addObject:[NSValue valueWithRange:result.range]];
    }];
    
    return [matchRanges copy];
}
- (NSArray *)rangesForCampTagMatches {
    NSMutableArray *matchRanges = [[NSMutableArray alloc] init];
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:[NSString stringWithFormat:@"(?!\\b)#([A-Za-z0-9_]{1,%i})(?=\\s|\\W|$)(?!#)", MAX_CAMP_TAG_LENGTH] options:NSRegularExpressionCaseInsensitive error:nil];
    [regEx enumerateMatchesInString:self options:0 range:NSMakeRange(0, self.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        [matchRanges addObject:[NSValue valueWithRange:result.range]];
    }];
    
    return [matchRanges copy];
}
- (NSArray *)rangesForLinkMatches {
    NSMutableArray *matchRanges = [[NSMutableArray alloc] init];
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:@"((https|http)?:\\/\\/|)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&//=]*)" options:NSRegularExpressionCaseInsensitive error:nil];
    [regEx enumerateMatchesInString:self options:0 range:NSMakeRange(0, self.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        NSLog(@"result.range:: %lu / %lu", (unsigned long)result.range.location, (unsigned long)result.range.length);
        [matchRanges addObject:[NSValue valueWithRange:result.range]];
    }];
    
    return [matchRanges copy];
}

@end
