/**
 * This file is generated using the remodel generation script.
 * The name of the input file is User.value
 */

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "UserAttributes.h"

@interface User : JSONModel

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *type;
@property (nonatomic) UserAttributes *attributes;

@end

