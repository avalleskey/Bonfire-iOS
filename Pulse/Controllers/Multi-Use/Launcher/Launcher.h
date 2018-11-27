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

NS_ASSUME_NONNULL_BEGIN

@interface Launcher : NSObject <UIViewControllerTransitioningDelegate>

+ (Launcher *)sharedInstance;

- (void)launchLoggedIn:(BOOL)animated;

- (void)openTimeline;
- (void)openTrending;

- (void)openRoom:(Room *)room;
- (void)openRoomMembersForRoom:(Room *)room;
- (void)openPost:(Post *)post;
- (void)openProfile:(User *)user;
- (void)openCreateRoom;
- (void)openComposePost;
- (void)openEditProfile;
- (void)openInviteFriends;
- (void)openOnboarding;

@end

@interface PushAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@end

@interface PopAnimator : NSObject <UIViewControllerAnimatedTransitioning>

@end

NS_ASSUME_NONNULL_END
