//
//  Session.m
//  Bonfire
//
//  Created by Austin Valleskey on 6/16/18.
//  Copyright © 2018 Ingenious, Inc. All rights reserved.
//

#import "Session.h"

#import "Launcher.h"
#import "AppDelegate.h"
#import <Lockbox/Lockbox.h>
#import "NSDictionary+Clean.h"
#import "HAWebService.h"
#import "Camp.h"
#import "UIColor+Palette.h"
#import "NSDictionary+Clean.h"
#import "NSArray+Clean.h"
#import <PINCache/PINCache.h>
#import "InsightsLogger.h"
#import "BFNotificationManager.h"

@interface Session ()

@property (nonatomic) BOOL refreshingToken;


@end

@implementation Session

static Session *session;

+ (Session *)sharedInstance {
    if (!session) {
        session = [[Session alloc] init];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"device_token"]) {
            // "user_device_token"  = the device token that is currently associated with a user
            // "device_token"       = the latest device token received/generated by the device
            session.deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"];
        }
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"user"]) {
            session.currentUser = [[User alloc] initWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"user"] error:nil];
            NSLog(@"🙎‍♂️ User: @%@", session.currentUser.attributes.identifier);
        }
        
        if ([session getAccessTokenWithVerification:true] != nil && session.currentUser.identifier != nil) {
            // update user object
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [BFAPI getUser:nil];
                
                #ifdef DEBUG
                #else
                [session syncDeviceToken];
                #endif
            });
        }
        
        [session initDefaultsWithCompletion:nil];
        [session resetTemporaryDefaults];
    }
    return session;
}

- (void)initDefaultsWithCompletion:(void (^_Nullable)(BOOL success))handler {
    if ([[NSUserDefaults standardUserDefaults] dictionaryForKey:@"app_defaults"] == nil) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"LocalDefaults" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:bundlePath];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        [session updateDefaultsJSON:json];
    }

    NSError* error;
    NSDictionary* dictionaryJSON = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"app_defaults"];
    
    if ([dictionaryJSON isKindOfClass:[NSDictionary class]]) {
        session.defaults = [[Defaults alloc] initWithDictionary:dictionaryJSON error:&error];
    }
    
    if (error || !session.defaults) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"app_defaults"];
        session.defaults = [[Defaults alloc] init];
        NSLog(@"⚠️ session defaults error: %@", error);
    }
    
    // only fetch new defaults if logged in
    if ([session getAccessTokenWithVerification:true] != nil && session.currentUser.identifier != nil) {
        // get new defaults!!
        NSString *url = @"clients/defaults.json";
        [[HAWebService authenticatedManager] GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSError *error;
            
            Defaults *newDefaults = [[Defaults alloc] initWithDictionary:responseObject error:&error];
            
            if (!error) {                
                if (session.defaults.announcement) {
                    TabController *tabVC = [Launcher tabController];
                    if (tabVC) {
                        NSString *badgeValue = @" ";
                        [tabVC setBadgeValue:badgeValue forItem:tabVC.notificationsNavVC.tabBarItem];
                        if (badgeValue && badgeValue.length > 0 && [badgeValue intValue] > 0) {
                            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                        }
                    }
                }
                
                session.defaults = newDefaults;
                                
                // save to local file
                [session updateDefaultsJSON:responseObject];
            }
            else {
                NSLog(@"⚠️ error with new json: %@", error);
            }
            
            if (handler) {
                handler(true);
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"😞 darn. error getting the new defaults");
            if (handler) {
                handler(true);
            }
        }];
    }
    else {
        if (handler) {
            handler(false);
        }
    }
}
- (void)updateDefaultsJSON:(NSDictionary *)json {
    [[NSUserDefaults standardUserDefaults] setObject:[json clean] forKey:@"app_defaults"];
}

- (void)syncDeviceToken {
    // "user_device_token"  = the device token that is currently associated with a user
    // "device_token"       = the latest device token received/generated by the device
    if (session.currentUser && [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"] && ![[[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"] isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"user_device_token"]]) {
        // has device token and it isn't equal the user_device_token
        NSLog(@"🚨 user has a new device token -> we need to register it");
                
        NSString *url = @"users/me/notifications/tokens";
        
        NSLog(@"parameters: %@", @{@"vendor": @"APNS", @"token": [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"]});
        [[HAWebService authenticatedManager] POST:url parameters:@{@"vendor": @"APNS", @"token": [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            NSLog(@"🤪 successfully updated the device token for @%@", session.currentUser.attributes.identifier);
            [[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"] forKey:@"user_device_token"];
            
            session.deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"😞 darn. error updating the device token");
        }];
    }
    else {
        // NSLog(@"No need to update device token");
    }
}

// User
- (void)updateUser:(User *)newUser {
    // add cover photo
    [[NSUserDefaults standardUserDefaults] setObject:[newUser toJSONData] forKey:@"user"];
    
    session.currentUser = newUser;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UserUpdated" object:newUser];
}

- (void)addToRecents:(id)object {
    if ([object isKindOfClass:[Camp class]] ||
        [object isKindOfClass:[User class]]) {
        NSMutableArray *searchRecents = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"recents_search"]];
        if ([object isKindOfClass:[Camp class]]) {
            NSMutableArray *campsRecents = [[NSMutableArray alloc] initWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:@"recents_camps"]];
            NSMutableArray *campsToRemove = [NSMutableArray new];
            for (id camp in campsRecents) {
                if ([camp isKindOfClass:[Camp class]]) {
                    if ([((Camp *)camp).identifier isEqualToString:((Camp *)object).identifier]) {
                        [campsToRemove addObject:camp];
                    }
                }
                else if ([Camp isKindOfClass:[NSDictionary class]]) {
                    if ([((NSDictionary *)camp) objectForKey:@"id"] && [((NSDictionary *)camp)[@"id"] isEqualToString:((Camp *)object).identifier]) {
                        [campsToRemove addObject:camp];
                    }
                }
            }
            [campsRecents removeObjectsInArray:campsToRemove];
            [campsRecents insertObject:[object toDictionary] atIndex:0];
            
            if (campsRecents.count > 8) {
                [campsRecents removeObjectsInRange:NSMakeRange(8, campsRecents.count - 8)];
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:campsRecents forKey:@"recents_camps"];
        }
        
        NSDictionary *objJSON = [object toDictionary];
        
        if ([object isKindOfClass:[Camp class]]) {
            [self incrementOpensForCamp:(Camp *)object];
            [self updateLastOpenedForCamp:(Camp *)object];
        }
        
        // add object or push to front if in recents
        BOOL existingMatch = false;
        for (NSInteger i = 0; i < [searchRecents count]; i++) {
            NSDictionary *result = searchRecents[i];
            if (objJSON[@"type"] && objJSON[@"id"] &&
                result[@"type"] && result[@"id"]) {
                if ([objJSON[@"type"] isEqualToString:result[@"type"]] && [[self convertToString:objJSON[@"id"]] isEqualToString:[self convertToString:result[@"id"]]]) {
                    existingMatch = true;
                    
                    [searchRecents removeObjectAtIndex:i];
                    [searchRecents insertObject:objJSON atIndex:0];
                    break;
                }
            }
        }
        if (!existingMatch) {
            // remove context first
            if ([object isKindOfClass:[Camp class]]) {
                Camp *camp = (Camp *)object;
                
                [searchRecents insertObject:[camp toDictionary] atIndex:0];
            }
            else if ([object isKindOfClass:[User class]]) {
                User *user = (User *)object;
                //user.attributes.context = nil;
                
                [searchRecents insertObject:[user toDictionary] atIndex:0];
            }
            
            NSMutableArray *removeObjects = [[NSMutableArray alloc] init];
            NSInteger numOfCamps = 0;
            NSInteger numOfUsers = 0;
            for (NSDictionary *object in searchRecents) {
                if ([object isKindOfClass:[NSDictionary class]] && [object[@"type"] isKindOfClass:[NSString class]]) {
                    if ([object[@"type"] isEqualToString:@"camp"]) {
                        numOfCamps = numOfCamps + 1;
                        if (numOfCamps > 16) {
                            [removeObjects addObject:object];
                        }
                    }
                    if ([object[@"type"] isEqualToString:@"user"]) {
                        numOfUsers = numOfUsers + 1;
                        if (numOfUsers > 16) {
                            [removeObjects addObject:object];
                        }
                    }
                }
            }
            [searchRecents removeObjectsInArray:removeObjects];
        }
        
        // update NSUserDefaults
        [[NSUserDefaults standardUserDefaults] setObject:[searchRecents clean] forKey:@"recents_search"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RecentsUpdated" object:nil];
    }
}
- (void)incrementOpensForCamp:(Camp *)camp {
    NSMutableDictionary *opens = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"camp_opens"]];
    
    // set
    NSInteger opensForCamp = [opens objectForKey:camp.identifier] ? [opens[camp.identifier] integerValue] : 0;
    opensForCamp = opensForCamp + 1;
    [opens setObject:[NSNumber numberWithInteger:opensForCamp] forKey:camp.identifier];
    
    // save
    [[NSUserDefaults standardUserDefaults] setObject:opens forKey:@"camp_opens"];
}
- (void)updateLastOpenedForCamp:(Camp *)camp {
    if (!camp || camp.identifier.length == 0) return;
    
    NSString *cache_key = @"camp_last_opens";
    NSMutableDictionary *lastOpenedDictionary = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:cache_key]];
    [lastOpenedDictionary setObject:[NSDate new] forKey:camp.identifier];
    [[NSUserDefaults standardUserDefaults] setObject:lastOpenedDictionary forKey:cache_key];
}
- (NSString *)convertToString:(id)object {
    return [NSString stringWithFormat:@"%@", object];
}

// Auth Tokens
- (void)setAccessToken:(NSDictionary *)accessToken {
    NSMutableDictionary *authTokenWithAppVersion = [[NSMutableDictionary alloc] initWithDictionary:accessToken];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [authTokenWithAppVersion setValue:version forKey:@"app_version"];
    
    NSLog(@"🆕🔑 New access token : %@ (called via setAccessToken in Session.m)", accessToken);
    
    [Lockbox archiveObject:authTokenWithAppVersion forKey:@"access_token"];
}
- (NSString *)refreshToken {
    NSDictionary *accessToken = [Lockbox unarchiveObjectForKey:@"access_token"];
    if (accessToken == nil) { return nil; }
        
    if (accessToken[@"refresh_token"] &&
        [accessToken[@"refresh_token"] isKindOfClass:[NSString class]]) {
        return accessToken[@"refresh_token"];
    }
    
    return nil;
}
- (NSDictionary *)getAccessTokenWithVerification:(BOOL)verify {
    NSDictionary *accessToken =  [Lockbox unarchiveObjectForKey:@"access_token"];
    return verify ? [session verifyToken:accessToken] : accessToken;
}

- (void)signOut {
    // cancel all existing requests
    HAWebService *manager = [HAWebService manager]; //manager should be instance which you are using across application
    [manager.session invalidateAndCancel];
    [HAWebService reset];
    
    // keep the config
    NSInteger launches = [[NSUserDefaults standardUserDefaults] integerForKey:@"launches"];
    BOOL hasSeenAppStoreReviewController = [[NSUserDefaults standardUserDefaults] boolForKey:@"hasSeenAppStoreReviewController"];
    
    // keep device token
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"];
    
    // send DELETE request to API
    NSDictionary *accessToken = [[Session sharedInstance] getAccessTokenWithVerification:true];
    if (accessToken != nil) {
        NSLog(@"⚡️⚡️⚡️⚡️⚡️⚡️  SIGN OUT  ⚡️⚡️⚡️⚡️⚡️⚡️⚡️");
        
        [[InsightsLogger sharedInstance] uploadAllInsights];
        
        NSString *url = [NSString stringWithFormat:@"%@/%@/oauth/access_token", [Configuration API_BASE_URI], [Configuration API_CURRENT_VERSION]];
        
        NSLog(@"let's authenticate........");
        [Session authenticate:^(BOOL success, NSString *token) {
            if (success) {
                HAWebService *logoutManager = [[HAWebService alloc] init];
                                 
                [logoutManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                logoutManager.requestSerializer.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", nil];
                
                if (token) {
                    NSLog(@"logoutManager headers: %@", [logoutManager.requestSerializer HTTPRequestHeaders]);
                    NSLog(@"headers: %@", @{@"access_token": token});
                    
                    [logoutManager DELETE:url parameters:@{@"access_token": token} success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                        NSLog(@"✌️ Logged out of User");
                        
                        [Launcher openOnboarding];
                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                        NSLog(@"❌ Failed to log out of User");
                        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                        NSLog(@"log out error: %@", ErrorResponse);
                        
                        NSLog(@"task: %@", task);
                        NSLog(@"logoutManager? %@", logoutManager);
                        
                        [Launcher openOnboarding];
                    }];
                }
                else {
                    [Launcher openOnboarding];
                }
            }
        }];
    }
    
    // clear session
    session = nil;
    
    // reset the [HAWebService authenticatedManager]
    [[HAWebService manager].session invalidateAndCancel];
    [HAWebService reset];
    
    // clear feed cache
    [[PINCache sharedCache] removeAllObjects];
    [[Session tempCache] removeAllObjects];
    
    // ❌🗑❌ clear local app data ❌🗑❌
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    // set the config again
    [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"kHasLaunchedBefore"];
    [[NSUserDefaults standardUserDefaults] setInteger:launches forKey:@"launches"];
    [[NSUserDefaults standardUserDefaults] setBool:hasSeenAppStoreReviewController forKey:@"hasSeenAppStoreReviewController"];
    [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"device_token"];
    
    // clear Lockbox
    [Lockbox archiveObject:nil forKey:@"access_token"];
    
    // clear notifications
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    NSLog(@"..... all done with sign out procedures ......");
}

+ (void)authenticate:(void (^)(BOOL success, NSString *token))handler {
    NSDictionary *accessToken = [session getAccessTokenWithVerification:false];
    
    // load cache of user
    if (accessToken != nil || ([[Session sharedInstance] getAccessTokenWithVerification:YES] && ![HAWebService hasInternet])) {
        handler(TRUE, accessToken[@"access_token"]);
    }
    else {
        handler(false, nil);
    } 
}
- (NSDictionary *)verifyToken:(NSDictionary *)token {
    NSDate *now = [NSDate date];
    
    // compare dates to make sure both are still active
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    NSDate *tokenExpiration = [formatter dateFromString:token[@"expires_at"]];
    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *comps = [gregorian components: NSCalendarUnitMinute
                                           fromDate: now
                                             toDate: (tokenExpiration==nil?now:tokenExpiration)
                                            options: 0];
     NSLog(@"minutes until token expiration:: %ld", (long)[comps minute]);
     NSLog(@"token app version: %@", token[@"app_version"]);
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if ([comps minute] <= 0 || ![token[@"app_version"] isEqualToString:version]) {
        // loginExpiration in the future
        token = nil;
        
        if (![token[@"app_version"] isEqualToString:version]) {
            // NSLog(@"app version has changed (%@ -> %@)", token[@"app_version"], version);
        }
    }
    
    return token;
}

- (void)setRefreshingToken:(BOOL)refreshingToken {
    if (refreshingToken != _refreshingToken) {
        if (_refreshingToken && !refreshingToken) {
            // (refreshing is all done)
            
            // fire all outstanding blocks
            NSLog(@"BOOM token isn't refreshing anymore");
            [[NSNotificationCenter defaultCenter] postNotificationName:@"BFTokenRefreshed" object:nil];
        }
        
        _refreshingToken = refreshingToken;
    }
}

- (void)fireOnRefreshingTokenCompletion:(void (^_Nullable)(void))handler {
    NSLog(@"fire on refreshing token completion!");
    [[NSNotificationCenter defaultCenter] addObserverForName:@"BFTokenRefreshed" object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSLog(@"call that handler!");
        handler();
    }];
}

- (void)getNewAccessToken:(void (^)(BOOL success, NSString *newToken))handler {
    NSLog(@"🆕🔑 getNewAccessToken:");
    
    // GET NEW ACCESS TOKEN
    NSDictionary *currentAccessToken = [[Session sharedInstance] getAccessTokenWithVerification:YES];
    if (currentAccessToken || (![HAWebService hasInternet] && [[Session sharedInstance] getAccessTokenWithVerification:NO])) {
        // access token is already valid -- must have already been refreshed
        NSLog(@"🔑✅ getNewAccessToken: NO NEED");
        
        handler(true, currentAccessToken[@"access_token"]);
    }
    else if ([[Session sharedInstance] refreshToken] != nil) {
        // has a seemingly valid refresh token, so we should attempt
        NSLog(@"🔑⏳ getNewAccessToken: REFRESH TOKEN AVAILABLE");
        
        if ([self refreshingToken]) {
            // NSLog(@"already refreshing....");
            [self fireOnRefreshingTokenCompletion:^(void) {
                // NSLog(@"all requests finished!");
                // NSLog(@"done refreshing and the verdict is.....");
                NSDictionary *accessToken = [[Session sharedInstance] getAccessTokenWithVerification:true];
                if (accessToken == nil) {
                    // original effort failed to get a new access token
                    // NSLog(@"original effort failed");
                    handler(false, nil);
                }
                else {
                    // NSLog(@"original effort SUCCEEDED WOOOOOO");
                    handler(true, accessToken[@"access_token"]);
                }
            }];
        }
        else {
            NSLog(@"🔑🌀 getNewAccessToken: GET NEW TOKEN");
            self.refreshingToken = true;
            
            // get new access token
            HAWebService *refreshTokenManager = [[HAWebService alloc] init];
            [refreshTokenManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Configuration API_KEY]] forHTTPHeaderField:@"Authorization"];
            NSLog(@"refreshtoken [HAWebService authenticatedManager]: %@", refreshTokenManager);
            
            NSDictionary *params = @{@"grant_type": @"refresh_token", @"refresh_token": [[Session sharedInstance] refreshToken]};
            
            // NSLog(@"params: %@", params);
            [refreshTokenManager POST:@"oauth" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable accessTokenResponse) {
                NSLog(@"--------");
                NSLog(@"success: getNewAccessToken");
                NSLog(@"--------");
                
                // save new auth token
                NSDictionary *cleanDictionary = [accessTokenResponse[@"data"] clean];
                
                [[Session sharedInstance] setAccessToken:cleanDictionary];
                
                handler(true, cleanDictionary[@"access_token"]);
                
                self.refreshingToken = false;
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"/oauth error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
                NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                NSLog(@"%@",ErrorResponse);
                
                // check if another access token was already retrieved in the mean time
                // -> this happens when you have multiple requests attempting to use an expired token and consequently, multiple requests are made to renew the access token. the subsequent requests will fail with an error code 48, due to sending an invalid token (since it has already been used for a refresh)
                
                NSDictionary *accessToken = [[Session sharedInstance] getAccessTokenWithVerification:true];
                if (accessToken != nil) {
                    // already refreshed! good to go
                    NSLog(@"access token? %@", accessToken[@"access_token"]);
                    handler(true, accessToken[@"access_token"]);
                }
                else {
                    handler(false, nil);
                }
                
                self.refreshingToken = false;
            }];
        }
    }
    else {
        // NSLog(@"refresh token  ==  nil");
        handler(false, nil);
    }
}

// Magic Login
// Store successful logins in the keychain
- (void)setSuccessfulEmail:(NSString *)email {
    NSMutableDictionary *successfulEmails = [[NSMutableDictionary alloc] initWithDictionary:[session getSuccessfulEmails]];
    [successfulEmails setObject:@true forKey:email];
    [Lockbox archiveObject:successfulEmails forKey:@"successful_emails"];
}
- (NSDictionary *)getSuccessfulEmails {
    if ([[Lockbox unarchiveObjectForKey:@"successful_emails"] isKindOfClass:[NSDictionary class]]) {
        return [Lockbox unarchiveObjectForKey:@"successful_emails"];
    }
    else {
        return @{};
    }
}
- (NSString *)getSuccessfulEmail {
    // TODO
    return @"";
}

- (void)resetTemporaryDefaults {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"temporary_defaults"];
    NSMutableDictionary *temporaryDefaults = [[NSMutableDictionary alloc] init];
    [[NSUserDefaults standardUserDefaults] setObject:temporaryDefaults forKey:@"temporary_defaults"];
    
    // clear temporary pin cache items
//    [[PINCache sharedCache] removeObjectForKey:MY_CAMPS_CAN_POST_KEY];
}
+ (int)getTempId {
    int tempId = 1;
    NSMutableDictionary *temporaryDefaults = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"temporary_defaults"]];
    if (temporaryDefaults[@"postsCreated"] != [NSNull null] && temporaryDefaults[@"postsCreated"] != nil) {
        tempId = [temporaryDefaults[@"postsCreated"] intValue] + 1;
    }
    [temporaryDefaults setObject:[NSNumber numberWithInt:tempId] forKey:@"postsCreated"];
    [[NSUserDefaults standardUserDefaults] setObject:temporaryDefaults forKey:@"temporary_defaults"];
    
    return tempId;
}

/* Caches */

+ (PINCache *)tempCache {
    static PINCache *_sharedCampCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedCampCache = [[PINCache alloc] initWithName:@"BonfireTemporaryCache" rootPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] serializer:nil deserializer:nil keyEncoder:nil keyDecoder:nil ttlCache:true];
    });
    
    return _sharedCampCache;
}

@end
