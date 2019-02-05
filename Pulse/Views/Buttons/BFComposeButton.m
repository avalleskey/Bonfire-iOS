//
//  BFComposeButton.m
//  Pulse
//
//  Created by Austin Valleskey on 12/26/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "BFComposeButton.h"
#import "UIColor+Palette.h"

@implementation BFComposeButton

- (id)init {
    self = [super init];
    if (self) {
        [self setImage:[[UIImage imageNamed:@"composeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.tintColor = [UIColor whiteColor];
        self.layer.cornerRadius = self.frame.size.width / 2;
        self.layer.masksToBounds = false;
        self.backgroundColor = [UIColor bonfireBrand];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    self.layer.cornerRadius = self.frame.size.width / 2;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touchDown = YES;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.alpha = 0.25;
    }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Triggered when touch is released
    if (self.touchDown) {
        self.touchDown = NO;
        
        [self touchCancel];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Triggered if touch leaves view
    if (self.touchDown) {
        self.touchDown = NO;
        
        [self touchCancel];
    }
}

- (void)touchCancel {
    [UIView animateWithDuration:0.2f animations:^{
        self.alpha = 1;
    }];
}

@end
