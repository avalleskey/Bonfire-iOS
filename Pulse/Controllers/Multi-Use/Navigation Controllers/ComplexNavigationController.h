//
//  LauncherNavigationViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 9/27/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SloppySwiper.h"
#import "BFSearchView.h"
#import "Session.h"
#import "Room.h"
#import "Post.h"
#import "User.h"

@interface ComplexNavigationController : UINavigationController <UINavigationControllerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, SloppySwiperDelegate>

typedef enum {
    LNActionTypeNone = 0,
    LNActionTypeCancel = 1,
    LNActionTypeCompose = 2,
    LNActionTypeInvite = 3,
    LNActionTypeMore = 4,
    LNActionTypeAdd = 5,
    LNActionTypeBack = 6
} LNActionType;
- (void)setLeftAction:(LNActionType)actionType;
- (void)setRightAction:(LNActionType)actionType;

@property (nonatomic, strong) SloppySwiper *swiper;

@property (nonatomic, strong) UITableView *searchResultsTableView;
@property (nonatomic, strong) BFSearchView *searchView;

@property (nonatomic, strong) UIButton *leftActionButton;
@property (nonatomic, strong) UIButton *rightActionButton;

@property (nonatomic, strong) UIView *shadowView;
@property (nonatomic, strong) UIView *navigationBackgroundView;

- (void)goBack;

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animation;
- (void)updateBarColor:(id)newColor withAnimation:(int)animationType statusBarUpdateDelay:(CGFloat)statusBarUpdateDelay;
- (void)updateNavigationBarItemsWithAnimation:(BOOL)animated;

@property (nonatomic, strong) UIColor *currentTheme;

@property (nonatomic) CGFloat currentKeyboardHeight;
    
@property (nonatomic) BOOL isCreatingPost;

@end
