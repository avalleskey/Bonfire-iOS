//
//  NSString+UTF.m
//  Pulse
//
//  Created by Austin Valleskey on 8/23/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "NSString+UTF.h"

@implementation NSString (UTF)

- (NSRange)composedRangeWithRange:(NSRange)range {
    // We're going to make a new range that takes into account surrogate unicode pairs (composed characters)
    __block NSRange adjustedRange = range;

    // Adjust the location
    [self enumerateSubstringsInRange:NSMakeRange(0, range.location + 1) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        // If they string the iterator found is greater than 1 in length, add that to range location.
        // This means that there is a composed character before where the range starts who's length is greater than 1.
        adjustedRange.location += substring.length - 1;
    }];

    // Adjust the length
    NSInteger length = self.length;

    // Count how many times we iterate so we only iterate over what we care about.
    __block NSInteger count = 0;
    [self enumerateSubstringsInRange:NSMakeRange(adjustedRange.location, length - adjustedRange.location) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        // If they string the iterator found is greater than 1 in length, add that to range length.
        // This means that there is a composed character inside of the range starts who's length is greater than 1.
        adjustedRange.length += substring.length - 1;

        // Add one to the count
        count++;

        // If we have iterated as many times as the original length, stop.
        if (range.length == count) {
            *stop = YES;
        }
    }];

    // Make sure we don't make an invalid range. This should never happen, but let's play it safe anyway.
    if (adjustedRange.location + adjustedRange.length > length) {
      adjustedRange.length = length - adjustedRange.location - 1;
    }

    // Return the adjusted range
    return adjustedRange;
}

@end
