/**
 * This file is generated using the remodel generation script.
 * The name of the input file is UserAttributes.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "UserDetails.h"
#import "UserStatus.h"
#import "BFContext.h"
#import "UserSummaries.h"

@interface UserAttributes : JSONModel

@property (nonatomic) UserDetails <Optional> *details;
@property (nonatomic) UserStatus <Optional> *status;
@property (nonatomic) BFContext <Optional> *context;
@property (nonatomic) UserSummaries <Optional> *summaries;

@end

