//
//  NSURL+WebsiteTypeValidation.m
//  Pulse
//
//  Created by Austin Valleskey on 8/7/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "NSURL+WebsiteTypeValidation.h"

@implementation NSURL (WebsiteTypeValidation)

- (BOOL)matches:(NSString *)pattern {
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger matches = [regEx numberOfMatchesInString:self.absoluteString options:0 range:NSMakeRange(0, [self.absoluteString length])];
    return (matches == 1);
}

@end
