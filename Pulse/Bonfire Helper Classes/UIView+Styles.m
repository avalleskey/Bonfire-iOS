//
//  UIView+Styles.m
//  Pulse
//
//  Created by Austin Valleskey on 2/18/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "UIView+Styles.h"
#import "UIColor+Palette.h"

@implementation UIView (Styles)

- (void)setCornerRadiusType:(BFCornerRadiusType)cornerRadiusType {
    CGFloat newCornerRadius = 0;
    switch (cornerRadiusType) {
        case BFCornerRadiusTypeSmall:
            newCornerRadius = 8;
            break;
        case BFCornerRadiusTypeMedium:
            newCornerRadius = 14;
            break;
        case BFCornerRadiusTypeLarge:
            newCornerRadius = 20;
            break;
        case BFCornerRadiusTypeCircle:
            newCornerRadius = (self.frame.size.width > self.frame.size.height ? self.frame.size.height / 2 : self.frame.size.width / 2);
            break;
            
        default:
            newCornerRadius = 0;
            break;
    }
    
    self.layer.cornerRadius = newCornerRadius;
}

- (void)setElevation:(NSInteger)elevation {
    self.layer.masksToBounds = false;
    self.layer.borderWidth = elevation > 0 ? HALF_PIXEL : 0;
    self.layer.borderColor = [UIColor tableViewSeparatorColor].CGColor;
    
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:MAX(0, (elevation > 0 ? 0.03 : 0)+(elevation*0.03))].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 1.5*elevation);
    self.layer.shadowRadius = roundf((1.5*elevation) * 0.75);
    self.layer.shadowOpacity = 1;
    self.layer.shouldRasterize = true;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
}

- (void)themeChanged {
    self.layer.borderColor = [UIColor tableViewSeparatorColor].CGColor;
}

@end
