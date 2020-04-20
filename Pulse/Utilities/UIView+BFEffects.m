//
//  BFEffects.m
//  Pulse
//
//  Created by Austin Valleskey on 4/7/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "UIView+BFEffects.h"

@implementation UIView (BFEffects)

- (void)showEffect:(BFEffectType)effectType completion:(void (^__nullable)(void))completion {
    if (effectType == BFEffectTypeBalloons) {
        [self balloons:completion];
    }
    else if (effectType == BFEffectTypeEmojis) {
        [self emojis:@"🔥" completion:completion];
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
        
        [UIView animateWithDuration:[balloon[@"duration"] floatValue] delay:[balloon[@"delay"] floatValue] options:UIViewAnimationOptionCurveEaseOut animations:^{
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
- (void)emojis:(NSString *)emoji completion:(void (^__nullable)(void))completion {
    DLog(@"start emojis!!!!");
    CGFloat emojis = 30;
    
    for (NSInteger b = 0; b < emojis; b++) {
        UIFont *font = [UIFont systemFontOfSize:32+arc4random_uniform(64)];
        
        NSUInteger x = arc4random_uniform(self.frame.size.width + 32) - 16;
        NSUInteger xFinal = x + (arc4random_uniform(32) - 16);
        
        CGFloat y = self.frame.size.height + font.lineHeight;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, y, font.lineHeight, font.lineHeight)];
        label.text = emoji;
        label.tag = b;
        label.font = font;
        [self addSubview:label];
        
        srand48(time(&b));
        double r = drand48();
        CGFloat duration = 3.f + (2.f * r);
        
        CGFloat delay = pow(2, b / 10) - 1;
        
        [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveEaseOut animations:^{
            label.frame = CGRectMake(xFinal, label.frame.size.height * -1, label.frame.size.width, label.frame.size.height);
        } completion:^(BOOL finished) {
            [label removeFromSuperview];
            
            if (label.tag == emojis - 1) {
                // last one
                if (completion) {
                    completion();
                }
            }
        }];
    }
}

@end
