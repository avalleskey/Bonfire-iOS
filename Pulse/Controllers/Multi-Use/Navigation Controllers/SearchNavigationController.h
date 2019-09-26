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

@property (nonatomic, strong) BFSearchView *searchView;
@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic) BOOL hideCancelOnBlur;

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animated;
- (void)hideBottomHairline;
- (void)showBottomHairline;
@property (nonatomic, strong) UIView *bottomHairline;

@end

NS_ASSUME_NONNULL_END
