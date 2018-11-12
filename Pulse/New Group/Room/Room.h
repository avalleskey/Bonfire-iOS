#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "RoomAttributes.h"

@interface Room : JSONModel

@property (nonatomic) NSString *identifier;
@property (nonatomic) NSString *type;
@property (nonatomic) RoomAttributes *attributes;

@end
