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

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err {
    Post *instance = [super initWithDictionary:dict error:err];
    
    // check if contains mention
    for (PostEntity *entity in instance.attributes.entities) {
        if ([entity.type isEqualToString:POST_ENTITY_TYPE_PROFILE] && [entity.displayText isEqualToString:[NSString stringWithFormat:@"@%@", [Session sharedInstance].currentUser.attributes.identifier]]) {
            instance.containsMention = true;
            break;
        }
    }
    if ([self.attributes.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
        instance.isCreator = true;
    }
        
    return instance;
}

- (BOOL)validate:(NSError **)error
{
    if (![super validate:error])
        return NO;

    if ([self.type isEqualToString:@"post"])
    {
        return NO;
    }

    return YES;
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

- (BOOL)isRemoved {
    return (self.attributes.removedAt.length > 0);
}

- (void)createTempWithMessage:(NSString *)message media:(BFMedia *)media postedIn:(Camp * _Nullable)postedIn parent:(Post *)parent {
    self.type = @"post";
    self.tempId = [NSString stringWithFormat:@"%d", [Session getTempId]];
    // TODO: Add support for images
    
    PostAttributes *attributes = [[PostAttributes alloc] init];

    attributes.creator = [Session sharedInstance].currentUser;
    if (message) {
        attributes.message = message;
    }
    if (parent) {
        attributes.parent = parent;
    }
    if (media && media.objects.count > 0) {
        attributes.media = [media toDataArray];
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
    return self.attributes.emojify;
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

- (void)setMessage:(NSString<Optional> *)message {
    if (![message isEqualToString:_message]) {
        _message = [message gtm_stringByUnescapingFromHTML];
        
        // set format
        self.emojify = ([_message emo_isPureEmojiString] && [_message emo_emojiCount] <= 3);
    }
}

- (void)setRemovedReason:(NSString<Optional> *)removedReason {
    if (removedReason.length == 0) {
        removedReason = @"This Post has been removed";
    }
    
    if (![removedReason isEqualToString:_removedReason]) {
        _removedReason = removedReason;
    }
}

- (BOOL)validateUrl: (NSString *) candidate {
    NSString *urlRegEx =
    @"(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegEx];
    return [urlTest evaluateWithObject:candidate];
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
