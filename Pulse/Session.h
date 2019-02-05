//
//  Session.h
//  Hallway App
//
//  Created by Austin Valleskey on 6/16/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HAWebService.h"
#import "ErrorCodes.h"
#import "Defaults.h"
#import "User.h"
#import "Post.h"

@interface Session : NSObject

+ (Session *)sharedInstance;

@property (nonatomic, strong) HAWebService *manager;
@property (nonatomic, strong) Defaults *defaults;


// -- User --
@property (readwrite,copy) User *currentUser;
- (void)updateUser:(User *)newUser;
- (void)fetchUser:(void (^)(BOOL success))handler;

- (UIColor *)themeColor;
- (void)addToRecents:(id)object;

// Auth Tokens
- (void)setAccessToken:(NSDictionary *)accessToken;
- (NSDictionary *)getAccessTokenWithVerification:(BOOL)verify;
- (NSString *)refreshToken;
- (void)authenticate:(void (^)(BOOL success, NSString *token))handler;
- (void)getNewAcessToken:(void (^)(BOOL success, NSString *newToken))handler;

// Push Tokens
@property (readwrite,copy) NSString *deviceToken;
- (void)syncDeviceToken;

- (void)signOut;


// -- Post --
- (void)createPost:(NSDictionary *)params postingIn:(Room *)postingIn replyingTo:(Post * _Nullable)replyingTo;
- (void)deletePost:(Post *)post completion:(void (^)(BOOL success, id responseObject))handler;
- (void)reportPost:(NSInteger)postId completion:(void (^)(BOOL success, id responseObject))handler;
- (void)sparkPost:(Post *)post completion:(void (^)(BOOL success, id responseObject))handler;
- (void)unsparkPost:(Post *)post completion:(void (^)(BOOL success, id responseObject))handler;


// -- User --
- (void)followUser:(User *)user completion:(void (^)(BOOL success, id responseObject))handler;
- (void)unfollowUser:(User *)user completion:(void (^)(BOOL success, id responseObject))handler;
- (void)blockUser:(User *)user completion:(void (^)(BOOL success, id responseObject))handler;
- (void)reportUser:(User *)user completion:(void (^)(BOOL success, id responseObject))handler;
- (void)unblockUser:(User *)user completion:(void (^)(BOOL success, id responseObject))handler;

// -- Follow/Unfollow Room --
- (void)followRoom:(NSString *)roomId completion:(void (^)(BOOL success, id responseObject))handler;
- (void)unfollowRoom:(NSString *)roomId completion:(void (^)(BOOL success, id responseObject))handler;


// Temporary Defaults
- (void)resetTemporaryDefaults;
- (int)getTempId;

@end
