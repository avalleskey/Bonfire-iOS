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
#import "BFAPI.h"
#import <PINCache/PINCache.h>

NS_ASSUME_NONNULL_BEGIN

@interface Session : NSObject

+ (Session *)sharedInstance;

@property (nonatomic, strong) HAWebService *manager;

#pragma mark - Defaults
@property (nonatomic, strong) Defaults *defaults;
- (void)initDefaultsWithCompletion:(void (^_Nullable)(BOOL success))handler;


#pragma mark - User
@property (readwrite,copy) User *currentUser;
- (void)updateUser:(User *)newUser;
- (void)signOut;

#pragma mark - Local Storage Management
- (void)addToRecents:(id)object;

#pragma mark - Auth
- (void)setAccessToken:(NSDictionary *)accessToken;
- (NSDictionary *)getAccessTokenWithVerification:(BOOL)verify;
- (NSString *)refreshToken;
+ (void)authenticate:(void (^)(BOOL success, NSString *token))handler;
- (void)getNewAccessToken:(void (^)(BOOL success, NSString *newToken))handler;

#pragma mark - APNS
@property (readwrite,copy) NSString *deviceToken;
- (void)syncDeviceToken;

// Temporary Defaults
- (void)resetTemporaryDefaults;
+ (int)getTempId;

// Caches
+ (PINCache *)tempCache;

@end

NS_ASSUME_NONNULL_END
