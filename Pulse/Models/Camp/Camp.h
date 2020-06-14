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
- (BOOL)isMember;
- (BOOL)isVerified;
- (BOOL)isDefaultCamp;
- (BOOL)isPrivate;
- (BOOL)isSupported; // ensure all walls are supported by the installed version
- (BOOL)isFavorite;

- (BOOL)isChannel;
- (BOOL)isFeed;

- (NSString *)mostDescriptiveIdentifier;
- (NSString *)memberCountTieredRepresentation;
+ (NSString *)memberCountTieredRepresentationFromInteger:(NSInteger)memberCount;

#pragma mark - API Methods
- (void)subscribeToCamp;
- (void)unsubscribeFromCamp;

- (void)favorite;
- (void)unFavorite;

@end

@interface NSArray (CampArray)

- (NSArray <Camp *> *)toCampArray;
- (NSArray <NSDictionary *> *)toCampDictionaryArray;

@end

NS_ASSUME_NONNULL_END
