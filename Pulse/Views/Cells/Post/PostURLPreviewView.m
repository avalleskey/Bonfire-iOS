//
//  PostURLPreviewView.m
//  Pulse
//
//  Created by Austin Valleskey on 11/11/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "PostURLPreviewView.h"
#import <ObjectiveGumbo/ObjectiveGumbo.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIColor+Palette.h"

@implementation PostURLPreviewView

- (id)init {
    self  = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {    
    self.backgroundColor = [UIColor colorWithRed:0.95 green:0.96 blue:0.97 alpha:1.0];
    self.layer.cornerRadius = 12.f;
    self.layer.masksToBounds = true;
    self.layer.borderWidth = 1.f;
    self.layer.borderColor = [UIColor colorWithRed:0.93 green:0.94 blue:0.96 alpha:1.0].CGColor;
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    [self addSubview:self.spinner];
    
    self.contentView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.contentView];
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, URL_PREVIEW_IMAGE_HEIGHT)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = true;
    self.imageView.backgroundColor = [UIColor whiteColor];
    self.imageView.layer.borderWidth = 1.f;
    self.imageView.layer.borderColor = self.layer.borderColor;
    [self.contentView addSubview:self.imageView];
    
    self.detailsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, URL_PREVIEW_DETAILS_HEIGHT)];
    [self.contentView addSubview:self.detailsView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 16)];
    self.titleLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1];
    self.titleLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
    self.titleLabel.numberOfLines = 1;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.detailsView addSubview:self.titleLabel];
    
    self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 14)];
    self.descriptionLabel.textColor = [UIColor colorWithRed:0.49 green:0.54 blue:0.60 alpha:1.0];
    self.descriptionLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightRegular];
    self.descriptionLabel.numberOfLines = 1;
    self.descriptionLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.detailsView addSubview:self.descriptionLabel];
    
    self.hostLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 4, self.frame.size.width, 12)];
    self.hostLabel.textColor = [UIColor colorWithRed:0.49 green:0.54 blue:0.60 alpha:1.0];
    self.hostLabel.font = [UIFont systemFontOfSize:10.f weight:UIFontWeightRegular];
    self.hostLabel.numberOfLines = 1;
    self.hostLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.detailsView addSubview:self.hostLabel];
    
    self.sourceLogoImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.detailsView.frame.size.width - 32 - 12, 20, 32, 32)];
    self.sourceLogoImageView.contentMode = UIViewContentModeCenter;
    self.sourceLogoImageView.layer.cornerRadius = self.sourceLogoImageView.frame.size.height / 2;
    self.sourceLogoImageView.layer.masksToBounds = true;
    [self.detailsView addSubview:self.sourceLogoImageView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.hidden = self.loading;
    self.spinner.hidden = !self.loading;
    
    if (self.loading) {
        self.spinner.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    }
    else {
        self.contentView.frame = self.bounds;
    }
}

- (void)setUrl:(NSURL *)url {
    if (url != _url) {
        _url = url;
        
        if (url.absoluteString.length > 0) {
            self.loading = true;
            
            self.contentIdentifier = URLPreviewContentIdentifierNone;
            self.contentType = URLPreviewContentTypeGeneral;
            self.imageView.hidden = false;
            
            [self validateContentIdentifier];
            
            [self fetchData];
        }
        else {
            // reset
            self.imageView.hidden = true;
            self.imageView.image = nil;
            
            self.sourceLogoImageView.hidden = true;
            self.sourceLogoImageView.image = nil;
            
            self.titleLabel.text = @"";
            self.descriptionLabel.text = @"";
            
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, URL_PREVIEW_DETAILS_HEIGHT);
        }
    }
}

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    if (loading) {
        self.spinner.hidden = false;
        if (!self.spinner.isAnimating) {
            [self.spinner startAnimating];
        }
        
        [self layoutSubviews];
    }
    else {
        self.spinner.hidden = true;
        [self.spinner stopAnimating];
    }
}

- (void)fetchData {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *title;
        NSString *description;
        NSURL *image_url;
        NSURL *favicon_url;
        NSString *host;
        
        OGNode *data = [ObjectiveGumbo parseDocumentWithUrl:self.url];
        NSArray *metaTags = [data elementsWithTag:GUMBO_TAG_META];
        for (OGElement *element in metaTags) {
            NSString *property = [element.attributes objectForKey:@"property"];
            NSString *name = [element.attributes objectForKey:@"name"];
            NSString *content = [element.attributes objectForKey:@"content"];
            
            if (property && content) {
                if ([property isEqualToString:@"og:title"]) {
                    title = content;
                }
                else if ([property isEqualToString:@"og:description"]) {
                    description = content;
                }
                else if ([property isEqualToString:@"og:image"]) {
                    image_url = [NSURL URLWithString:content relativeToURL:self.url];
                }
            }
            
            if (!description && name && [name isEqualToString:@"description"]) {
                description = content;
            }
            
            if (title && description && image_url) break;
        }
        if (title.length == 0) {
            NSArray *titleTags = [data elementsWithTag:GUMBO_TAG_TITLE];
            for (OGElement *element in titleTags) {
                title = element.text;
                break;
            }
        }
        if (image_url.absoluteString.length == 0) {
            NSArray *linkTags = [data elementsWithTag:GUMBO_TAG_LINK];
            for (OGElement *element in linkTags) {
                NSString *rel = [element.attributes objectForKey:@"rel"];
                NSString *href = [element.attributes objectForKey:@"href"];
                
                if (rel && ([rel isEqualToString:@"icon"] || [[rel componentsSeparatedByString:@" "] containsObject:@"icon"]) && href) {
                    favicon_url = [NSURL URLWithString:href relativeToURL:self.url];
                    continue;
                }
                
                if (rel && ([rel isEqualToString:@"apple-touch-icon-precomposed"] || [rel isEqualToString:@"apple-touch-icon"]) && href) {
                    favicon_url = [NSURL URLWithString:href relativeToURL:self.url];
                    break;
                }
            }
            if (favicon_url.absoluteString.length == 0) {
                favicon_url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/favicon.ico", self.url.host]];
            }
        }
        
        // remove line breaks
        title = [[title componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
        description = [[description componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
        // remove leading whitespace
        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        description = [description stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        NSString *shortenedUrl = [self.url.host lowercaseString];
        host = shortenedUrl;
        if (self.contentIdentifier != URLPreviewContentIdentifierNone) {
            // URLPreviewContentIdentifierSpotifySong
            if (self.contentIdentifier == URLPreviewContentIdentifierSpotifySong) {
                NSString *inputTitle = title;
                NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:@"(.{1,}), a song by (.{1,}) on Spotify" options:NSRegularExpressionCaseInsensitive error:nil];
                if ([regEx numberOfMatchesInString:inputTitle options:0 range:NSMakeRange(0, [inputTitle length])] > 0) {
                    NSArray *matches = [regEx matchesInString:inputTitle options:0 range:NSMakeRange(0, [inputTitle length])];
                    for (NSTextCheckingResult *match in matches) {
                        //NSRange matchRange = [match range];
                        if ([match numberOfRanges] > 1) {
                            NSRange matchRange = [match rangeAtIndex:1];
                            NSString *matchString = [inputTitle substringWithRange:matchRange];
                            NSLog(@"match string 1: %@", matchString);
                            title = (matchString.length > 0 ? matchString : inputTitle);
                        }
                        if ([match numberOfRanges] > 2) {
                            NSRange matchRange = [match rangeAtIndex:2];
                            NSString *matchString = [inputTitle substringWithRange:matchRange];
                            NSLog(@"match string 2  : %@", matchString);
                            description = (matchString.length > 0 ? matchString : description);
                        }
                    }
                }
                host = @"SPOTIFY SONG";
            }
            else if (self.contentIdentifier == URLPreviewContentIdentifierSpotifyPlaylist) {
                // TODO: RegEx to pull out the artist name
                NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:@"(.{1,}), a playlist by (.{1,}) on Spotify" options:NSRegularExpressionCaseInsensitive error:nil];
                if ([regEx numberOfMatchesInString:title options:0 range:NSMakeRange(0, [title length])] > 0) {
                    NSArray *matches = [regEx matchesInString:title options:0 range:NSMakeRange(0, [title length])];
                    for (NSTextCheckingResult *match in matches) {
                        //NSRange matchRange = [match range];
                        NSLog(@"match: %@", match);
                        if ([match numberOfRanges] > 1) {
                            NSRange matchRange = [match rangeAtIndex:1];
                            NSString *matchString = [title substringWithRange:matchRange];
                            NSLog(@"match string:: %@", matchString);
                            title = (matchString.length > 0 ? matchString : title);
                            break;
                        }
                    }
                }
                host = @"SPOTIFY PLAYLIST";
            }
            else if (self.contentIdentifier == URLPreviewContentIdentifierAppleMusic) {
                // TODO: RegEx to pull out the artist name
                NSString *inputTitle = title;
                NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:@"(.{1,}) by (.{1,})" options:NSRegularExpressionCaseInsensitive error:nil];
                if ([regEx numberOfMatchesInString:inputTitle options:0 range:NSMakeRange(0, [inputTitle length])] > 0) {
                    NSArray *matches = [regEx matchesInString:inputTitle options:0 range:NSMakeRange(0, [inputTitle length])];
                    for (NSTextCheckingResult *match in matches) {
                        //NSRange matchRange = [match range];
                        NSLog(@"number of ranges: %lu", (unsigned long)[match numberOfRanges]);
                        if ([match numberOfRanges] > 1) {
                            NSRange matchRange = [match rangeAtIndex:1];
                            NSString *matchString = [inputTitle substringWithRange:matchRange];
                            NSLog(@"match string 1: %@", matchString);
                            title = (matchString.length > 0 ? matchString : inputTitle);
                        }
                        if ([match numberOfRanges] > 2) {
                            NSRange matchRange = [match rangeAtIndex:2];
                            NSString *matchString = [inputTitle substringWithRange:matchRange];
                            NSLog(@"match string 2  : %@", matchString);
                            description = (matchString.length > 0 ? matchString : description);
                        }
                    }
                }
                host = @" MUSIC SONG";
            }
            else if (self.contentIdentifier == URLPreviewContentIdentifierApplePodcast) {
                // 1) determine if it's a show or episode
                BOOL isShow = false;
                BOOL isEpisode = false;
                
                NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:REGEX_APPLE_PODCAST options:NSRegularExpressionCaseInsensitive error:nil];
                if ([regEx numberOfMatchesInString:self.url.absoluteString options:0 range:NSMakeRange(0, [self.url.absoluteString length])] > 0) {
                    NSArray *matches = [regEx matchesInString:self.url.absoluteString options:0 range:NSMakeRange(0, [self.url.absoluteString length])];

                    for (NSTextCheckingResult *match in matches) {
                        //NSRange matchRange = [match range];
                        NSLog(@"number of ranges: %lu", (unsigned long)[match numberOfRanges]);

                        for (NSInteger i = 1; i < [match numberOfRanges]; i++) {
                            NSRange matchRange = [match rangeAtIndex:i];
                            if (matchRange.location != NSNotFound && matchRange.location + matchRange.length <= self.url.absoluteString.length) {
                                NSString *matchString = [self.url.absoluteString substringWithRange:matchRange];
                                NSLog(@"match string(%li)::: %@", (long)i, matchString);
                                isEpisode = true;
                            }
                            else {
                                isShow = true;
                            }
                        }
                    }
                }
                
                NSLog(@"isShow: %@", isShow ? @"YES" : @"NO");
                NSLog(@"isEpisode: %@", isEpisode ? @"YES" : @"NO");
                
                NSString *inputTitle = title;
                if (isEpisode) {
                    // (.{1,})
                    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:@"\"(.{1,})\" from (.{1,}) by (.{1,}) on Apple Podcasts" options:NSRegularExpressionCaseInsensitive error:nil];
                    if ([regEx numberOfMatchesInString:inputTitle options:0 range:NSMakeRange(0, [inputTitle length])] > 0) {
                        NSArray *matches = [regEx matchesInString:inputTitle options:0 range:NSMakeRange(0, [inputTitle length])];
                        for (NSTextCheckingResult *match in matches) {
                            //NSRange matchRange = [match range];
                            NSLog(@"number of ranges: %lu", (unsigned long)[match numberOfRanges]);
                            if ([match numberOfRanges] > 1) {
                                // podcast episode name
                                NSRange matchRange = [match rangeAtIndex:1];
                                NSString *matchString = [inputTitle substringWithRange:matchRange];
                                NSLog(@"match string 1: %@", matchString);
                                title = (matchString.length > 0 ? matchString : inputTitle);
                            }
                            if ([match numberOfRanges] > 2) {
                                // podcast show name
                                NSRange matchRange = [match rangeAtIndex:2];
                                NSString *matchString = [inputTitle substringWithRange:matchRange];
                                NSLog(@"match string 2  : %@", matchString);
                                description = (matchString.length > 0 ? matchString : description);
                            }
                        }
                    }
                    host = @"APPLE PODCASTS EPISODE";
                }
                else if (isShow) {
                    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:@"(.{1,}) by (.{1,}) on Apple Podcasts" options:NSRegularExpressionCaseInsensitive error:nil];
                    if ([regEx numberOfMatchesInString:inputTitle options:0 range:NSMakeRange(0, [inputTitle length])] > 0) {
                        NSArray *matches = [regEx matchesInString:inputTitle options:0 range:NSMakeRange(0, [inputTitle length])];
                        for (NSTextCheckingResult *match in matches) {
                            //NSRange matchRange = [match range];
                            NSLog(@"number of ranges: %lu", (unsigned long)[match numberOfRanges]);
                            if ([match numberOfRanges] > 1) {
                                // podcast show name
                                NSRange matchRange = [match rangeAtIndex:1];
                                NSString *matchString = [inputTitle substringWithRange:matchRange];
                                NSLog(@"match string 1: %@", matchString);
                                title = (matchString.length > 0 ? matchString : inputTitle);
                            }
                            if ([match numberOfRanges] > 2) {
                                // podcast show creator
                                NSRange matchRange = [match rangeAtIndex:2];
                                NSString *matchString = [inputTitle substringWithRange:matchRange];
                                NSLog(@"match string 2  : %@", matchString);
                                description = (matchString.length > 0 ? matchString : description);
                            }
                        }
                    }
                    host = @"APPLE PODCASTS SHOW";
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loading = false;
            
            NSString *shortenedUrl = [self.url.host lowercaseString];
            self.titleLabel.text = (title.length > 0 ? title : shortenedUrl);
            self.descriptionLabel.text = description;
            self.hostLabel.text = (host.length > 0 ? host : [shortenedUrl uppercaseString]);
            self.hostLabel.frame = CGRectMake(self.hostLabel.frame.origin.x, (self.descriptionLabel.text.length == 0 ? self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 4 : self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 4), self.hostLabel.frame.size.width, self.hostLabel.frame.size.height);
            
            if (image_url) {
                [self.imageView sd_setImageWithURL:image_url];
                self.imageView.contentMode = UIViewContentModeScaleAspectFill;
            }
            else if (favicon_url) {
                self.imageView.contentMode = UIViewContentModeCenter;
                [self.imageView sd_setImageWithURL:favicon_url placeholderImage:[UIImage imageNamed:@"emptyLinkIcon"] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    if (error) {
                        self.imageView.contentMode = UIViewContentModeCenter;
                        self.imageView.image = [UIImage imageNamed:@"emptyLinkIcon"];
                    }
                    else {
                        if (image.size.width < self.imageView.frame.size.width && image.size.height < self.imageView.frame.size.height) {
                            self.imageView.contentMode = UIViewContentModeCenter;
                        }
                        else {
                            self.imageView.contentMode = UIViewContentModeScaleAspectFill;
                        }
                        self.imageView.image = image;
                    }
                }];
            }
            
            if (self.contentIdentifier == URLPreviewContentIdentifierNone) {
                // determine if it's basic, favicon or image
                if (image_url) {
                    NSLog(@"contentType: URLPreviewContentTypeImage");
                    self.contentType = URLPreviewContentTypeImage;
                }
                else if (favicon_url) {
                    NSLog(@"contentType: URLPreviewContentTypeGeneral 1");
                    NSLog(@"favicon_url: %@", favicon_url.absoluteString);
                    self.contentType = URLPreviewContentTypeGeneral;
                }
                else {
                    NSLog(@"contentType: URLPreviewContentTypeGeneral 2");
                    self.contentType = URLPreviewContentTypeGeneral;
                }
            }
            
            CGRect newFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, [self height]);
            [self.delegate URLPreviewWillChangeFrameTo:newFrame];
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.frame = newFrame;
            } completion:nil];
            
            [self layoutSubviews];
        });
        
        NSLog(@"title: %@", title);
        NSLog(@"description: %@", description);
        NSLog(@"image_url: %@", image_url);
    });
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformMakeScale(0.92, 0.92);
    } completion:nil];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)validateContentIdentifier {
    if ([self URLMatches:REGEX_YOUTUBE]) {
        // youtube link
        NSLog(@"youtube link!");
        self.contentIdentifier = URLPreviewContentIdentifierYouTubeVideo;
        self.contentType = URLPreviewContentTypeVideo;
        NSLog(@"contentType: URLPreviewContentTypeVideo");
        
        return;
    }
    if ([self URLMatches:REGEX_SPOTIFY_SONG]) {
        // https://open.spotify.com/track/47n6zyO3Uf9axGAPIY0ZOd?si=EzRVMTfJTv2qygVe1BrV4Q
        // spotify song
        NSLog(@"spotify song!");
        self.contentIdentifier = URLPreviewContentIdentifierSpotifySong;
        self.contentType = URLPreviewContentTypeAudio;
        NSLog(@"contentType: URLPreviewContentTypeAudio");
        
        return;
    }
    if ([self URLMatches:REGEX_SPOTIFY_PLAYLIST]) {
        // spotify playlist
        // https://open.spotify.com/user/1248735265/playlist/7cu21dpm13nXHNu8BNp5qd?si=MzdEuaKPSveJWdKk2DcUDw
        NSLog(@"spotify playlist!");
        self.contentIdentifier = URLPreviewContentIdentifierSpotifyPlaylist;
        self.contentType = URLPreviewContentTypeAudio;
        NSLog(@"contentType: URLPreviewContentTypeAudio");
        
        return;
    }
    if ([self URLMatches:REGEX_APPLE_MUSIC]) {
        // apple music album
        NSLog(@"apple music!");
        self.contentIdentifier = URLPreviewContentIdentifierAppleMusic;
        self.contentType = URLPreviewContentTypeAudio;
        NSLog(@"contentType: URLPreviewContentTypeAudio");
        
        return;
    }
    if ([self URLMatches:REGEX_SOUNDCLOUD]) {
        // soundcloud
        NSLog(@"soundcloud!");
        self.contentIdentifier = URLPreviewContentIdentifierSoundCloud;
        self.contentType = URLPreviewContentTypeAudio;
        NSLog(@"contentType: URLPreviewContentTypeAudio");
        
        return;
    }
    if ([self URLMatches:REGEX_APPLE_PODCAST]) {
        // apple podcast (episode|show)
        
        NSLog(@"apple podcast episode or show!");
        self.contentIdentifier = URLPreviewContentIdentifierApplePodcast;
        self.contentType = URLPreviewContentTypeAudio;
        NSLog(@"contentType: URLPreviewContentTypeAudio");
        
        return;
    }
    /*
    if ([self URLMatches:@"^https?:\\/\\/twitter\\.com\\/(?:#!\\/)?(\\w+)\\/status(?:es)?\\/(\\d+)(?:\\/.*)?$"]) {
        // twitter post
        // TODO: Broken regex
        NSLog(@"twitter post!");
        self.contentIdentifier = URLPreviewContentIdentifierTwitterPost;
        self.contentType = URLPreviewContentTypePost;
        NSLog(@"contentType: URLPreviewContentTypePost");
        
        return;
    }
    if ([self URLMatches:@"^http(s)?(.+)reddit\\.com/r/([^/]+)/(?=(comments\\/(.+)))"]) {
        // reddit post
        NSLog(@"reddit post!");
        self.contentIdentifier = URLPreviewContentIdentifierRedditPost;
        self.contentType = URLPreviewContentTypePost;
        NSLog(@"contentType: URLPreviewContentTypePost");
        
        return;
    }*/
    
    NSLog(@"no match ;(");
    self.contentIdentifier = URLPreviewContentIdentifierNone;
}

- (BOOL)URLMatches:(NSString *)pattern {
    NSRegularExpression *regEx = [[NSRegularExpression alloc] initWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSUInteger matches = [regEx numberOfMatchesInString:self.url.absoluteString options:0 range:NSMakeRange(0, [self.url.absoluteString length])];
    return (matches == 1);
}

- (CGFloat)height {
    if (!self.loading) {
        switch (self.contentType) {
            case URLPreviewContentTypeGeneral:
            case URLPreviewContentTypeAudio:
                return URL_PREVIEW_DETAILS_HEIGHT;
                break;
                
            case URLPreviewContentTypeImage:
                return URL_PREVIEW_DETAILS_HEIGHT + URL_PREVIEW_IMAGE_HEIGHT;
                break;
                
            case URLPreviewContentTypeVideo:
                return URL_PREVIEW_DETAILS_HEIGHT + URL_PREVIEW_VIDEO_HEIGHT;
                break;
                
//            case URLPreviewContentTypePost:
//                return URL_PREVIEW_POST_HEIGHT;
//                break;
                
            default:
                return URL_PREVIEW_DETAILS_HEIGHT;
                break;
        }
    }
    
    return URL_PREVIEW_DETAILS_HEIGHT;
}

- (void)setContentType:(URLPreviewContentType)contentType {
    if (contentType != _contentType) {
        _contentType = contentType;
        
        // show/hide views
        self.imageView.hidden = false; // (contentType == URLPreviewContentTypePost);
//        self.imageView.layer.borderWidth = (contentType == URLPreviewContentTypeImage || contentType == URLPreviewContentTypeVideo ? 1.f : 0);
        self.sourceLogoImageView.hidden = (self.contentIdentifier == URLPreviewContentIdentifierNone);
        
        if (!self.imageView.isHidden) {
            // resize based on content type
            CGRect frame = CGRectMake(0, 0, self.frame.size.width, 0);
            if (contentType == URLPreviewContentTypeGeneral || contentType == URLPreviewContentTypeAudio) {
                frame.origin = CGPointMake(12, 12);
                frame.size = CGSizeMake(URL_PREVIEW_DETAILS_HEIGHT - (frame.origin.y*2), URL_PREVIEW_DETAILS_HEIGHT - (frame.origin.y*2));
                self.imageView.layer.cornerRadius = 6.f;
            }
            else if (contentType == URLPreviewContentTypeImage) {
                frame.size = CGSizeMake(self.frame.size.width, URL_PREVIEW_IMAGE_HEIGHT);
                self.imageView.layer.cornerRadius = 0;
            }
            else if (contentType == URLPreviewContentTypeVideo) {
                frame.size = CGSizeMake(self.frame.size.width, URL_PREVIEW_VIDEO_HEIGHT);
                self.imageView.layer.cornerRadius = 0;
            }
//            else if (contentType == URLPreviewContentTypePost) {
//                frame.size = CGSizeMake(24, 24);
//                frame.origin = CGPointMake(12, self.frame.size.height / 2 - frame.size.height / 2);
//            }
            
            self.imageView.frame = frame;
        }
        
        // set details rect and content logo
        CGRect detailsRect = CGRectMake(12, 0, self.frame.size.width - 24, URL_PREVIEW_DETAILS_HEIGHT);
        if (contentType == URLPreviewContentTypeGeneral || contentType == URLPreviewContentTypeAudio) {
            detailsRect.origin.x = 72;
            detailsRect.size = CGSizeMake(self.frame.size.width - detailsRect.origin.x - 12, URL_PREVIEW_DETAILS_HEIGHT);
        }
        else if (contentType == URLPreviewContentTypeImage) {
            detailsRect.origin.y = URL_PREVIEW_IMAGE_HEIGHT;
        }
        else if (contentType == URLPreviewContentTypeVideo) {
            detailsRect.origin.y = URL_PREVIEW_VIDEO_HEIGHT;
        }
//        else if (contentType == URLPreviewContentTypePost) {
//            detailsRect.origin.y = URL_PREVIEW_POST_HEIGHT - detailsRect.size.height;
//        }
        self.detailsView.frame = detailsRect;
        if (!self.sourceLogoImageView.isHidden) {
            self.sourceLogoImageView.frame = CGRectMake(self.detailsView.frame.size.width - self.sourceLogoImageView.frame.size.width, self.detailsView.frame.size.height / 2 - self.sourceLogoImageView.frame.size.height / 2, self.sourceLogoImageView.frame.size.width, self.sourceLogoImageView.frame.size.height);
        }
        CGFloat detailTextWidth = (self.sourceLogoImageView.isHidden ? self.detailsView.frame.size.width : self.sourceLogoImageView.frame.origin.x - 8);
        self.titleLabel.frame = CGRectMake(0, 12, detailTextWidth, self.titleLabel.frame.size.height);
        self.descriptionLabel.frame = CGRectMake(0, self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 2, detailTextWidth, self.descriptionLabel.frame.size.height);
        self.hostLabel.frame = CGRectMake(0, (self.descriptionLabel.text.length == 0 ? self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 4 : self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 4), detailTextWidth, self.hostLabel.frame.size.height);
    }
}

- (void)setContentIdentifier:(URLPreviewContentIdentifier)contentIdentifier {
    if (contentIdentifier != _contentIdentifier) {
        _contentIdentifier = contentIdentifier;
        
        switch (contentIdentifier) {
            case URLPreviewContentIdentifierYouTubeVideo:
                self.sourceLogoImageView.image = [UIImage imageNamed:@"content_logo_youtube"];
                break;
                
            case URLPreviewContentIdentifierSpotifySong:
            case URLPreviewContentIdentifierSpotifyPlaylist:
                self.sourceLogoImageView.image = [UIImage imageNamed:@"content_logo_spotify"];
                break;
                
            case URLPreviewContentIdentifierAppleMusic:
                self.sourceLogoImageView.image = [UIImage imageNamed:@"content_logo_apple_music"];
                break;
                
            case URLPreviewContentIdentifierSoundCloud:
                self.sourceLogoImageView.image = [UIImage imageNamed:@"content_logo_soundcloud"];
                break;
                
            case URLPreviewContentIdentifierApplePodcast:
                self.sourceLogoImageView.image = [UIImage imageNamed:@"content_logo_podcasts"];
                break;
//
//            case URLPreviewContentIdentifierTwitterPost:
//                self.sourceLogoImageView.image = [UIImage imageNamed:@"content_logo_twitter"];
//                break;
//
//            case URLPreviewContentIdentifierRedditPost:
//                self.sourceLogoImageView.image = [UIImage imageNamed:@"content_logo_reddit"];
//                break;
                
            default:
                self.sourceLogoImageView.hidden = true;
                self.sourceLogoImageView.image = nil;
                break;
        }
    }
}

@end
