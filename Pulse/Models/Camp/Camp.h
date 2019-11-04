#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CampAttributes.h"

NS_ASSUME_NONNULL_BEGIN

@protocol Camp
@end

@interface Camp : JSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) CampAttributes <Optional> *attributes;

// internal use on
@property (nonatomic) NSInteger opens;
@property (nonatomic) NSDate *lastOpened;

// helper methods
- (BOOL)isVerified;

@end

@interface NSArray (CampArray)

- (NSArray <Camp *> *)toCampArray;
- (NSArray <NSDictionary *> *)toCampDictionaryArray;

@end

NS_ASSUME_NONNULL_END
