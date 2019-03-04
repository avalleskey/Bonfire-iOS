//
//  Launcher.h
//  Pulse
//
//  Created by Austin Valleskey on 11/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "Room.h"
#import "Post.h"
#import "User.h"
#import "SOLOptionsTransitionAnimator.h"
#import "ZFModalTransitionAnimator.h"
#import "ComplexNavigationController.h"
#import <JTSImageViewController/JTSImageViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface Launcher : NSObject <UIViewControllerTransitioningDelegate>

+ (Launcher *)sharedInstance;
@property (strong, nonatomic) SOLOptionsTransitionAnimator *animator;
@property (strong, nonatomic) ZFModalTransitionAnimator *ZFAnimator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition *interactionController;

- (void)launchLoggedIn:(BOOL)animated;

- (void)openTimeline;
- (void)openTrending;
- (void)openSearch;

- (void)openRoom:(Room *)room;
- (void)openRoomMembersForRoom:(Room *)room;
- (void)openPost:(Post *)post withKeyboard:(BOOL)withKeyboard;
- (void)openPostReply:(Post *)post sender:(UIView *)sender;
- (void)openProfile:(User *)user;
- (void)openProfileCampsJoined:(User *)user;
- (void)openProfileUsersFollowing:(User *)user;
- (void)openCreateRoom;
- (void)openComposePost:(Room * _Nullable)room inReplyTo:(Post * _Nullable)replyingTo withMessage:(NSString * _Nullable)message media:(NSArray * _Nullable)media;
- (void)openEditProfile;
- (void)openInviteFriends:(id)sender;
- (void)openOnboarding;
- (void)openSettings;

- (void)openURL:(NSString *)urlString;

// share sheets
- (void)sharePost:(Post *)post;
- (void)shareRoom:(Room *)room;
- (void)shareUser:(User *)user;
- (void)shareOniMessage:(NSString *)message image:(UIImage * _Nullable)image;

- (void)expandImageView:(UIImageView *)imageView;
- (void)requestAppStoreRating;

- (UITabBarController *)activeTabController;
- (ComplexNavigationController *)activeLauncherNavigationController;
- (UIViewController *)activeViewController;

- (void)present:(UIViewController *)viewController animated:(BOOL)animated;
- (void)push:(UIViewController *)viewController animated:(BOOL)animated;

- (void)openTweaks;

@end

@interface PushAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@end

@interface PopAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@end

NS_ASSUME_NONNULL_END
