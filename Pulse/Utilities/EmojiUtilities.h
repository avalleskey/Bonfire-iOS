//
//  EmojiUtilities.h
//  Pulse
//
//  Created by Austin Valleskey on 3/27/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreText/CoreText.h>

NS_ASSUME_NONNULL_BEGIN

@interface EmojiUtilities : NSObject

+ (CFCharacterSetRef)emojiCharacterSet;
+ (BOOL)containsEmoji:(NSString *)emoji;

@end

NS_ASSUME_NONNULL_END
