//
//  BFTabBar.m
//  Pulse
//
//  Created by Austin Valleskey on 8/5/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFTabBar.h"

@implementation BFTabBar

-(CGSize)sizeThatFits:(CGSize)size
{
    CGSize sizeThatFits;
    if (IS_IPAD) {
        sizeThatFits = [super sizeThatFits:size];
        sizeThatFits.height = 52 + ([[UIApplication sharedApplication] keyWindow].safeAreaInsets.bottom);
    }
    else {
        sizeThatFits = [super sizeThatFits:size];
            sizeThatFits.height = 52 + ([[UIApplication sharedApplication] keyWindow].safeAreaInsets.bottom);
    }

    return sizeThatFits;
}

@end
