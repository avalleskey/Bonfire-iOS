//
//  UIView+Styles.h
//  Pulse
//
//  Created by Austin Valleskey on 2/18/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Styles)

typedef enum {
    BFCornerRadiusTypeNone,
    BFCornerRadiusTypeSmall,
    BFCornerRadiusTypeMedium,
    BFCornerRadiusTypeLarge,
    BFCornerRadiusTypeCircle
} BFCornerRadiusType;
- (void)setCornerRadiusType:(BFCornerRadiusType)cornerRadiusType;

- (void)setElevation:(NSInteger)elevation;

- (void)themeChanged;

@end

NS_ASSUME_NONNULL_END
