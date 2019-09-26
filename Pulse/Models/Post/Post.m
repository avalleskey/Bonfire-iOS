#import "Post.h"
#import "Session.h"
#import "GTMNSString+HTML.h"
#import <SearchEmojiOnString/NSString+EMOEmoji.h>
#import "BFLinkAttachmentView.h"
#import "NSURL+WebsiteTypeValidation.h"

@implementation Post

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

- (BOOL)hasLinkAttachment {
    return (self.attributes.details.attachments.link != nil);
}

- (BOOL)hasCampAttachment {
    return (self.attributes.details.attachments.camp != nil);
}

- (BOOL)hasUserAttachment {
    return (self.attributes.details.attachments.user != nil);
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

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}
+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

@end

@implementation PostStatus

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation PostStatusDisplay

NSString * const POST_DISPLAY_CREATOR_CAMP = @"camp";
NSString * const POST_DISPLAY_CREATOR_USER = @"user";

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

@implementation PostStatusDisplayFormat

NSString * const POST_DISPLAY_FORMAT_ICEBREAKER = @"icebreaker";

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
}

- (void)setMessage:(NSString<Optional> *)message {
    if (![message isEqualToString:_message]) {
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

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

- (void)setLink:(PostAttachmentsLink<Optional> *)link {
    if (link != _link) {
        _link = link;
        
        self.link.attributes.contentIdentifier = [self contentIdentifierForLink:link];
        
        if (self.link.attributes.linkTitle.length == 0) {
            if (self.link.attributes.theDescription.length > 0) {
                self.link.attributes.linkTitle = self.link.attributes.theDescription;
            }
            else {
                self.link.attributes.linkTitle = self.link.attributes.site;
            }
        }
    }
}

- (BFLinkAttachmentContentIdentifier)contentIdentifierForLink:(PostAttachmentsLink *)link {
    NSURL *url = [NSURL URLWithString:link.attributes.canonicalUrl];
    
    if ([url matches:REGEX_YOUTUBE]) {
        // youtube link
//        NSLog(@"youtube link!");
        return BFLinkAttachmentContentIdentifierYouTubeVideo;
    }
    if ([url matches:REGEX_SPOTIFY_SONG]) {
        // https://open.spotify.com/track/47n6zyO3Uf9axGAPIY0ZOd?si=EzRVMTfJTv2qygVe1BrV4Q
        // spotify song
//        NSLog(@"spotify song!");
        return BFLinkAttachmentContentIdentifierSpotifySong;
    }
    if ([url matches:REGEX_SPOTIFY_PLAYLIST]) {
        // spotify playlist
        // https://open.spotify.com/user/1248735265/playlist/7cu21dpm13nXHNu8BNp5qd?si=MzdEuaKPSveJWdKk2DcUDw
//        NSLog(@"spotify playlist!");
        return BFLinkAttachmentContentIdentifierSpotifyPlaylist;
    }
    if ([url matches:REGEX_APPLE_MUSIC_SONG]) {
        // apple music album
//        NSLog(@"apple music!");
        return BFLinkAttachmentContentIdentifierAppleMusicSong;
    }
    if ([url matches:REGEX_APPLE_MUSIC_ALBUM]) {
            // apple music album
//            NSLog(@"apple music!");
            return BFLinkAttachmentContentIdentifierAppleMusicAlbum;
        }
    if ([url matches:REGEX_SOUNDCLOUD]) {
        // soundcloud
//        NSLog(@"soundcloud!");
        return BFLinkAttachmentContentIdentifierSoundCloud;
    }
    if ([url matches:REGEX_APPLE_MUSIC_PODCAST_OR_PODCAST_EPISODE]) {
        // apple podcast (episode|show)
//        NSLog(@"apple podcast episode or show!");
        return BFLinkAttachmentContentIdentifierApplePodcast;
    }
    
    return BFLinkAttachmentContentIdentifierNone;
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

@implementation PostAttachmentsLink

+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

@end

@implementation PostAttachmentsLinkAttributes

NSString * const POST_LINK_CUSTOM_FORMAT_AUDIO = @"playable:audio";
NSString * const POST_LINK_CUSTOM_FORMAT_VIDEO = @"playable:video";

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"theDescription": @"description",
                                                                  @"canonicalUrl": @"canonical_url",
                                                                  @"actionUrl": @"action_url",
                                                                  @"iconUrl": @"icon_url",
                                                                  @"contentIdentifier": @"content_identifier",
                                                                  @"postedIn": @"posted_in",
                                                                  @"linkTitle": @"title"
                                                                  }];
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

- (void)setDisplayText:(NSString<Optional> *)displayText {
    if (![displayText isEqualToString:_displayText]) {
        _displayText = [displayText gtm_stringByUnescapingFromHTML];
    }
}

+ (BOOL)propertyIsOptional:(NSString*)propertyName
{
    return YES;
}

@end
