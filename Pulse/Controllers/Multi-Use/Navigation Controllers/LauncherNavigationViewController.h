//
//  LauncherNavigationViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 9/27/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SOLOptionsTransitionAnimator.h"
#import "SloppySwiper.h"
#import "Session.h"
#import "Room.h"
#import "Post.h"
#import "User.h"

@interface ComplexNavigationController : UINavigationController <UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, SloppySwiperDelegate>

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

@property (strong, nonatomic) SloppySwiper *swiper;

@property (strong, nonatomic) UITableView *searchResultsTableView;
@property (strong, nonatomic) UITextField *textField;

@property (strong, nonatomic) UIButton *inviteFriendButton;
@property (strong, nonatomic) UIButton *composePostButton;
@property (strong, nonatomic) UIButton *infoButton;
@property (strong, nonatomic) UIButton *moreButton;
@property (strong, nonatomic) UIButton *backButton;

@property (strong, nonatomic) UIView *shadowView;
@property (strong, nonatomic) UIView *navigationBackgroundView;

- (void)goBack;

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animation;
- (void)updateBarColor:(id)newColor withAnimation:(int)animationType statusBarUpdateDelay:(CGFloat)statusBarUpdateDelay;
- (void)updateNavigationBarItemsWithAnimation:(BOOL)animated;
- (void)updateSearchText:(NSString *)newSearchText;

- (void)positionTextFieldSearchIcon;
- (void)showSearchIcon;
- (void)hideSearchIcon;

@property (strong, nonatomic) UIColor *currentTheme;

@property (nonatomic) CGFloat currentKeyboardHeight;
    
@property (nonatomic) BOOL isCreatingPost;

@end
