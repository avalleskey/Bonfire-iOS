//
//  HAWebService.m
//  Hallway App
//
//  Created by Austin Valleskey on 8/21/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "HAWebService.h"
#import "Session.h"
#import "Reachability.h"
#import "Launcher.h"

@implementation HAWebService

NSString * const kCONTENT_TYPE_URL_ENCODED = @"application/x-www-form-urlencoded";
NSString * const kCONTENT_TYPE_JSON = @"application/json";

NSString * const kIMAGE_UPLOAD_URL = @"https://upload.bonfire.camp/v1/upload";

static HAWebService *manager;

+ (instancetype)manager {
    // assume authenticated
    // assume contentType = kCONTENT_TYPE_URL_ENCODED
    return [HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED];
}

+ (HAWebService *)managerWithContentType:(NSString * _Nullable)contentType {
    if (!manager) {
        manager = [[HAWebService alloc] init];
    }
    
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Configuration API_KEY]] forHTTPHeaderField:@"Authorization"];
    
    if (contentType == nil) {
        contentType = kCONTENT_TYPE_URL_ENCODED;
    }
    [manager.requestSerializer setValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    return manager;
}

+ (HAWebService *)authenticatedManager {
    return [[HAWebService manager] authenticate];
}

- (id)init {
    self = [super init];
    if (self) {
        self = [[HAWebService alloc] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [Configuration API_BASE_URI], [Configuration API_CURRENT_VERSION]]]];
        
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
        [self.requestSerializer setValue:[NSString stringWithFormat:@"%@", [NSString stringWithFormat:@"iosClient/%@", appVersion]] forHTTPHeaderField:@"x-rooms-client"];
        [self.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [self.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Configuration API_KEY]] forHTTPHeaderField:@"Authorization"];
        [self.requestSerializer setTimeoutInterval:10];
    }
    return self;
}

// In order to update the  the manager instance,
+ (void)reset {
    manager = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:manager];
    
    NSLog(@"manager after being deleted: %@", manager);
    
    manager = [[HAWebService alloc] init];
    
    NSLog(@"manager after being re-initialized: %@", manager);
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request uploadProgress:(void (^)(NSProgress * _Nonnull))uploadProgressBlock downloadProgress:(void (^)(NSProgress * _Nonnull))downloadProgressBlock completionHandler:(void (^)(NSURLResponse * _Nonnull, id _Nullable, NSError * _Nullable))completionHandler {
    //create a completion block that wraps the original
    void (^authFailBlock)(NSURLResponse *response, id responseObject, NSError *error) = ^(NSURLResponse *response, id responseObject, NSError *error)
    {
        NSInteger code = [responseObject[@"error"][@"code"] integerValue];
        NSLog(@"code: %ld", (long)code);
        
        if (code == BAD_AUTHENTICATION || code == BAD_ACCESS_TOKEN) {
            // refresh the token!
            
            //since there was an error, call you refresh method and then redo the original task
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                
                [[Session sharedInstance] getNewAccessToken:^(BOOL success, NSString * _Nonnull newToken) {
                    if (success) {
                        //  queue up and execute the original task
                        NSURLSessionDataTask *originalTask = [super dataTaskWithRequest:request uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:completionHandler];
                        [originalTask resume];
                    }
                    else {
                        [[Session sharedInstance] signOut];
                        
                        [[Launcher sharedInstance] openOnboarding];
                        
                        completionHandler(response, responseObject, error);
                    }
                }];
            });
        }
        else if (code == BAD_REFRESH_TOKEN || code == BAD_REFRESH_LOGIN_REQ) {
            NSLog(code == BAD_REFRESH_TOKEN ? @"bad refresh token" : @"BAD_REFRESH_LOGIN_REQ");
            
            [[Session sharedInstance] signOut];
            
            [[Launcher sharedInstance] openOnboarding];
            
            completionHandler(response, responseObject, error);
        }
        else{
            completionHandler(response, responseObject, error);
        }
    };
    
    NSURLSessionDataTask *task = [super dataTaskWithRequest:request uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:authFailBlock];
    
    return task;
}

#pragma mark - Helper functions
+ (BOOL)hasInternet {
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    return networkStatus != NotReachable;
}

- (instancetype)authenticate {
    [Session authenticate:^(BOOL success, NSString * _Nonnull token) {
        if (success) {
            [self.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
        }
        else {
            // logout
            [[Session sharedInstance] signOut];
            [[Launcher sharedInstance] openOnboarding];
        }
    }];
    
    return self;
}

@end
