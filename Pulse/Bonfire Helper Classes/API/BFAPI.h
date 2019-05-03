//
//  BFAPI.h
//  Pulse
//
//  Created by Austin Valleskey on 4/13/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Post.h"
#import "Room.h"
#import "User.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFAPI : NSObject

#pragma mark - User
+ (void)getUser:(void (^)(BOOL success))handler;
+ (void)followUser:(User *_Nonnull)user completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)unfollowUser:(User *_Nonnull)user completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)reportUser:(User *_Nonnull)user completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)blockUser:(User *_Nonnull)user completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)unblockUser:(User *_Nonnull)user completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)subscribeToUser:(User *_Nonnull)user completion:(void (^_Nullable)(BOOL success, User *_Nullable user))handler;
+ (void)unsubscribeFromUser:(User *_Nonnull)user completion:(void (^_Nullable)(BOOL success, User *_Nullable user))handler;

#pragma mark - Room
+ (void)followRoom:(Room *_Nonnull)room completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)unfollowRoom:(Room *_Nonnull)room completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;

#pragma mark - Post
+ (void)createPost:(NSDictionary *)params postingIn:(Room * _Nullable)postingIn replyingTo:(Post * _Nullable)replyingTo;
+ (void)deletePost:(Post *_Nonnull)post completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)reportPost:(NSInteger)postId completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)sparkPost:(Post *_Nonnull)post completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;
+ (void)unsparkPost:(Post *_Nonnull)post completion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler;

#pragma mark - Misc
+ (void)uploadImage:(BFMediaObject *)mediaObject copmletion:(void (^)(BOOL success, NSString *uploadedImageURL))handler;
+ (void)uploadImages:(BFMedia *)media copmletion:(void (^)(BOOL success, NSArray *uploadedImages))handler;

@end

NS_ASSUME_NONNULL_END
