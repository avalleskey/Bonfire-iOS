#import "Post.h"
#import "Session.h"

@implementation Post

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
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

- (BOOL)validateUrl: (NSString *) candidate {
    NSString *urlRegEx =
    @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

- (void)createTempWithMessage:(NSString *)message images:(NSArray *)images postedIn:(Room * _Nullable)postedIn parent:(NSInteger)parentId {
    self.type = @"post";
    self.tempId = [NSString stringWithFormat:@"%d", [[Session sharedInstance] getTempId]];
    // TODO: Add support for images
    
    PostAttributes *attributes = [[PostAttributes alloc] init];
    /*
     @property (nonatomic) PostDetails *details;
     @property (nonatomic) PostStatus *status;
     @property (nonatomic) PostSummaries *summaries;
     @property (nonatomic) PostContext *context;
     */
    PostDetails *details = [[PostDetails alloc] init];
    details.creator = [Session sharedInstance].currentUser;
    if (message) {
        details.message = message;
    }
    if (parentId) {
        details.parent = parentId;
    }
    if (images) {
        
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

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    NSArray *optionalProperties = @[@"rowHeight", @"tempId"];
    if ([optionalProperties containsObject:propertyName]) return YES;
    return NO;
}

@end

@implementation PostAttributes

@end

@implementation PostDisplay

@end

@implementation PostStatus

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation PostStatusDisplay

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation PostCounts

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
    NSArray *optionalProperties = @[@"parent"];
    if ([optionalProperties containsObject:propertyName]) return YES;
    return NO;
}

- (NSString *)simpleMessage {
    NSString *trimmedString = [self trimString:self.message];
    
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

- (NSString *)trimString:(NSString *)string {
    if (string != nil) {
        return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    return @"";
}

- (BOOL)validateUrl: (NSString *) candidate {
    NSString *urlRegEx =
    @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
}

@end

@implementation PostContext

@end

@implementation PostContextReplies

@end

@implementation PostContextVote

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end
