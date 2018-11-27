/**
 * This file is generated using the remodel generation script.
 * The name of the input file is UserAttributes.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "UserDetails.h"
#import "UserStatus.h"
#import "UserContext.h"

@interface UserAttributes : JSONModel

@property (nonatomic) UserDetails *details;
@property (nonatomic) UserStatus <Optional> *status;
@property (nonatomic) UserContext <Optional> *context;
@property (nonatomic) NSString <Optional> *email;

@end

