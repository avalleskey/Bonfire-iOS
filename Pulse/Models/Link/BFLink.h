//
//  BFLink.h
//  Pulse
//
//  Created by Austin Valleskey on 10/30/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFJSONModel.h"

@class Camp;

NS_ASSUME_NONNULL_BEGIN

@class BFLinkAttributes;

@interface BFLink : BFJSONModel

@property (nonatomic) NSString <Optional> *identifier;
@property (nonatomic) NSString <Optional> *type;
@property (nonatomic) BFLinkAttributes <Optional> *attributes;

- (BOOL)isSmartLink;

@end

@interface BFLinkAttributes: BFJSONModel

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
@property (nonatomic) Camp <Optional> *attribution;

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

NS_ASSUME_NONNULL_END
