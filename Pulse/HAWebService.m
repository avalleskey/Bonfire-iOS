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

@implementation HAWebService

+ (instancetype)manager {
    HAWebService *manager = [[self alloc] initWithBaseURL:nil];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    
    // set defaults
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", envConfig[@"API_KEY"]] forHTTPHeaderField:@"Authorization"];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"iosClient/bonfire"] forHTTPHeaderField:@"x-rooms-client"];
    [manager.requestSerializer setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
//    [manager.requestSerializer setValue:@"https://hallway.app" forHTTPHeaderField:@"origin"];
//    [manager.requestSerializer setValue:nil forHTTPHeaderField:@"Origin"];
    [manager.requestSerializer setTimeoutInterval:10];
    
    return manager;
}

- (BOOL)hasInternet {
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [networkReachability currentReachabilityStatus];
    
    return networkStatus != NotReachable;
}

@end
