#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CampAttributes.h"

@interface Camp : JSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) CampAttributes <Optional> *attributes;

@end
