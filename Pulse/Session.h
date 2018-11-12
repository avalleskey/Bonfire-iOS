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
- (void)fetchUser;
- (UIColor *)themeColor;

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
- (void)deletePost:(NSInteger)postId completion:(void (^)(BOOL success, id responseObject))handler;
- (void)reportPost:(NSInteger)postId completion:(void (^)(BOOL success, id responseObject))handler;
- (void)sparkPost:(Post *)post completion:(void (^)(BOOL success, id responseObject))handler;
- (void)unsparkPost:(Post *)post completion:(void (^)(BOOL success, id responseObject))handler;


// -- Follow/Unfollow User --
- (void)followUser:(NSString *)userId completion:(void (^)(BOOL success, id responseObject))handler;
- (void)unfollowUser:(NSString *)postId completion:(void (^)(BOOL success, id responseObject))handler;


// -- Follow/Unfollow Room --
- (void)followRoom:(NSString *)roomId completion:(void (^)(BOOL success, id responseObject))handler;
- (void)unfollowRoom:(NSString *)roomId completion:(void (^)(BOOL success, id responseObject))handler;


// Temporary Defaults
- (void)resetTemporaryDefaults;
- (int)getTempId;

@end
