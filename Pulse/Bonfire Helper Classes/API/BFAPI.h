//
//  BFAPI.h
//  Pulse
//
//  Created by Austin Valleskey on 4/13/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Post.h"
#import "User.h"
#import "Bot.h"
#import "Camp.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFAPI : NSObject

#pragma mark - Identity
+ (void)blockIdentity:(Identity *_Nonnull)identity completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)unblockIdentity:(Identity *_Nonnull)identity completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;

#pragma mark - User
+ (void)getUser:(void (^ _Nullable)(BOOL success))handler;
+ (void)followUser:(User *_Nonnull)user completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)unfollowUser:(User *_Nonnull)user completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;

#pragma mark - Camp
+ (void)followCamp:(Camp *_Nonnull)camp completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)unfollowCamp:(Camp *_Nonnull)camp completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;

#pragma mark - Post
+ (void)createPost:(NSDictionary *)params postingIn:(Camp * _Nullable)postingIn replyingTo:(Post * _Nullable)replyingTo attachments:(PostAttachments * _Nullable)attachments;
+ (void)deletePost:(Post *_Nonnull)post completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)votePost:(Post *_Nonnull)post completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)unvotePost:(Post *_Nonnull)post completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;

#pragma mark - Misc
+ (void)uploadImage:(BFMediaObject *)mediaObject copmletion:(void (^)(BOOL success, NSString *uploadedImageURL))handler;
+ (void)uploadImages:(BFMedia *)media copmletion:(void (^)(BOOL success, NSArray *uploadedImages))handler;

@end

NS_ASSUME_NONNULL_END
