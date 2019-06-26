/**
 * This file is generated using the remodel generation script.
 * The name of the input file is CampSummaries.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CampCounts.h"
#import "User.h"

@interface CampSummaries : JSONModel

@property (nonatomic) NSArray <User *> <User, Optional> *members;
@property (nonatomic) CampCounts <Optional> *counts;

@end

