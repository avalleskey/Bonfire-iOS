#import "CampAttributes.h"
#import "GTMNSString+HTML.h"

@implementation CampAttributes

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"theDescription": @"description",
                                                                  @"isPrivate": @"private",
                                                                  @"isSuspended": @"suspended",
                                                                  @"isVerified": @"verified",
                                                                  @"createdAt": @"created_at"
                                                                  }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return true;
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

@implementation CampDisplay

NSString * const CAMP_DISPLAY_FORMAT_CHANNEL = @"channel";
NSString * const CAMP_DISPLAY_FORMAT_FEED = @"feed";

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

- (void)setSourceWithNSDictionary:(NSDictionary *)dictionary
{
    NSString *type = [dictionary objectForKey:@"type"];
    
    if (!type) {
        self.source = nil;
        self.sourceUser = nil;
        self.sourceLink = nil;
        
        return;
    }
    
    if ([type isEqualToString:@"user"]) {
        User *user = [[User alloc] initWithDictionary:dictionary error:nil];
        self.source = user;
        self.sourceUser = user;
        self.sourceLink = nil;
        
        return;
    }
    else if ([type isEqualToString:@"link"]) {
        BFLink *link = [[BFLink alloc] initWithDictionary:dictionary error:nil];
        self.source = link;
        self.sourceUser = nil;
        self.sourceLink = link;
        
        return;
    }
}

@end
