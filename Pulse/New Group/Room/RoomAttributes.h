/**
 * This file is generated using the remodel generation script.
 * The name of the input file is RoomAttributes.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "RoomDetails.h"
#import "RoomStatus.h"
#import "RoomSummaries.h"
#import "RoomContext.h"

@interface RoomAttributes : JSONModel

@property (nonatomic) RoomDetails <Optional> *details;
@property (nonatomic) RoomStatus <Optional> *status;
@property (nonatomic) RoomSummaries <Optional> *summaries;
@property (nonatomic) RoomContext <Optional> *context;

@end

