#import "Post.h"
#import "Session.h"
#import "GTMNSString+HTML.h"
#import <SearchEmojiOnString/NSString+EMOEmoji.h>
#import "BFMiniNotificationManager.h"
#import "BFLinkAttachmentView.h"
#import "HAWebService.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
@import Firebase;

@implementation Post

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

- (id)init {
    if (self = [super init]) {
        self.type = @"post";
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err {
    Post *instance = [super initWithDictionary:dict error:err];
    
    // check if contains mention
    for (PostEntity *entity in instance.attributes.entities) {
        if ([entity.type isEqualToString:POST_ENTITY_TYPE_PROFILE] && [[entity.displayText lowercaseString] isEqualToString:[NSString stringWithFormat:@"@%@", [[Session sharedInstance].currentUser.attributes.identifier lowercaseString]]]) {
            instance.containsMention = true;
            break;
        }
    }
    if ([[self.attributes.creator.identifier lowercaseString] isEqualToString:[[Session sharedInstance].currentUser.identifier lowercaseString]]) {
        instance.isCreator = true;
    }
    [instance updateThemeColor];
        
    return instance;
}

- (void)updateThemeColor {
    Camp *postedIn = self.attributes.postedIn;
    if (!postedIn && self.attributes.parent && self.attributes.parent.attributes.postedIn) {
        postedIn =  self.attributes.parent.attributes.postedIn;
    }
    
    if (postedIn) {
        self.themeColor = (postedIn.attributes.color ?: [UIColor toHex:[UIColor bonfireSecondaryColor]]);
    }
    else {
        self.themeColor = (self.attributes.creator.attributes.color ?: [UIColor toHex:[UIColor bonfireSecondaryColor]]);
    }
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

- (BOOL)hasLinkAttachment {
    return (self.attributes.attachments.link != nil);
}

- (BOOL)hasCampAttachment {
    return (self.attributes.attachments.camp != nil);
}

- (BOOL)hasUserAttachment {
    return (self.attributes.attachments.user != nil);
}

- (BOOL)hasPostAttachment {
    return (self.attributes.attachments.post != nil);
}

- (BOOL)isRemoved {
    return (self.attributes.removedAt.length > 0);
}

- (void)createTempWithMessage:(NSString * _Nullable)message media:(BFMedia * _Nullable)media postedIn:(Camp * _Nullable)postedIn parent:(Post * _Nullable)parent attachments:(PostAttachments * _Nullable)attachments {
    self.type = @"post";
    self.tempId = [NSString stringWithFormat:@"%d", [Session getTempId]];
    // TODO: Add support for images
    
    PostAttributes *attributes = [[PostAttributes alloc] init];

    attributes.creator = [Session sharedInstance].currentUser;
    if (message) {
        attributes.message = message;
    }
    if (parent) {
        Post *postCopy = [[Post alloc] initWithDictionary:@{@"id": parent.identifier, @"type": @"post"} error:nil];
        attributes.parent = postCopy;
    }
    if (media && media.objects.count > 0) {
        attributes.media = [media toDataArray];
    }
    if (attachments) {
        attributes.attachments = attachments;
    }
        
    NSDate *date = [NSDate new];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    attributes.createdAt = [dateFormatter stringFromDate:date];
    if (postedIn) {
        attributes.postedIn = postedIn;
    }
    
    self.attributes = attributes;
}

+ (NSString *_Nullable)trimString:(NSString *_Nullable)string {
    if (string != nil) {
        return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    return @"";
}

- (BOOL)isEmojiPost {
    return self.attributes.emojify;
}

- (void)report {
    [FIRAnalytics logEventWithName:@"post_report"
                            parameters:@{}];
    
    BFMiniNotificationObject *notificationObject = [BFMiniNotificationObject notificationWithText:@"Reported" action:nil];
    [[BFMiniNotificationManager manager] presentNotification:notificationObject completion:^{

    }];
        
    NSString *url = [NSString stringWithFormat:@"posts/%@/reports", self.identifier];
    
    [[HAWebService authenticatedManager] POST:url parameters:nil progress:nil success:nil failure:nil];
}

- (void)muteWithCmpletion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler {
    [FIRAnalytics logEventWithName:@"post_mute"
                            parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"posts/%@/subscriptions", self.identifier];
    [[HAWebService authenticatedManager] DELETE:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        BFMiniNotificationObject *notificationObject = [BFMiniNotificationObject notificationWithText:@"Muted" action:nil];
        [[BFMiniNotificationManager manager] presentNotification:notificationObject completion:nil];
        
        if (handler) {
            handler(true, self);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            handler(false, self);
        }
    }];
    
    // update model
    Post *post = [[Post alloc] initWithDictionary:[self toDictionary] error:nil];
    BFContext *context = [[BFContext alloc] initWithDictionary:[post.attributes.context toDictionary] error:nil];
    BFContextPost *contextPost = [[BFContextPost alloc] initWithDictionary:[context.post toDictionary] error:nil];
    contextPost.muted = true;
    context.post = contextPost;
    post.attributes.context = context;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:post];
}
- (void)mute {
    [self muteWithCmpletion:nil];
}

- (void)unMuteWithCmpletion:(void (^_Nullable)(BOOL success, id _Nullable responseObject))handler {
    [FIRAnalytics logEventWithName:@"post_unmute"
                            parameters:@{}];
    
    NSString *url = [NSString stringWithFormat:@"posts/%@/subscriptions", self.identifier];
    [[HAWebService authenticatedManager] POST:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (handler) {
            handler(true, self);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (handler) {
            handler(false, self);
        }
    }];
    
    // update model
    Post *post = [[Post alloc] initWithDictionary:[self toDictionary] error:nil];
    BFContext *context = [[BFContext alloc] initWithDictionary:[post.attributes.context toDictionary] error:nil];
    BFContextPost *contextPost = [[BFContextPost alloc] initWithDictionary:[context.post toDictionary] error:nil];
    contextPost.muted = false;
    context.post = contextPost;
    post.attributes.context = context;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PostUpdated" object:post];
}
- (void)unMute {
    [self unMuteWithCmpletion:nil];
}

@end

@implementation PostAttributes

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

// details
- (NSString *)simpleMessage {
    NSString *trimmedString = [Post trimString:self.message];
    
    return trimmedString;
}

- (NSString *)simpleMessageWithTruncationLimit:(NSInteger)truncationLimit {
    NSString *message = [self simpleMessage];
    return (message.length > truncationLimit) ? [[message substringToIndex:truncationLimit] stringByAppendingString:@"..."] : message;
}

- (void)setMessageWithNSString:(NSString *)string {
    self.message = [string gtm_stringByUnescapingFromHTML];
    
    self.emojify = ([self.message emo_isPureEmojiString] && [self.message emo_emojiCount] <= 3);
}

- (void)setRemovedReason:(NSString<Optional> *)removedReason {
    if (removedReason.length == 0) {
        removedReason = @"This Post has been removed";
    }
    
    if (![removedReason isEqualToString:_removedReason]) {
        _removedReason = removedReason;
    }
}

- (void)setCreator:(Identity<Optional> *)creator {
    if (creator != _creator) {
        _creator = creator;
        
        if ([creator isKindOfClass:[User class]]) {
            self.creatorUser = (User *)creator;
            self.creatorBot = nil;
        }
        else if ([creator isKindOfClass:[Bot class]]) {
            self.creatorUser = nil;
            self.creatorBot = (Bot *)creator;
        }
        else {
            self.creatorUser = nil;
            self.creatorBot = nil;
        }
    }
}
- (void)setCreatorWithNSDictionary:(NSDictionary *)dictionary
{
    NSString *type = [dictionary objectForKey:@"type"];
    
    if (!type) {
        self.creator = nil;
        self.creatorUser = nil;
        self.creatorBot = nil;
        
        return;
    }
    
    if ([type isEqualToString:@"user"]) {
        User *user = [[User alloc] initWithDictionary:dictionary error:nil];
        self.creator = user;
        self.creatorUser = user;
        self.creatorBot = nil;
        
        return;
    }
    else if ([type isEqualToString:@"bot"]) {
        Bot *bot = [[Bot alloc] initWithDictionary:dictionary error:nil];
        self.creator = bot;
        self.creatorUser = nil;
        self.creatorBot = bot;
        
        return;
    }
}

@end

@implementation PostAttributesThread

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}
+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

@end

@implementation PostDisplay

NSString * const POST_DISPLAY_CREATOR_CAMP = @"camp";

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation PostDisplayFormat

NSString * const POST_DISPLAY_FORMAT_ICEBREAKER = @"icebreaker";

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation PostCounts

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

@end

@implementation PostSummaries

@end

@implementation PostAttachments

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

@end

@implementation PostAttachmentsMedia

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                      @"identifier": @"id"
                                                                      }];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
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

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
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

- (void)setDisplayTextWithNSString:(NSString *)string {
    self.displayText = [string gtm_stringByUnescapingFromHTML];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

@end
