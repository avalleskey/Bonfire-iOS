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
#import "PostViewController.h"
#import "BotViewController.h"
#import "CampViewController.h"
#import "TabController.h"

#define VIEW_CONTROLLER_PUSH_TAG 99

NS_ASSUME_NONNULL_BEGIN

@interface Launcher : NSObject <UIViewControllerTransitioningDelegate>

+ (Launcher *)sharedInstance;
@property (nonatomic, strong) SOLOptionsTransitionAnimator *animator;

+ (void)launchLoggedIn:(BOOL)animated replaceRootViewController:(BOOL)replaceRootViewController;
@property (nonatomic, copy) void (^_Nullable launchAction)(void);

+ (void)openTimeline;
+ (void)openTrending;
+ (void)openSearch;
+ (void)openDiscover;

+ (void)openCamp:(Camp *)camp;
+ (CampViewController *)campViewControllerForCamp:(Camp *)camp;

+ (void)openPost:(Post *)post withKeyboard:(BOOL)withKeyboard;
+ (PostViewController *)postViewControllerForPost:(Post *)post;

+ (void)openProfile:(User *)user;
+ (ProfileViewController *)profileViewControllerForUser:(User *)user;

+ (void)openBot:(Bot *)bot;
+ (ProfileViewController *)profileViewControllerForBot:(Bot *)bot;

+ (void)openCampMembersForCamp:(Camp *)camp;
+ (void)openLinkConversations:(BFLink *)link withKeyboard:(BOOL)withKeyboard;
+ (void)openPostReply:(Post *)post sender:(UIView *)sender;
+ (void)openProfileCampsJoined:(User *)user;
+ (void)openProfileUsersFollowing:(User *)user;
+ (void)openCreateCamp;
+ (void)openComposePost:(Camp * _Nullable)camp inReplyTo:(Post * _Nullable)replyingTo withMessage:(NSString * _Nullable)message media:(NSArray * _Nullable)media quotedObject:(NSObject * _Nullable)quotedObject;
+ (void)openEditProfile;
+ (void)openInviteFriends:(id)sender;
+ (void)openInviteToCamp:(Camp *)camp;
+ (void)openOnboarding;
+ (void)openSettings;

+ (void)openURL:(NSString *)urlString;
+ (void)openDebugView:(id)object;

+ (void)openOutOfDateClient;

+ (void)copyBetaInviteLink;

// share sheets
+ (void)sharePost:(Post *)post;
+ (void)openPostActions:(Post *)post;
+ (void)shareCamp:(Camp *)camp;
+ (void)shareIdentity:(Identity *)identity;
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
