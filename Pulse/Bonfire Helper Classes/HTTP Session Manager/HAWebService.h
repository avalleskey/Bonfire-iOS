//
//  HAWebService.h
//  Hallway App
//
//  Created by Austin Valleskey on 8/21/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import <AFNetworking/AFHTTPSessionManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface HAWebService : AFHTTPSessionManager

extern NSString * const kCONTENT_TYPE_URL_ENCODED;
extern NSString * const kCONTENT_TYPE_JSON;

extern NSString * const kIMAGE_UPLOAD_URL;

+ (HAWebService *)authenticatedManager;
+ (HAWebService *)managerWithContentType:(NSString * _Nullable)contentType;

@property (nonatomic, copy) void (^savedCompletionHandler)(void);

+ (void)reset;

+ (BOOL)hasInternet;

- (instancetype)authenticate;

@end

NS_ASSUME_NONNULL_END
