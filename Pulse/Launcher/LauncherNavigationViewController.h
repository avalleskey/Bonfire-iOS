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

@interface LauncherNavigationViewController : UINavigationController <UINavigationControllerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate, SloppySwiperDelegate>

@property (strong, nonatomic) SloppySwiper *swiper;

@property (strong, nonatomic) UITableView *searchResultsTableView;
@property (strong, nonatomic) UITextField *textField;

- (void)removeGestureRecognizersForView:(UIView *)view;

@property (strong, nonatomic) UIImageView *profilePicture;
@property (strong, nonatomic) UIButton *composePostButton;
@property (strong, nonatomic) UIButton *infoButton;
@property (strong, nonatomic) UIButton *moreButton;
@property (strong, nonatomic) UIButton *backButton;

@property (strong, nonatomic) UIView *shadowView;
@property (strong, nonatomic) UIView *navigationBackgroundView;

- (void)setShadowVisibility:(BOOL)visible withAnimation:(BOOL)animation;
- (void)updateBarColor:(id)newColor withAnimation:(int)animationType statusBarUpdateDelay:(CGFloat)statusBarUpdateDelay;
- (void)updateNavigationBarItemsWithAnimation:(BOOL)animated;

- (void)openRoom:(Room *)room;
- (void)openRoomMembersForRoom:(Room *)room;
- (void)openPost:(Post *)post;
- (void)openProfile:(User *)user;
- (void)openCreateRoom;
- (void)openComposePost;
- (void)openEditProfile;

@property (strong, nonatomic) UIColor *currentTheme;

@property (nonatomic) CGFloat currentKeyboardHeight;
    
@property (nonatomic) BOOL isCreatingPost;

@end

@interface PushAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@end

@interface PopAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@end
