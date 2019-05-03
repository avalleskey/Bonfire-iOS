//
//  BFRefreshControl.h
//  Pulse
//
//  Created by Austin Valleskey on 4/6/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "ISAlternativeRefreshControl.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFRefreshControl : ISAlternativeRefreshControl {
    NSArray *colors;
    int currentColor;
}

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *progressView;
@property (nonatomic, strong) UIImageView *miniSpinner;

- (void)startAnimating;
- (void)stopAnimating;

- (void)endRefreshingWithDelay:(BOOL)delay;

@end

NS_ASSUME_NONNULL_END
