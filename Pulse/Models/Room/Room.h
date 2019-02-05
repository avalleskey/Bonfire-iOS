#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "RoomAttributes.h"

@interface Room : JSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) RoomAttributes <Optional> *attributes;

@end
