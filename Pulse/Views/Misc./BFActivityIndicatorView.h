//
//  BFActivityIndicatorView.h
//  Pulse
//
//  Created by Austin Valleskey on 3/6/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BFActivityIndicatorView : UIView

typedef enum {
    BFActivityIndicatorViewStyleSmall = 0,
    BFActivityIndicatorViewStyleLarge = 1
} BFActivityIndicatorViewStyle;
@property (nonatomic) BFActivityIndicatorViewStyle style;

- (id)initWithStyle:(BFActivityIndicatorViewStyle)style;

@property(nonatomic, strong) UIColor *color;
@property(nonatomic, readonly, getter=isAnimating) BOOL animating;

- (void)startAnimating;
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
