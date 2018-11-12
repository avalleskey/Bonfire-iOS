//
//  HAWebService.h
//  Hallway App
//
//  Created by Austin Valleskey on 8/21/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import <AFNetworking/AFNetworking.h>

@interface HAWebService : AFHTTPSessionManager

+ (instancetype)manager;

@end
