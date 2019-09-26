/**
 * This file is generated using the remodel generation script.
 * The name of the input file is PostAttributes.value
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "Camp.h"
#import "BFMedia.h"
#import "BFHostedVersions.h"
#import "BFContext.h"

NS_ASSUME_NONNULL_BEGIN

@protocol Post;
@protocol PostAttachmentsMedia;
@protocol PostEntity;

@class Post;
@class PostAttributes;
@class PostStatus;
@class PostStatusDisplay;
@class PostStatusDisplayFormat;
@class PostCounts;
@class PostSummaries;
@class PostDetails;
@class PostDetails;
@class PostAttachments;
@class PostAttachmentsMedia;
@class PostAttachmentsMediaAtributes;
@class PostAttachmentsMediaAtributesRawMedia;
@class PostAttachmentsLink;
@class PostAttachmentsLinkAttributes;
@class PostEntity;

@interface Post : JSONModel

@property (nonatomic) NSString <Optional> *identifier;

// Used when creating a post
@property (nonatomic) NSString <Optional> *tempId;

@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) PostAttributes <Optional> *attributes;

- (BOOL)hasLinkAttachment;
- (BOOL)hasUserAttachment;
- (BOOL)hasCampAttachment;

- (void)createTempWithMessage:(NSString *)message media:(BFMedia *)media postedIn:(Camp * _Nullable)postedIn parentId:(NSString *)parentId;
+ (NSString *_Nullable)trimString:(NSString *_Nullable)string;
- (BOOL)isEmojiPost;

@property (nonatomic) NSString <Optional> *prevCursor;
@property (nonatomic) NSString <Optional> *nextCursor;

@end

@interface PostAttributes : JSONModel

@property (nonatomic) PostDetails <Optional> *details;
@property (nonatomic) PostStatus <Optional> *status;
@property (nonatomic) PostSummaries <Optional> *summaries;
@property (nonatomic) BFContext <Optional> *context;

@end

@interface PostDetails : JSONModel

@property (nonatomic) NSString <Optional> *message;
@property (nonatomic) PostAttachments <Optional> *attachments;
@property (nonatomic) NSArray <PostEntity *> <PostEntity, Optional> *entities;
@property (nonatomic) NSString <Optional> *url;
@property (nonatomic) BOOL hasMedia;
@property (nonatomic) NSArray <Optional> *media;
@property (nonatomic) User <Optional> *creator;
// parent post ID --> used for Post replies
@property (nonatomic) NSString <Optional> *parentId;
@property (nonatomic) NSString <Optional> *parentUsername;
@property (nonatomic) NSArray <Post *> <Post, Optional> * _Nullable replies;

@property (nonatomic) BOOL emojify;

- (NSString *)simpleMessage;

@end

@interface PostStatus : JSONModel

@property (nonatomic) Camp <Optional> *postedIn;
@property (nonatomic) NSString <Optional> *createdAt;
@property (nonatomic) PostStatusDisplay <Optional> *display;

@end

@interface PostStatusDisplay : JSONModel

extern NSString * const POST_DISPLAY_CREATOR_CAMP;
extern NSString * const POST_DISPLAY_CREATOR_USER;
@property (nonatomic) NSString <Optional> *creator;
@property (nonatomic) PostStatusDisplayFormat <Optional> *format;

@end

@interface PostStatusDisplayFormat : JSONModel

extern NSString * const POST_DISPLAY_FORMAT_ICEBREAKER;
@property (nonatomic) NSString <Optional> *type;

@end

@interface PostCounts : JSONModel

@property (nonatomic) NSInteger replies;
@property (nonatomic) NSInteger live;

@end

@interface PostSummaries : JSONModel

@property (nonatomic) NSArray <Post *> <Post, Optional> *replies;
@property (nonatomic) PostCounts <Optional> *counts;

@end

@interface PostAttachments : JSONModel

@property (nonatomic) NSArray <PostAttachmentsMedia *> <PostAttachmentsMedia, Optional> *media;
@property (nonatomic) PostAttachmentsLink <Optional> *link;
@property (nonatomic) Camp <Optional> *camp;
@property (nonatomic) User <Optional> *user;

@end

@interface PostAttachmentsMedia : JSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) PostAttachmentsMediaAtributes <Optional> *attributes;

@end

@interface PostAttachmentsMediaAtributes : JSONModel

typedef enum {
    PostAttachmentMediaTypeImage = 1,
    PostAttachmentMediaTypeGIF = 2,
    PostAttachmentMediaTypeVideo = 3,
    PostAttachmentMediaTypeText = 4,
    PostAttachmentMediaTypeLink = 5
} PostAttachmentMediaType;

@property (nonatomic) PostAttachmentMediaType type;
@property (nonatomic) NSString <Optional> *createdAt;
@property (nonatomic) NSString <Optional> *expiresAt;
@property (nonatomic) BFHostedVersions <Optional> *hostedVersions;
@property (nonatomic) PostAttachmentsMediaAtributesRawMedia <Optional> *rawMedia;
@property (nonatomic) NSArray <Optional> *owners;

@end

@interface PostAttachmentsMediaAtributesRawMedia : JSONModel

@property (nonatomic) NSString <Optional> *value;

@end

@interface PostAttachmentsLink : JSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) PostAttachmentsLinkAttributes <Optional> *attributes;

@end

@interface PostAttachmentsLinkAttributes : JSONModel

/**
 The full URL that metadata was retrieved from. What they paste.
 */
@property (nonatomic) NSString <Optional> *actionUrl;

/**
 The URL that metadata was retrieved from. Where the conversations collect.
   This is used in setting the custom content identifier property.
 */
@property (nonatomic) NSString <Optional> *canonicalUrl;

/**
 An icon for the URL. In most cases, this is the URL's favicon.
 */
@property (nonatomic) NSString <Optional> *iconUrl;

/**
 An image for the URL. In most cases, this is the URL's OG image property value.
 */
@property (nonatomic) NSArray <Optional> *images;

/**
 Site name to display. In most cases, this will be a pretty-fied URL. If available,
 this will use the URL's OG site property value.
 */
@property (nonatomic) NSString <Optional> *site;

/**
 A title for the URL. In most cases, this is the URL's <title> attribute.
 */
@property (nonatomic) NSString <Optional> *linkTitle;

/**
 A detail text for the URL. This can be anything from the URL's OG
 description to the first few lines of the URL's body.
 */
@property (nonatomic) NSString <Optional> *theDescription;

/**
 In the case that a bot posts inside a For Everyone Camp, a postedIn
  camp will be provided, so users can discover more posts like it.
 */
@property (nonatomic) Camp <Optional> *postedIn;

/**
 Always fallback to website.
 
 Supported custom formats:
 - playable:audio
 - playable:video.
 */
extern NSString * const POST_LINK_CUSTOM_FORMAT_AUDIO;
extern NSString * const POST_LINK_CUSTOM_FORMAT_VIDEO;
@property (nonatomic) NSString <Optional> *format;

/**
 Content identifiers are a set of custom supported link sources.
 This allows us to style/format the link differently in special instances.
 */
typedef enum {
    BFLinkAttachmentContentIdentifierNone,
    BFLinkAttachmentContentIdentifierYouTubeVideo, // works
    BFLinkAttachmentContentIdentifierSpotifySong, // works
    BFLinkAttachmentContentIdentifierSpotifyPlaylist, // works
    BFLinkAttachmentContentIdentifierAppleMusicSong, // works
    BFLinkAttachmentContentIdentifierAppleMusicAlbum, // works
    BFLinkAttachmentContentIdentifierSoundCloud, // works
    BFLinkAttachmentContentIdentifierApplePodcast,
    // BFLinkAttachmentContentIdentifierTwitterPost,
    // BFLinkAttachmentContentIdentifierRedditPost
} BFLinkAttachmentContentIdentifier;
/**
 Internal value for the content identifier.
 */
@property (nonatomic) BFLinkAttachmentContentIdentifier contentIdentifier;

@end

@interface PostEntity : JSONModel

extern NSString * const POST_ENTITY_TYPE_PROFILE;
extern NSString * const POST_ENTITY_TYPE_CAMP;
extern NSString * const POST_ENTITY_TYPE_URL;
@property (nonatomic) NSString <Optional> *type;

@property (nonatomic) NSString <Optional> *displayText;
@property (nonatomic) NSString <Optional> *expandedUrl;
@property (nonatomic) NSString <Optional> *actionUrl;
@property (nonatomic) NSArray <Optional> *indices;

@end

NS_ASSUME_NONNULL_END
