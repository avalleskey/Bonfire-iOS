//
//  UserDiscoverability.h
//  Pulse
//
//  Created by Austin Valleskey on 11/25/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

@interface UserDiscoverability : JSONModel

@property (nonatomic) BOOL isPrivate;
@property (nonatomic) BOOL searchable;

@end
