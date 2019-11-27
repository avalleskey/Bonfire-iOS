//
//  BFLink.m
//  Pulse
//
//  Created by Austin Valleskey on 10/30/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFLink.h"
#import "NSURL+WebsiteTypeValidation.h"

@implementation BFLink

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

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err {
    BFLink *instance = [super initWithDictionary:dict error:err];
    
    instance.attributes.contentIdentifier = [self setContentIdentifier];
            
    if (instance.attributes.linkTitle.length == 0) {
        if (instance.attributes.theDescription.length > 0) {
            instance.attributes.linkTitle = instance.attributes.theDescription;
        }
        else {
            instance.attributes.linkTitle = instance.attributes.site;
        }
    }
    
    return instance;
}

- (BFLinkAttachmentContentIdentifier)setContentIdentifier {
    NSURL *url = [NSURL URLWithString:self.attributes.canonicalUrl];
    
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

- (BOOL)isSmartLink {
    return self.attributes.attribution != nil;
}

@end

@implementation BFLinkAttributes

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
