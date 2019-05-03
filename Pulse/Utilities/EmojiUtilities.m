//
//  EmojiUtilities.m
//  Pulse
//
//  Created by Austin Valleskey on 3/27/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "EmojiUtilities.h"

@implementation EmojiUtilities

+ (CFCharacterSetRef)emojiCharacterSet {
    static CFCharacterSetRef set = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        set = CTFontCopyCharacterSet(CTFontCreateWithName(CFSTR("AppleColorEmoji"), 0.0, NULL));
    });
    return set;
}

+ (BOOL)containsEmoji:(NSString *)string {
    return CFStringFindCharacterFromSet((CFStringRef)string, [self emojiCharacterSet], CFRangeMake(0, string.length), 0, NULL);
}

@end
