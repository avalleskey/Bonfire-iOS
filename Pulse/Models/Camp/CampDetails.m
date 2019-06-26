#import "CampDetails.h"
#import "GTMNSString+HTML.h"

@implementation CampDetails

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"theDescription": @"description"
                                                                  }];
}

- (void)setTitle:(NSString<Optional> *)title {
    if (title != _title) {
        _title = [title gtm_stringByUnescapingFromHTML];
    }
}

- (void)setTheDescription:(NSString<Optional> *)theDescription {
    if (theDescription != _theDescription) {
        _theDescription = [theDescription gtm_stringByUnescapingFromHTML];
    }
}

@end

