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

static NSString * const kBackgroundSessionIdentifier = @"Ingenious.bonfire.backgroundsession";

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
    
    if (contentType == kCONTENT_TYPE_JSON) {
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
    }
    else {
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        contentType = kCONTENT_TYPE_URL_ENCODED;
    }
    
    [manager addBonfireHeaders];
    [manager.requestSerializer setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [manager.requestSerializer setTimeoutInterval:15];
    
    return manager;
}

+ (HAWebService *)authenticatedManager {
    return [[HAWebService manager] authenticate];
}

- (id)init {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.waitsForConnectivity = true;
    
    self = [super init];
    if (self) {
        self = [[HAWebService alloc] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", [Configuration API_BASE_URI], [Configuration API_CURRENT_VERSION]]] sessionConfiguration:configuration];
        
        self.requestSerializer = [AFHTTPRequestSerializer serializer];
        self.responseSerializer = [AFJSONResponseSerializer serializer];
                
        [self addBonfireHeaders];
    }
    return self;
}

- (void)addBonfireHeaders {
    // add standard bonfire headers
    [self.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [Configuration API_KEY]] forHTTPHeaderField:@"Authorization"];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
    NSString *clientString = [NSString stringWithFormat:@"iosClient/%@ b%@", appVersion, (buildNumber ? buildNumber : @"0")];
    if ([Configuration isDebug]) {
        clientString = [clientString stringByAppendingString:@"/debug"];
    }
    else if ([Configuration isBeta]) {
        clientString = [clientString stringByAppendingString:@"/beta"];
    }
    else {
        clientString = [clientString stringByAppendingString:@"/release"];
    }
    [self.requestSerializer setValue:[NSString stringWithFormat:@"%@", clientString] forHTTPHeaderField:@"x-bonfire-client"];
}

// In order to update the  the manager instance,
+ (void)reset {
    manager = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:manager];
    
    manager = [[HAWebService alloc] init];
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request uploadProgress:(void (^)(NSProgress * _Nonnull))uploadProgressBlock downloadProgress:(void (^)(NSProgress * _Nonnull))downloadProgressBlock completionHandler:(void (^)(NSURLResponse * _Nonnull, id _Nullable, NSError * _Nullable))completionHandler {
    //create a completion block that wraps the original
    void (^authFailBlock)(NSURLResponse *response, id responseObject, NSError *error) = ^(NSURLResponse *response, id responseObject, NSError *error)
    {
        NSInteger code = [responseObject[@"error"][@"code"] integerValue];
        
        if (code == BAD_AUTHENTICATION || code == BAD_ACCESS_TOKEN) {
            // refresh the token!
            
            //since there was an error, call you refresh method and then redo the original task
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                [[Session sharedInstance] getNewAccessToken:^(BOOL success, NSString * _Nonnull newToken) {
                    if (success) {
                        //  queue up and execute the original task
                        NSURLSessionDataTask *originalTask = [super dataTaskWithRequest:request uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:completionHandler];
                        [originalTask resume];
                    }
                    else {
                        [[Session sharedInstance] signOut];
                        
                        [Launcher openOnboarding];
                        
                        completionHandler(response, responseObject, error);
                    }
                }];
            });
        }
        else if (code == BAD_REFRESH_TOKEN || code == BAD_REFRESH_LOGIN_REQ) {
            [[Session sharedInstance] signOut];
            
            [Launcher openOnboarding];
            
            completionHandler(response, responseObject, error);
        }
        else if (code == OUT_OF_DATE_CLIENT) {
            [[Session sharedInstance] signOut];
            
            [Launcher openOutOfDateClient];
            
            completionHandler(response, responseObject, error);
        }
        else {
            if (error) {
                DSimpleLog(@"[🚩] (code: %lu) %@ → %@", code, request.HTTPMethod, request.URL.absoluteString);
                                
                if (error.code == NSURLErrorNotConnectedToInternet) {
                    DSimpleLog(@"[🚩] error: network connectivity");
                }
                else {
                    NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    if (ErrorResponse.length > 0) {
                        DSimpleLog(@"[🚩] error respone: %@",ErrorResponse);
                    }
                }
            }
            else {
                DSimpleLog(@"[🎉] (code: %lu) %@ → %@", code, request.HTTPMethod, request.URL.absoluteString);
            }
            
            completionHandler(response, responseObject, error);
        }
    };
    
    DSimpleLog(@"[👋] %@ → %@", request.HTTPMethod, request.URL.absoluteString);
    DSimpleLog(@"[👋] headers: %@", request.allHTTPHeaderFields);
    NSString *body = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
    if (body.length > 0) {
        DSimpleLog(@"[👋] body: %@", [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding]);
    }
    
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
            [Launcher openOnboarding];
        }
    }];
    
    return self;
}

@end
