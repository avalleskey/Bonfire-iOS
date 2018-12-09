//
//  SearchNavigationController.h
//  Pulse
//
//  Created by Austin Valleskey on 11/30/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFSearchView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SearchNavigationController : UINavigationController <UITextFieldDelegate>

@property (strong, nonatomic) UIView *navigationBackgroundView;
@property (strong, nonatomic) UIVisualEffectView *blurView;
@property (strong, nonatomic) UIView *hairline;

@property (strong, nonatomic) BFSearchView *searchView;
@property (strong, nonatomic) UIButton *cancelButton;

@end

NS_ASSUME_NONNULL_END
