//
//  Configuration.h
//  Pulse
//
//  Created by Austin Valleskey on 4/11/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Configuration : NSObject

extern NSString * const LOCAL_APP_URI;

#pragma mark -
+ (NSString *)configuration;
+ (BOOL)isDevelopment;

#pragma mark -
+ (NSString *)API_BASE_URI;
+ (NSString *)API_CURRENT_VERSION;
+ (NSString *)API_KEY;

#pragma mark - Internal URL Helpers
+ (BOOL)isInternalURL:(NSURL *)url;
+ (id)objectFromInternalURL:(NSURL *)url;
+ (BOOL)isExternalBonfireURL:(NSURL *)url;
+ (id)objectFromExternalBonfireURL:(NSURL *)url;
+ (NSDictionary *)parametersFromExternalBonfireURL:(NSURL *)url;
+ (BOOL)isBonfireURL:(NSURL *)url;

#pragma mark - Internal Swich Methods
+ (void)switchToDevelopment;
+ (void)switchToProduction;
+ (void)replaceDevelopmentURIWith:(NSString *)newURI;

#pragma mark - Misc. Getters
+ (NSString *)DEVELOPMENT_BASE_URI;
+ (BOOL)isDebug;
+ (BOOL)isBeta;
+ (BOOL)isRelease;

@end

NS_ASSUME_NONNULL_END
