//
//  Session.m
//  Hallway App
//
//  Created by Austin Valleskey on 6/16/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "Session.h"

#import "AppDelegate.h"
#import <Lockbox/Lockbox.h>
#import "NSDictionary+Clean.h"
#import "HAWebService.h"
#import "Room.h"

#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@implementation Session

static Session *session;

+ (Session *)sharedInstance {
    if (!session) {
        session = [[Session alloc] init];
        
        // init AFNetworking session manager
        [session initManager];
        [session initDefaults];
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"user_device_token"]) {
            // "user_device_token"  = the device token that is currently associated with a user
            // "device_token"       = the latest device token received/generated by the device
            session.deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"user_device_token"];
        }
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"user"]) {
            session.currentUser = [[User alloc] initWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"user"] error:nil];
            NSLog(@"session user: %@", session.currentUser);
        }
        
        if ([session getAccessTokenWithVerification:true] != nil) {
            NSLog(@"has access token");
            [session fetchUser];
            //[session syncDeviceToken];
        }
        else {
            [session signOut];
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate launchOnboarding];
        }
        
        [session resetTemporaryDefaults];
    }
    return session;
}

- (void)initManager {
    session.manager = [HAWebService manager];
    
    [[NSNotificationCenter defaultCenter] addObserver:session selector:@selector(HTTPOperationDidFinish:) name:AFNetworkingTaskDidCompleteNotification object:nil];
}
- (void)initDefaults {
    if([[NSUserDefaults standardUserDefaults] dictionaryForKey:@"app_defaults"] == nil) {
        NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"LocalDefaults" ofType:@"json"];
        NSData *data = [NSData dataWithContentsOfFile:bundlePath];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        
        [self updateDefaultsJSON:json];
    }

    NSError* error;
    NSDictionary* dictionaryJSON = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"app_defaults"];
    
    session.defaults = [[Defaults alloc] initWithDictionary:dictionaryJSON error:&error];
    if (error) {
        NSLog(@"session defaults error: %@", error);
    }
    
    // get new defaults!!
    NSString *url = [NSString stringWithFormat:@"%@/%@/clients/defaults.json", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    [session.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [session.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSError *error;
        Defaults *newDefaults = [[Defaults alloc] initWithDictionary:responseObject error:&error];

        if (!error) {
            session.defaults = newDefaults;
            
            // save to local file
            [self updateDefaultsJSON:responseObject];
        }
        else {
            NSLog(@"error with new json: %@", error);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"😞 darn. error getting the new defaults");
        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"errorResponse: %@", ErrorResponse);
    }];
}
- (void)updateDefaultsJSON:(NSDictionary *)json {
    [[NSUserDefaults standardUserDefaults] setObject:[json clean] forKey:@"app_defaults"];
}

// app-wide error code handling
- (void)HTTPOperationDidFinish:(NSNotification *)notification {
    NSError *error = [notification.userInfo objectForKey:AFNetworkingTaskDidCompleteErrorKey];
    NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
    NSInteger statusCode = httpResponse.statusCode;
    
    if (statusCode != 0) {        
        NSLog(@"status code:: %ld", (long)statusCode);
        
        if (statusCode == BAD_AUTHENTICATION) {
            NSLog(@"40: BAD AUTHENTICATION");
            // try getting new auth token
            [session getNewAcessToken:^(BOOL success, NSString *newToken) {
                if (success) {
                    NSLog(@"successfully got new access token: %@", newToken);
                }
                else {
                    NSLog(@"bad token");
                    [session signOut];
                    
                    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                    [appDelegate launchOnboarding];
                }
            }];
        }
        else if (statusCode == BAD_REFRESH_TOKEN || statusCode == BAD_REFRESH_LOGIN_REQ) {
            [session signOut];
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate launchOnboarding];
        }
    }
}

- (UIColor *)themeColor {
    return [[session.currentUser.attributes.details.color lowercaseString] isEqualToString:@"ffffff"] ? [UIColor colorWithWhite:0.2f alpha:1] : [self colorFromHexString:session.currentUser.attributes.details.color.length > 0 ? session.currentUser.attributes.details.color : @"0076ff"];
}
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    if (hexString != nil && hexString.length == 6) {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner setScanLocation:0]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];
        return [UIColor colorWithDisplayP3Red:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    }
    else {
        return [UIColor colorWithWhite:0.2f alpha:1];
    }
}

- (void)syncDeviceToken {
    // "user_device_token"  = the device token that is currently associated with a user
    // "device_token"       = the latest device token received/generated by the device
    if (session.currentUser && [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"] && ![[[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"] isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"user_device_token"]]) {
        // has device token and it isn't equal the user_device_token
        NSLog(@"🚨 user has a new device token -> we need to register it");
                
        NSString *url = [NSString stringWithFormat:@"%@/%@/users/me/notifications/token", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
        
        [session authenticate:^(BOOL success, NSString *token) {
            [session.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            [session.manager POST:url parameters:@{@"system": @"apns", @"token": [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"]} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSLog(@"🤪 successfully updated the device token for @%@", session.currentUser.attributes.details.identifier);
                [[NSUserDefaults standardUserDefaults] setObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"] forKey:@"user_device_token"];
                
                session.deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"😞 darn. error updating the device token");
                // NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            }];
        }];
    }
    else {
        NSLog(@"sync device token didn't qualify");
    }
}

// User
- (void)updateUser:(User *)newUser {
    [[NSUserDefaults standardUserDefaults] setObject:[newUser toJSONData] forKey:@"user"];
    
    session.currentUser = newUser;
}
- (void)fetchUser {
    if ([session getAccessTokenWithVerification:true] != nil) {
        NSString *url = [NSString stringWithFormat:@"%@/%@/users/me", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
        
        [session authenticate:^(BOOL success, NSString *token) {
            if (success) {
                [session.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                
                [session.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSLog(@"responseObject: %@", responseObject[@"data"][@"attributes"][@"details"]);
                    
                    NSError *error;
                    
                    UserDetails *userDetails = [[UserDetails alloc] initWithDictionary:responseObject[@"data"][@"attributes"][@"details"] error:&error];
                    if (error) { NSLog(@"user details error -> : %@", error); }
                    
                    User *user = [[User alloc] initWithDictionary:responseObject[@"data"] error:&error];
                    if (error) { NSLog(@"GET -> /users/me; User error: %@", error); }
                    
                    [session updateUser:user];
                    NSLog(@"🙎‍♂️ User: @%@", user.attributes.details.identifier);
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"UserUpdated" object:nil];
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"❌ Failed to get User ID");
                    NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    NSLog(@"%@", ErrorResponse);
                }];
            }
        }];
    }
}

// Auth Tokens
- (void)setAccessToken:(NSDictionary *)accessToken {
    NSMutableDictionary *authTokenWithAppVersion = [[NSMutableDictionary alloc] initWithDictionary:accessToken];
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [authTokenWithAppVersion setValue:version forKey:@"app_version"];
    
    [Lockbox archiveObject:authTokenWithAppVersion forKey:@"access_token"];
}
- (NSString *)refreshToken {
    NSDictionary *accessToken = [Lockbox unarchiveObjectForKey:@"access_token"];
    if (accessToken == nil) { return nil; }
    
    if (accessToken[@"attributes"] && accessToken[@"attributes"][@"refresh_token"] && [accessToken[@"attributes"][@"refresh_token"] isKindOfClass:[NSString class]]) {
        return accessToken[@"attributes"][@"refresh_token"];
    }
    
    return nil;
}
- (NSDictionary *)getAccessTokenWithVerification:(BOOL)verify {
    NSDictionary *accessToken =  [Lockbox unarchiveObjectForKey:@"access_token"];
    return verify ? [self verifyToken:accessToken] : accessToken;
}

- (void)signOut {
    // send DELETE request to API
    
    if ([[Session sharedInstance] getAccessTokenWithVerification:true] != nil) {
        NSString *url = [NSString stringWithFormat:@"%@/%@/oauth/access_token", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
        
        [session authenticate:^(BOOL success, NSString *token) {
            if (success) {
                [session.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
                [session.manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

                [session.manager DELETE:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    NSLog(@"✌️ Logged out of User");
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    NSLog(@"❌ Failed to log out of User");
                    NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    NSLog(@"%@", ErrorResponse);
                }];
            }
        }];
        
        // keep the config
        NSString *environment = [[NSUserDefaults standardUserDefaults] stringForKey:@"environment"];
        NSDictionary *config = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"config"];
        NSInteger launches = [[NSUserDefaults standardUserDefaults] integerForKey:@"launches"];
        
        // keep device token
        NSString *deviceToken = session.deviceToken;
        
        // clear session
        session = nil;
        
        // ❌🗑❌ clear local app data ❌🗑❌
        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
        
        // set the config again
        [[NSUserDefaults standardUserDefaults] setObject:environment forKey:@"environment"];
        [[NSUserDefaults standardUserDefaults] setObject:config forKey:@"config"];
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"kFirstLaunch"];
        [[NSUserDefaults standardUserDefaults] setInteger:launches forKey:@"launches"];
        
        // set the device token again
        [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:@"device_token"];
        
        // clear Lockbox
        [Lockbox archiveObject:nil forKey:@"access_token"];
    }
}

- (void)authenticate:(void (^)(BOOL success, NSString *token))handler {
    NSDictionary *accessToken = [session getAccessTokenWithVerification:false];
    NSDictionary *verifiedAccessToken = [session getAccessTokenWithVerification:true];

    // NSLog(@"attempt authenticate");
    // NSLog(@"accessToken: %@", (accessToken == nil ? @"FALSE" : @"TRUE"));
    
    // load cache of user
    if (verifiedAccessToken != nil) {
        handler(TRUE, accessToken[@"attributes"][@"access_token"]);
    }
    else if (accessToken[@"attributes"] && accessToken[@"attributes"][@"refresh_token"] && [accessToken[@"attributes"][@"refresh_token"] isKindOfClass:[NSString class]]) {
        NSLog(@"refresh token exists");
        // refresh token exists -> use it to get a new access token
        [session getNewAcessToken:^(BOOL success, NSString *newToken) {
            if (success) {
                handler(true, newToken);
            }
            else {
                NSLog(@"bad token");
                [session signOut];
                
                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate launchOnboarding];
            }
        }];
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
    
    NSDate *tokenExpiration = [formatter dateFromString:token[@"attributes"][@"expires_at"]];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if ([now compare:tokenExpiration] == NSOrderedDescending || ![token[@"app_version"] isEqualToString:version]) {
        // loginExpiration in the future
        token = nil;
        
        NSLog(@"token is expired");
    }
    
    return token;
}

- (void)getNewAcessToken:(void (^)(BOOL success, NSString *newToken))handler {
    NSLog(@"->> getNewAcessToken");
    
    // GET NEW ACCESS TOKEN
    if ([Session sharedInstance].refreshToken != nil) {
        NSString *url = [NSString stringWithFormat:@"%@/%@/oauth", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
        NSDictionary *params = @{@"grant_type": @"refresh_token", @"refresh_token": [Session sharedInstance].refreshToken};
        
        // set defaults
        [session.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", envConfig[@"API_KEY"]] forHTTPHeaderField:@"Authorization"];
        [session.manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        
        [session.manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable accessTokenResponse) {
            NSLog(@"--------");
            NSLog(@"success: getNewAccessToken");
            NSLog(@"--------");
            
            // save new auth token
            NSDictionary *cleanDictionary = [accessTokenResponse[@"data"] clean];
            
            [[Session sharedInstance] setAccessToken:cleanDictionary];
            
            handler(true, cleanDictionary[@"attributes"][@"access_token"]);
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
            NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
            NSLog(@"%@",ErrorResponse);
            
            // check if another access token was already retrieved in the mean time
            // -> this happens when you have multiple requests attempting to use an expired token and consequently, multiple requests are made to renew the access token. the subsequent requests will fail with an error code 48, due to sending an invalid token (since it has already been used for a refresh)
            NSDictionary *accessToken = [[Session sharedInstance] getAccessTokenWithVerification:true];
            if (accessToken != nil) {
                NSLog(@"already refreshed! good to go.");
                handler(true, accessToken[@"attributes"][@"access_token"]);
            }
            else {
                NSLog(@"access token  ==  nil");
                
                handler(false, nil);
            }
        }];
    }
    else {
        NSLog(@"refresh token  ==  nil");
        handler(false, nil);
    }
}

// Magic Login
// Store successful logins in the keychain
- (void)setSuccessfulEmail:(NSString *)email {
    NSMutableDictionary *successfulEmails = [[NSMutableDictionary alloc] initWithDictionary:[self getSuccessfulEmails]];
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
}
- (int)getTempId {
    int tempId = 1;
    NSMutableDictionary *temporaryDefaults = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"temporary_defaults"]];
    if (temporaryDefaults[@"postsCreated"] != [NSNull null] && temporaryDefaults[@"postsCreated"] != nil) {
        tempId = [temporaryDefaults[@"postsCreated"] intValue] + 1;
    }
    [temporaryDefaults setObject:[NSNumber numberWithInt:tempId] forKey:@"postsCreated"];
    [[NSUserDefaults standardUserDefaults] setObject:temporaryDefaults forKey:@"temporary_defaults"];
    
    return tempId;
}

// Actions
// -- Post --
- (void)deletePost:(NSInteger)postId completion:(void (^)(BOOL success, id responseObject))handler {
    handler(true, @{});
}
- (void)reportPost:(NSInteger)postId completion:(void (^)(BOOL success, id responseObject))handler {
    handler(true, @{});
}
- (void)sparkPost:(Post *)post completion:(void (^)(BOOL success, id responseObject))handler {
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/posts/%ld/votes", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], post.attributes.status.postedIn.identifier, (long)post.identifier];
    NSDictionary *params = @{};
    
    NSLog(@"url:: %@", url);
    
    [session.manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [session.manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: upvote");
        NSLog(@"--------");
        
        handler(true, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
    
    // update the UI
    NSDateFormatter *gmtDateFormatter = [[NSDateFormatter alloc] init];
    gmtDateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    gmtDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *dateString = [gmtDateFormatter stringFromDate:[NSDate new]];
    
    PostContextVote *voteDict = [[PostContextVote alloc] initWithDictionary:@{@"created_at": dateString} error:nil];
    post.attributes.context.vote = voteDict;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"postUpdated" object:post];
}
- (void)unsparkPost:(Post *)post completion:(void (^)(BOOL success, id responseObject))handler {
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/posts/%ld/votes", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], post.attributes.status.postedIn.identifier, (long)post.identifier];
    NSDictionary *params = @{};
    
    NSLog(@"url:: %@", url);
    
    [session.manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [session.manager DELETE:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: downvote");
        NSLog(@"--------");
        
        handler(true, responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
    
    // update the UI
    NSMutableDictionary *contextDict = [[NSMutableDictionary alloc] initWithDictionary:[post.attributes.context toDictionary]];
    [contextDict removeObjectForKey:@"vote"];
    PostContext *newContext = [[PostContext alloc] initWithDictionary:contextDict error:nil];
    post.attributes.context = newContext;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"postUpdated" object:post];
}


// -- Follow/Unfollow User --
- (void)followUser:(NSString *)userId completion:(void (^)(BOOL success, id responseObject))handler {
    handler(true, @{});
}
- (void)unfollowUser:(NSString *)userid completion:(void (^)(BOOL success, id responseObject))handler {
    handler(true, @{});
}


// -- Follow/Unfollow Room --
- (void)followRoom:(NSString *)roomId completion:(void (^)(BOOL success, id responseObject))handler {
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/members", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], roomId];
    NSDictionary *params = @{};
    
    [session.manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [session.manager POST:url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: followRoom");
        NSLog(@"--------");
        
        // refresh my rooms
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
        
        NSError *error;
        RoomContext *roomContextResponse = [[RoomContext alloc] initWithDictionary:responseObject[@"data"] error:&error];
        
        if (!error) { NSLog(@"room context reponse:"); NSLog(@"%@", roomContextResponse); };
        
        handler(true, roomContextResponse);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
}
- (void)unfollowRoom:(NSString *)roomId completion:(void (^)(BOOL success, id responseObject))handler {
    NSString *url = [NSString stringWithFormat:@"%@/%@/rooms/%@/members", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], roomId];
    NSDictionary *params = @{};
    
    [session.manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [session.manager DELETE:url parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"--------");
        NSLog(@"success: followRoom");
        NSLog(@"--------");
        
        // refresh my rooms
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refreshMyRooms" object:nil];
        
        NSError *error;
        RoomContext *roomContextResponse = [[RoomContext alloc] initWithDictionary:responseObject[@"data"] error:&error];
        
        if (!error) { NSLog(@"room context reponse:"); NSLog(@"%@", roomContextResponse); };
        
        handler(true, roomContextResponse);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"error: %@", error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey]);
        NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
        NSLog(@"%@",ErrorResponse);
        
        handler(false, @{@"error": ErrorResponse});
    }];
}

@end
