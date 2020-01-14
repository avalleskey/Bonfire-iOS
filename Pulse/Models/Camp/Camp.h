#import <Foundation/Foundation.h>
#import "BFJSONModel.h"
#import "CampAttributes.h"

NS_ASSUME_NONNULL_BEGIN

@protocol Camp
@end

@interface Camp : BFJSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) CampAttributes <Optional> *attributes;

// internal use on
@property (nonatomic) NSInteger opens;
@property (nonatomic) NSDate *lastOpened;
@property (nonatomic) NSString *scoreColor;

// helper methods
- (BOOL)isVerified;
- (BOOL)isChannel;
- (BOOL)isPrivate;

#pragma mark - API Methods
- (void)subscribeToCamp;
- (void)unsubscribeFromCamp;

@end

@interface NSArray (CampArray)

- (NSArray <Camp *> *)toCampArray;
- (NSArray <NSDictionary *> *)toCampDictionaryArray;

@end

NS_ASSUME_NONNULL_END
