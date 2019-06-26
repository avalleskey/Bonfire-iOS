//
//  Launcher.h
//  Pulse
//
//  Created by Austin Valleskey on 11/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "Camp.h"
#import "Post.h"
#import "User.h"
#import "SOLOptionsTransitionAnimator.h"
#import "ComplexNavigationController.h"
#import "TabController.h"

NS_ASSUME_NONNULL_BEGIN

@interface Launcher : NSObject <UIViewControllerTransitioningDelegate>

+ (Launcher *)sharedInstance;
@property (nonatomic, strong) SOLOptionsTransitionAnimator *animator;

+ (void)launchLoggedIn:(BOOL)animated;

+ (void)openTimeline;
+ (void)openTrending;
+ (void)openSearch;

+ (void)openCamp:(Camp *)camp;
+ (void)openCampMembersForCamp:(Camp *)camp;
+ (void)openPost:(Post *)post withKeyboard:(BOOL)withKeyboard;
+ (void)openPostReply:(Post *)post sender:(UIView *)sender;
+ (void)openProfile:(User *)user;
+ (void)openProfileCampsJoined:(User *)user;
+ (void)openProfileUsersFollowing:(User *)user;
+ (void)openCreateCamp;
+ (void)openComposePost:(Camp * _Nullable)camp inReplyTo:(Post * _Nullable)replyingTo withMessage:(NSString * _Nullable)message media:(NSArray * _Nullable)media;
+ (void)openEditProfile;
+ (void)openInviteFriends:(id)sender;
+ (void)openOnboarding;
+ (void)openSettings;

+ (void)openURL:(NSString *)urlString;
+ (void)openDebugView:(id)object;

+ (void)copyBetaInviteLink;

// share sheets
+ (void)sharePost:(Post *)post;
+ (void)shareCamp:(Camp *)camp;
+ (void)shareUser:(User *)user;
+ (void)shareOniMessage:(NSString *)message image:(UIImage * _Nullable)image;
+ (void)openActionsForPost:(Post *)post;

+ (void)expandImageView:(UIImageView *)imageView;
+ (void)exapndImageView:(UIImageView *)imageView media:(NSArray *)media imageViews:(NSArray <UIImageView *> *)imageViews selectedIndex:(NSInteger)selectedIndex;
+ (void)requestAppStoreRating;

+ (TabController *)tabController;
+ (UITabBarController *)activeTabController;
+ (UINavigationController *)activeNavigationController;
+ (ComplexNavigationController *)activeLauncherNavigationController;
+ (UIViewController *)activeViewController;
+ (UIViewController *)topMostViewController;

+ (void)present:(UIViewController *)viewController animated:(BOOL)animated;
+ (void)push:(UIViewController *)viewController animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
