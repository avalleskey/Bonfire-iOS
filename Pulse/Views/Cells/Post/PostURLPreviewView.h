//
//  PostURLPreviewView.h
//  Pulse
//
//  Created by Austin Valleskey on 11/11/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Post.h"

#define URL_PREVIEW_DETAILS_HEIGHT 72

#define URL_PREVIEW_IMAGE_HEIGHT 148
#define URL_PREVIEW_VIDEO_HEIGHT 148
#define URL_PREVIEW_POST_HEIGHT 188

#define REGEX_YOUTUBE @"^(http(s)??\\:\\/\\/)?(www\\.)?((youtube\\.com\\/watch\?v=)|(youtu.be\\/))([a-zA-Z0-9\\-_])+"
#define REGEX_SPOTIFY_SONG @"^(https:\\/\\/open.spotify.com\\/track\\/)([a-zA-Z0-9]+)(.*)$"
#define REGEX_SPOTIFY_PLAYLIST @"^(https:\\/\\/open.spotify.com\\/user\\/([a-zA-Z0-9]+)\\/playlist\\/)([a-zA-Z0-9]+)(.*)$"
#define REGEX_APPLE_MUSIC @"^https:\\/\\/itunes.apple.com\\/([a-zA-Z]+)\\/album\\/([-_a-zA-Z0-9]+)\\/([a-zA-Z0-9]+)(.*)$"
#define REGEX_SOUNDCLOUD @"((https:\\/\\/)|(http:\\/\\/)|(www.)|(m\\.)|(\\s))+(soundcloud.com\\/)+[a-zA-Z0-9\\-\\.]+(\\/)+[a-zA-Z0-9\\-\\.]+"
#define REGEX_APPLE_PODCAST @"^https:\\/\\/itunes.apple.com\\/(?:[a-zA-Z]+)\\/podcast\\/(?:[-_a-zA-Z0-9]+)\\/id(?:[a-zA-Z0-9]+)(?:\\?(?:[a-zA-Z0-9]{1,}\\=[a-zA-Z0-9]{1,}(?:\\?|\\&)){0,}(?:\\i\\=(\\d{13})))?"

NS_ASSUME_NONNULL_BEGIN

@protocol PostURLPreviewViewDelegate <NSObject>

- (void)URLPreviewWillChangeFrameTo:(CGRect)newFrame;

@end

@interface PostURLPreviewView : UIView

@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL editable;

@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSURL *url;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *sourceLogoImageView;

@property (nonatomic, strong) UIView *detailsView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UILabel *hostLabel;

@property (nonatomic, weak) id <PostURLPreviewViewDelegate> delegate;

typedef enum {
    URLPreviewContentTypeNone,
    URLPreviewContentTypeGeneral,
    URLPreviewContentTypeImage,
    URLPreviewContentTypeVideo,
    URLPreviewContentTypeAudio,
    // URLPreviewContentTypePost (included in future update)
} URLPreviewContentType;
@property (nonatomic) URLPreviewContentType contentType;

typedef enum {
    URLPreviewContentIdentifierNone,
    // URLPreviewContentTypeVideo
    URLPreviewContentIdentifierYouTubeVideo, // works
    // URLPreviewContentTypeAudio
    URLPreviewContentIdentifierSpotifySong, // works
    URLPreviewContentIdentifierSpotifyPlaylist, // works 
    URLPreviewContentIdentifierAppleMusic, // works
    URLPreviewContentIdentifierSoundCloud, // works
    URLPreviewContentIdentifierApplePodcast,
    // URLPreviewContentTypePost (included in future update)
    // URLPreviewContentIdentifierTwitterPost,
    // URLPreviewContentIdentifierRedditPost
} URLPreviewContentIdentifier;
@property (nonatomic) URLPreviewContentIdentifier contentIdentifier;

- (CGFloat)height;

@end

NS_ASSUME_NONNULL_END
