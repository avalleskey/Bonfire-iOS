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
#import "Camp.h"
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
    LNActionTypeBack = 6,
    LNActionTypeInfo = 7,
    LNActionTypeSettings = 8
} LNActionType;
- (void)setLeftAction:(LNActionType)actionType;
- (void)setRightAction:(LNActionType)actionType;

@property (nonatomic, strong) SloppySwiper *swiper;

@property (nonatomic, strong) UITableView *searchResultsTableView;

@property (nonatomic, strong) BFSearchView *searchView;

@property (nonatomic, strong) UIView *progressView;
@property (nonatomic) CGFloat progress;
// Additional progress methods
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated;
- (void)setProgress:(CGFloat)progress animated:(BOOL)animated hideOnCompletion:(BOOL)hideOnCompletion;

@property (nonatomic, strong) UIButton *leftActionButton;
@property (nonatomic, strong) UIButton *rightActionButton;

@property (nonatomic, strong) UIView *navigationBackgroundView;

- (void)goBack;

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animated;
- (void)hideBottomHairline;
- (void)showBottomHairline;
@property (nonatomic, strong) UIView *bottomHairline;

- (void)updateBarColor:(id)background animated:(BOOL)animated;

- (void)updateNavigationBarItemsWithAnimation:(BOOL)animated;

@property (nonatomic, strong) UIColor *currentTheme;

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (nonatomic) BOOL transparentOnLoad;

@property (nonatomic) CGFloat onScrollLowerBound;
@property (nonatomic) BOOL shadowOnScroll;
@property (nonatomic) BOOL opaqueOnScroll;
- (void)childTableViewDidScroll:(UITableView *)tableView;
    
@end
