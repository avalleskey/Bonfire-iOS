//
//  BFEffects.m
//  Pulse
//
//  Created by Austin Valleskey on 4/7/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "UIView+BFEffects.h"

@implementation UIView (BFEffects)

NSString * const BFEffectEmojiStringAttributeName = @"emoji_string";
NSString * const BFEffectEmojisArrayAttributeName = @"emojis_array";

- (void)showEffect:(BFEffectType)effectType completion:(void (^__nullable)(void))completion {
    [self showEffect:effectType options:nil completion:completion];
}
- (void)showEffect:(BFEffectType)effectType options:(NSDictionary * _Nullable)options completion:(void (^__nullable)(void))completion {
    if (!options) options = @{};
    
    if (effectType == BFEffectTypeBalloons) {
        [self balloons:completion];
    }
    else if (effectType == BFEffectTypeEmojis) {
        NSMutableArray *emojis = [NSMutableArray new];
        
        NSString *emojiString = (NSString *)[options objectForKey:BFEffectEmojiStringAttributeName];
        NSArray *emojisArray = (NSArray *)[options objectForKey:BFEffectEmojisArrayAttributeName];
        
        if (emojiString) {
            for (int i = 0; i < emojiString.length; i++) {
                [emojis addObject:[emojiString substringWithRange:[emojiString rangeOfComposedCharacterSequencesForRange:NSMakeRange(i, 1)]]];
            }
        }
        else if (emojisArray) {
            [emojis addObjectsFromArray:emojisArray];
        }
        else {
            [emojis addObjectsFromArray:@[@"🔥"]];
        }
        
        if (emojis.count > 0) {
            [self emojis:emojis completion:completion];
        }
    }
}

- (void)balloons:(void (^__nullable)(void))completion {
    DLog(@"start balloons!!!!");
    NSMutableArray *balloons = [NSMutableArray new];
    
    [balloons addObject:@{
        @"color": @"orange",
        @"scale": @(1.0),
        @"xPosStart": @(0),
        @"xPosEnd": @(0.1),
        @"delay": @(0),
        @"duration": @(4.5)
    }];
    
    [balloons addObject:@{
        @"color": @"yellow",
        @"scale": @(1.25),
        @"xPosStart": @(0.25),
        @"xPosEnd": @(0.4),
        @"delay": @(0.4),
        @"duration": @(3.75)
    }];
    
    [balloons addObject:@{
        @"color": @"blue",
        @"scale": @(0.75),
        @"xPosStart": @(0.4),
        @"xPosEnd": @(0.3),
        @"delay": @(1.0),
        @"duration": @(4)
    }];
    
    [balloons addObject:@{
        @"color": @"green",
        @"scale": @(1.0),
        @"xPosStart": @(0.1),
        @"xPosEnd": @(0.15),
        @"delay": @(1.2),
        @"duration": @(5)
    }];
    
    [balloons addObject:@{
        @"color": @"pink",
        @"scale": @(1.5),
        @"xPosStart": @(0.8),
        @"xPosEnd": @(0.65),
        @"delay": @(1.6),
        @"duration": @(3.5)
    }];
    
    [balloons addObject:@{
        @"color": @"purple",
        @"scale": @(1.75),
        @"xPosStart": @(0.9),
        @"xPosEnd": @(0.95),
        @"delay": @(2.5),
        @"duration": @(4)
    }];
    
    [balloons addObject:@{
        @"color": @"orange",
        @"scale": @(1.75),
        @"xPosStart": @(0.0),
        @"xPosEnd": @(0.95),
        @"delay": @(2.3),
        @"duration": @(3)
    }];
    
    CGFloat xMin = -40;
    CGFloat xMax = self.frame.size.width + 40;
    for (NSInteger b = 0; b < balloons.count; b++) {
        NSDictionary *balloon = balloons[b];
        
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"balloon_%@", balloon[@"color"]]];
        CGFloat scale = [balloon[@"scale"] floatValue];
        CGFloat width = image.size.width * scale;
        CGFloat height = image.size.height * scale;
        CGFloat xStart = [balloon[@"xPosStart"] floatValue] * ((xMax - width) - xMin);
        CGFloat xEnd = [balloon[@"xPosEnd"] floatValue] * ((xMax - width) - xMin);
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.tag = b;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.frame = CGRectMake(xStart, self.frame.size.height, width, height);
        [self addSubview:imageView];
        
        [UIView animateWithDuration:[balloon[@"duration"] floatValue] delay:[balloon[@"delay"] floatValue] options:UIViewAnimationOptionCurveLinear animations:^{
            imageView.frame = CGRectMake(xEnd, -(height), width, height);
        } completion:^(BOOL finished) {
            [imageView removeFromSuperview];
            
            if (imageView.tag == balloons.count - 1) {
                // last one
                if (completion) {
                    completion();
                }
            }
        }];
    }
}
- (void)emojis:(NSArray<NSString *> *)emojis completion:(void (^__nullable)(void))completion {
    DLog(@"start emojis!!!!");
    CGFloat count = 24;
    
    for (NSInteger b = 0; b < count; b++) {
        UIFont *font = [UIFont systemFontOfSize:48+arc4random_uniform(48)];
        
        double r = drand48();
        
        NSUInteger x = arc4random_uniform(self.frame.size.width + 32) - 16;
        NSUInteger xFinal = x + (32*r - 16);
        
        CGFloat y = self.frame.size.height + font.lineHeight;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, y, font.lineHeight, font.lineHeight)];
        label.text = emojis[b % emojis.count];
        label.tag = b;
        label.font = font;
        [self addSubview:label];
        
        CGFloat duration = 0.8f + (2.f * r);
                
        NSLog(@"x: %lu", (unsigned long)x);
        NSLog(@"xFinal: %lu", (unsigned long)xFinal);
        NSLog(@"font size: %f", font.pointSize);
        
        [UIView animateWithDuration:duration delay:0.04*b options:UIViewAnimationOptionCurveEaseOut animations:^{
            label.frame = CGRectMake(xFinal, label.frame.size.height * -1, label.frame.size.width, label.frame.size.height);
        } completion:^(BOOL finished) {
            [label removeFromSuperview];
            
            if (label.tag == count - 1) {
                // last one
                if (completion) {
                    completion();
                }
            }
        }];
    }
}

@end
