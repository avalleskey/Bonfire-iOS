/**
 * This file is generated using the remodel generation script.
 * The name of the input file is CampAttributes.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CampDetails.h"
#import "CampStatus.h"
#import "CampSummaries.h"
#import "BFContext.h"

@interface CampAttributes : JSONModel

@property (nonatomic) CampDetails <Optional> *details;
@property (nonatomic) CampStatus <Optional> *status;
@property (nonatomic) CampSummaries <Optional> *summaries;
@property (nonatomic) BFContext <Optional> *context;

@end

