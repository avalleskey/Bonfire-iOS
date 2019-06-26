//
//  BFTappableLabel.m
//  Pulse
//
//  Created by Austin Valleskey on 5/16/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFTappableLabel.h"

@implementation BFTappableLabel

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.userInteractionEnabled = true;
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnLabel:)]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

- (void)handleTapOnLabel:(UITapGestureRecognizer *)sender {
    
}

@end
