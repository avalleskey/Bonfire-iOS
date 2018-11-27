/**
 * This file is generated using the remodel generation script.
 * The name of the input file is UserStatus.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "UserDiscoverability.h"

@interface UserStatus : JSONModel

@property (nonatomic) NSString *createdAt;
// @property (nonatomic) BOOL isActive;
// @property (nonatomic) BOOL isBlocked;
@property (nonatomic) UserDiscoverability <Optional> *discoverability;

@end

