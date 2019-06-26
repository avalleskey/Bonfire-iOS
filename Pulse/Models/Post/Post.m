#import "Post.h"
#import "Session.h"
#import "GTMNSString+HTML.h"
#import <SearchEmojiOnString/NSString+EMOEmoji.h>

@implementation Post

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    NSArray *optionalProperties = @[@"tempId"];
    if ([optionalProperties containsObject:propertyName]) return YES;
    return NO;
}

- (BOOL)requiresURLPreview {
    return false;
    
    /*
    if (self.attributes.details.message != nil) {
        // break apart the message
        // Only TRUE if:
        // • begins or ends with valid URL
        // • has only one URL
        
        NSArray *parts = [self.attributes.details.message componentsSeparatedByString:@" "];
        if (parts.count > 0) {
            if ([self validateUrl:[parts firstObject]]) {
                NSLog(@"found valid URL: %@", [parts firstObject]);
                return true;
            }
            else if (parts.count > 1 &&
                     [self validateUrl:[parts lastObject]]) {
                NSLog(@"found valid URL at end: %@", [parts lastObject]);
                return true;
            }
        }
    }
    
    return false;*/
}

- (void)createTempWithMessage:(NSString *)message media:(BFMedia *)media postedIn:(Camp * _Nullable)postedIn parentId:(NSString *)parentId {
    self.type = @"post";
    self.tempId = [NSString stringWithFormat:@"%d", [Session getTempId]];
    // TODO: Add support for images
    
    PostAttributes *attributes = [[PostAttributes alloc] init];

    PostDetails *details = [[PostDetails alloc] init];
    details.creator = [Session sharedInstance].currentUser;
    if (message) {
        details.message = message;
    }
    if (parentId) {
        NSLog(@"set parent id! %@", parentId);
        details.parentId = parentId;
    }
    if (media && media.objects.count > 0) {
        details.media = [media toDataArray];
    }
    attributes.details = details;
    
    PostStatus *status = [[PostStatus alloc] init];
    
    NSDate *date = [NSDate new];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    status.createdAt = [dateFormatter stringFromDate:date];
    if (postedIn) {
        status.postedIn = postedIn;
    }
    attributes.status = status;
    
    self.attributes = attributes;
}

- (BOOL)validateUrl: (NSString *) candidate {
    NSString *urlRegEx =
    @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

+ (NSString *_Nullable)trimString:(NSString *_Nullable)string {
    if (string != nil) {
        return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    return @"";
}

- (BOOL)isEmojiPost {
    return self.attributes.details.emojify;
}

@end

@implementation PostAttributes

@end

@implementation PostStatus

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation PostStatusDisplay

NSString * const POST_CHOSEN_RECENT = @"recent";
NSString * const POST_CHOSEN_POPULAR = @"popular";
NSString * const POST_CHOSEN_FOLLOWED = @"followed";
NSString * const POST_CHOSEN_SUGGESTED = @"suggested";
NSString * const POST_CHOSEN_SPONSORED = @"sponsored";

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation PostCounts

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    NSArray *optionalProperties = @[@"replies", @"live"];
    if ([optionalProperties containsObject:propertyName]) return YES;
    return NO;
}

@end

@implementation PostSummaries

@end

@implementation PostDetails

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

- (NSString *)simpleMessage {
    NSString *trimmedString = [Post trimString:self.message];
    
    return trimmedString;
    
    
    /* TODO: Disabled for now - still need to build metadata downloader
     
     // trim leading and trailing spaces
     if (self.message != nil) {
     NSString *trimmedString = [self trimString:self.message];
     // break apart the message
     // Only TRUE if:
     // • begins or ends with valid URL
     // • has only one URL
     
     NSArray *parts = [trimmedString componentsSeparatedByString:@" "];
     if (parts.count > 0) {
     NSString *firstPart = [parts firstObject];
     
     if ([self validateUrl:firstPart]) {
     NSLog(@"found valid URL: %@", firstPart);
     return [trimmedString stringByReplacingCharactersInRange:NSMakeRange(0, firstPart.length + 1) withString:@""];
     }
     else if (parts.count > 1 &&
     [self validateUrl:[parts lastObject]]) {
     NSString *lastPart = [parts lastObject];
     
     NSLog(@"found valid URL at end: %@", lastPart);
     return [self trimString:[trimmedString stringByReplacingCharactersInRange:[trimmedString rangeOfString:lastPart] withString:@""]];
     }
     }
     }
     
     return self.message;*/
}

- (void)setMessage:(NSString<Optional> *)message {
    if (message != _message) {
        _message = [message gtm_stringByUnescapingFromHTML];
        
        // set format
        self.emojify = ([_message emo_isPureEmojiString] && [_message emo_emojiCount] <= 3);
    }
}

- (BOOL)validateUrl: (NSString *) candidate {
    NSString *urlRegEx =
    @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

@end

@implementation PostAttachments

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation PostAttachmentsMedia

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation PostAttachmentsMediaAtributes

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

@end

@implementation PostAttachmentsMediaAtributesRawMedia

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation PostEntity

NSString * const POST_ENTITY_TYPE_PROFILE = @"profile";
NSString * const POST_ENTITY_TYPE_CAMP = @"camp";
NSString * const POST_ENTITY_TYPE_URL = @"url";

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end
