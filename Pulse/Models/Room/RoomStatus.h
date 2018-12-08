/**
 * This file is generated using the remodel generation script.
 * The name of the input file is RoomStatus.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "RoomVisibility.h"

@interface RoomStatus : JSONModel

@property (nonatomic) BOOL isActive;
@property (nonatomic) BOOL isBlocked;
@property (nonatomic) RoomVisibility *visibility;

@end

