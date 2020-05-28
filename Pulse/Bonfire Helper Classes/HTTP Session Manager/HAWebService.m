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
#import "AccountSuspendedViewController.h"

#import <Security/Security.h>
#import <CommonCrypto/CommonHMAC.h>

#import "NSString+getQueryStringParameter.h"

@implementation HAWebService

NSString * const kCONTENT_TYPE_URL_ENCODED = @"application/x-www-form-urlencoded";
NSString * const kCONTENT_TYPE_JSON = @"application/json";

NSString * const kIMAGE_UPLOAD_URL = @"https://upload.bonfire.camp/v1/upload";

NSString * const xBonfireClientFieldName = @"X-Bonfire-Client";
NSString * const xBonfireTimeStampFieldName = @"X-Authorization-Timestamp";

static NSString * const kBackgroundSessionIdentifier = @"Ingenious.bonfire.backgroundsession";

static HAWebService *manager;

+ (instancetype)manager {
    // assume authenticated
    // assume contentType = kCONTENT_TYPE_URL_ENCODED
    return [HAWebService managerWithContentType:kCONTENT_TYPE_URL_ENCODED];
}

+ (HAWebService *)managerWithContentType:(NSString * _Nullable)contentType {
    return [HAWebService managerWithContentType:contentType options:0];
}
+ (HAWebService *)managerWithContentType:(NSString * _Nullable)contentType options:(HAWebServiceManagerOptions)options {
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
    [manager.requestSerializer setTimeoutInterval:60];
    
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
    [self.requestSerializer setValue:[NSString stringWithFormat:@"%@", clientString] forHTTPHeaderField:xBonfireClientFieldName];
}

+ (NSString*)hmacSHA256:(NSString*)data withKey:(NSString *)key {
    const char *cKey = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *hash = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    NSString *hexString = [HAWebService hexStringForData:hash];
    NSData *hexStringData = [hexString dataUsingEncoding:NSASCIIStringEncoding];
    
    return [HAWebService base64forData:hexStringData];
}
+ (NSString *)hexStringForData:(NSData *)data
{
    if (data == nil) {
        return nil;
    }
    
    NSMutableString *hexString = [NSMutableString string];
    
    const unsigned char *p = [data bytes];
    
    for (int i=0; i < [data length]; i++) {
        [hexString appendFormat:@"%02x", *p++];
    }
    
    return hexString;
}

+ (NSString*)base64forData:(NSData*)theData {
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {  value |= (0xFF & input[j]);  }  }  NSInteger theIndex = (i / 3) * 4;  output[theIndex + 0] = table[(value >> 18) & 0x3F];
        output[theIndex + 1] = table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6) & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0) & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
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
        DSimpleLog(@"[🤔] %@ → %@ response headers: %@", request.HTTPMethod, request.URL.absoluteString, response);
        
        NSInteger code = [error bonfireErrorCode];
        
        if (code == BAD_AUTHENTICATION || code == BAD_ACCESS_TOKEN) {
            // refresh the token!
            
            //since there was an error, call you refresh method and then redo the original task
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                [[Session sharedInstance] getNewAccessToken:^(BOOL success, NSString * _Nonnull newToken, NSInteger bonfireErrorCode) {
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
        else if (code == ACTIONER_PROFILE_SUSPENDED) {
            [[Session sharedInstance] signOut];
            
            if (![[Launcher activeViewController] isKindOfClass:[AccountSuspendedViewController class]]) {
                [Launcher openOnboarding];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [Launcher openAccountSuspended];
                });
            }
            
            completionHandler(response, responseObject, error);
        }
        else {
            if (error) {
                DSimpleLog(@"[🚩] (code: %lu) %@ → %@", code, request.HTTPMethod, request.URL.absoluteString);
                     
                NSHTTPURLResponse *httpResponse = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
                NSInteger statusCode = httpResponse.statusCode;
                
                if (error.code == NSURLErrorNotConnectedToInternet) {
                    DSimpleLog(@"[🚩] error: network connectivity");
                    completionHandler(response, responseObject, error);
                }
                else if ([request.HTTPMethod isEqualToString:@"GET"] && statusCode == 504) {
                    // try again once
                    NSURLSessionDataTask *originalTask = [super dataTaskWithRequest:request uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:completionHandler];
                    [originalTask resume];
                }
                else {
                    NSString* ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                    if (ErrorResponse.length > 0) {
                        DSimpleLog(@"[🚩] error respone: %@",ErrorResponse);
                    }
                    completionHandler(response, responseObject, error);
                }
            }
            else {
                DSimpleLog(@"[🎉] (code: %lu) %@ → %@", code, request.HTTPMethod, request.URL.absoluteString);
                completionHandler(response, responseObject, error);
            }
        }
    };
        
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    if ([request.HTTPMethod isEqualToString:@"POST"]) {
        // increase timeout
        mutableRequest.timeoutInterval = 60 * 2; // allow 2min (some media uploads may take a while)
    }
    [self addAdditionalHeadersForRequest:mutableRequest];
    
    DSimpleLog(@"[👋] %@ → %@ (%fs timeout)", mutableRequest.HTTPMethod, mutableRequest.URL.absoluteString, mutableRequest.timeoutInterval);
    DSimpleLog(@"[👋] headers: %@", mutableRequest.allHTTPHeaderFields);
    NSString *body = [[NSString alloc] initWithData:[mutableRequest HTTPBody] encoding:NSUTF8StringEncoding];
    if (body.length > 0) {
        DSimpleLog(@"[👋] body: %@", [[NSString alloc] initWithData:[mutableRequest HTTPBody] encoding:NSUTF8StringEncoding]);
    }
    
    NSURLSessionDataTask *task = [super dataTaskWithRequest:mutableRequest uploadProgress:uploadProgressBlock downloadProgress:downloadProgressBlock completionHandler:authFailBlock];
    
    return task;
}
- (void)addAdditionalHeadersForRequest:(NSMutableURLRequest *)request {
    NSString *method = request.HTTPMethod;
    NSString *host = [NSString stringWithFormat:@"%@://%@", request.URL.scheme, request.URL.host];
    NSString *path = request.URL.path;
    NSString *parameters = @"";
    if (request.URL.query && request.URL.query.length > 0) {
        parameters = request.URL.query;
    }
    NSString *bodyParameters = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSUTF8StringEncoding];
    if ([[request.allHTTPHeaderFields valueForKey:@"Content-Type"] isEqualToString:kCONTENT_TYPE_URL_ENCODED] && bodyParameters && bodyParameters.length > 0) {
        if (parameters.length > 0) {
            parameters = [parameters stringByAppendingString:@"&"];
        }
        parameters = [parameters stringByAppendingString:bodyParameters];
    }
    NSString *token = [Session sharedInstance].accessTokenString ? [Session sharedInstance].accessTokenString : @"";
    NSString *timestamp = [@(floor([[NSDate date] timeIntervalSince1970])) stringValue];
    NSString *appId = [Configuration API_KEY];
    
    NSString *message = @"";
    NSMutableArray *parts = [NSMutableArray new];
    [parts addObject:method?method:@""];
    [parts addObject:host?host:@""];
    [parts addObject:path?path:@""];
    [parts addObject:parameters?parameters:@""];
    [parts addObject:token?token:@""];
    [parts addObject:timestamp?timestamp:@""];
    [parts addObject:appId?appId:@""];

    for (NSString *p in parts) {
        message = [message stringByAppendingFormat:@"%@%@", (p.length>0 ? p : @""), (p != [parts lastObject] ? @" " : @"")];
    }

    NSString *signature = [HAWebService hmacSHA256:message withKey:@"007c7ac746a314857510b2c08188ccfa"];
    
    // Set http fields
    [request setValue:timestamp forHTTPHeaderField:xBonfireTimeStampFieldName];
    [request setValue:signature forHTTPHeaderField:@"Signature"];
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
