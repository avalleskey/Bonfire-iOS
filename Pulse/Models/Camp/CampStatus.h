/**
 * This file is generated using the remodel generation script.
 * The name of the input file is CampStatus.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CampVisibility.h"

@interface CampStatus : JSONModel

@property (nonatomic) BOOL isActive;
@property (nonatomic) BOOL isBlocked;
@property (nonatomic) CampVisibility *visibility;

@end

