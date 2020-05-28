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
+ (BOOL)isExternalBonfireURL:(NSURL *)url;
+ (BOOL)isBonfireURL:(NSURL *)url;

+ (NSString *)pathStringFromBonfireURL:(NSURL *)url;
+ (NSArray<NSString *> *)pathPartsFromBonfireURL:(NSURL *)url;
+ (NSDictionary *)parametersFromExternalBonfireURL:(NSURL *)url;
+ (id)objectFromBonfireURL:(NSURL *)url;

#pragma mark - Internal Swich Methods
+ (void)switchToDevelopment;
+ (void)switchToProduction;
+ (void)replaceCurrentURIWith:(NSString *)newURI;

#pragma mark - Misc. Getters
+ (NSString *)CURRENT_BASE_URI;
+ (NSString *)DEVELOPMENT_BASE_URI;
+ (NSString *)PRODUCTION_BASE_URI;
+ (BOOL)isDebug;
+ (BOOL)isBeta;
+ (BOOL)isRelease;

@end

NS_ASSUME_NONNULL_END
