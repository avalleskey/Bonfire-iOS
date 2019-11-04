//
//  BFLinkAttachmentView.m
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFLinkAttachmentView.h"
#import "UIColor+Palette.h"
#import "NSString+Validation.h"
#import "Launcher.h"
#import "NSURL+WebsiteTypeValidation.h"
#import <SafariServices/SafariServices.h>

#define LINK_ATTACHMENT_EDGE_INSETS UIEdgeInsetsMake(12, 12, 13, 12)

// title macros
#define LINK_ATTACHMENT_TITLE_FONT [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize weight:UIFontWeightSemibold]
#define LINK_ATTACHMENT_TITLE_BOTTOM_PADDING roundf(ceilf(LINK_ATTACHMENT_TITLE_FONT.lineHeight)/7)
// detail macros
#define LINK_ATTACHMENT_DETAIL_FONT [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize-2.f weight:UIFontWeightRegular]
#define LINK_ATTACHMENT_DETAIL_BOTTOM_PADDING 3
// source macros
#define LINK_ATTACHMENT_SOURCE_FONT [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize-2.f weight:UIFontWeightRegular]

#define LINK_ATTACHMENT_DETAILS_HEIGHT ceilf(LINK_ATTACHMENT_EDGE_INSETS.top + LINK_ATTACHMENT_EDGE_INSETS.bottom + LINK_ATTACHMENT_TITLE_FONT.lineHeight + LINK_ATTACHMENT_TITLE_BOTTOM_PADDING + LINK_ATTACHMENT_DETAIL_FONT.lineHeight + LINK_ATTACHMENT_DETAIL_BOTTOM_PADDING + LINK_ATTACHMENT_SOURCE_FONT.lineHeight)
#define LINK_ATTACHMENT_DETAILS_HEIGHT_SMALL ceilf(LINK_ATTACHMENT_EDGE_INSETS.top + LINK_ATTACHMENT_EDGE_INSETS.bottom + LINK_ATTACHMENT_TITLE_FONT.lineHeight + LINK_ATTACHMENT_TITLE_BOTTOM_PADDING + LINK_ATTACHMENT_SOURCE_FONT.lineHeight)

#define LINK_ATTACHMENT_IMAGE_HEIGHT 148
#define LINK_ATTACHMENT_VIDEO_HEIGHT 148
#define LINK_ATTACHMENT_POST_HEIGHT 188

#define LINK_ATTACHMENT_SOURCE_IMAGE_VIEW_PADDING 8
#define LINK_ATTACHMENT_SOURCE_IMAGE_SIZE 32

#define LINK_ATTACHMENT_ICON_IMAGE_SIZE ceilf(LINK_ATTACHMENT_DETAILS_HEIGHT - LINK_ATTACHMENT_EDGE_INSETS.top - LINK_ATTACHMENT_EDGE_INSETS.bottom)
#define LINK_ATTACHMENT_ICON_IMAGE_VIEW_PADDING ceilf(LINK_ATTACHMENT_ICON_IMAGE_SIZE / 5)

#define LINK_ATTACHMENT_PLAY_VIEW_TAG 11

@implementation BFLinkAttachmentView

- (id)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [super setup];
    
    self.backgroundColor = [UIColor clearColor];
    
    self.imageView = [[SDAnimatedImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, LINK_ATTACHMENT_IMAGE_HEIGHT)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = true;
    self.imageView.backgroundColor = [UIColor colorWithRed:0.77 green:0.77 blue:0.79 alpha:1];
    UIView *imageSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.sourceImageView.layer.borderWidth, self.imageView.frame.size.height - self.contentView.layer.borderWidth, self.imageView.frame.size.width - (self.contentView.layer.borderWidth), self.contentView.layer.borderWidth)];
    imageSeparator.tag = 1;
    [self.imageView addSubview:imageSeparator];
    UIImageView *blankImage = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"emptyOGImageIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    blankImage.tintColor = [UIColor whiteColor];
    blankImage.center = CGPointMake(self.imageView.frame.size.width / 2, self.imageView.frame.size.height/ 2);
    blankImage.tag = 2;
    blankImage.alpha = 0.5;
    [self addPlayIconToView:self.imageView];
    [self.imageView addSubview:blankImage];
    
    [self.contentView addSubview:self.imageView];
    
    self.sourceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(LINK_ATTACHMENT_EDGE_INSETS.left, LINK_ATTACHMENT_EDGE_INSETS.top, LINK_ATTACHMENT_SOURCE_IMAGE_SIZE, LINK_ATTACHMENT_SOURCE_IMAGE_SIZE)];
    self.sourceImageView.layer.cornerRadius = 6.f;
    self.sourceImageView.hidden = true;
    self.sourceImageView.layer.masksToBounds = true;
    self.sourceImageView.layer.cornerRadius = self.sourceImageView.frame.size.height / 2;
    self.sourceImageView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.sourceImageView];
    
    self.iconImageView = [[SDAnimatedImageView alloc] initWithFrame:CGRectMake(LINK_ATTACHMENT_EDGE_INSETS.left, LINK_ATTACHMENT_EDGE_INSETS.top, LINK_ATTACHMENT_ICON_IMAGE_SIZE, LINK_ATTACHMENT_ICON_IMAGE_SIZE)];
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.iconImageView.clipsToBounds = true;
    self.iconImageView.backgroundColor = [UIColor tableViewBackgroundColor];
    self.iconImageView.layer.cornerRadius = LINK_ATTACHMENT_ICON_IMAGE_SIZE / 8;
    self.iconImageView.layer.borderWidth = HALF_PIXEL;
    [self addPlayIconToView:self.iconImageView];
    [self.contentView addSubview:self.iconImageView];
    
    // display name
    self.textLabel = [[UILabel alloc] init];
    self.textLabel.text = @"Link Title that goes on and on and on blahb allollb blah blah lah blah";
    self.textLabel.font = LINK_ATTACHMENT_TITLE_FONT;
    self.textLabel.textColor = [UIColor bonfirePrimaryColor];
    self.textLabel.textAlignment = NSTextAlignmentLeft;
    self.textLabel.numberOfLines = 1;
    self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.textLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.textLabel];
    
    // username
    self.detailTextLabel = [[UILabel alloc] init];
    self.detailTextLabel.text = @"Link detail text here";
    self.detailTextLabel.font = LINK_ATTACHMENT_DETAIL_FONT;
    self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
    self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
    self.detailTextLabel.numberOfLines = 1;
    self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.detailTextLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.detailTextLabel];
    
    // username
    self.sourceLabel = [[UILabel alloc] init];
    self.sourceLabel.text = @"BONFIRE.CAMP";
    self.sourceLabel.font = LINK_ATTACHMENT_SOURCE_FONT;
    self.sourceLabel.textAlignment = NSTextAlignmentLeft;
    self.sourceLabel.textColor = [UIColor bonfireSecondaryColor];
    self.sourceLabel.numberOfLines = 1;
    self.sourceLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.sourceLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.sourceLabel];
    
    [self bk_whenTapped:^{
        [Launcher openURL:self.link.attributes.actionUrl];
    }];
    
    if (@available(iOS 13.0, *)) {
        UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self addInteraction:interaction];
    } else {
        // Fallback on earlier versions
    }
}

- (void)addPlayIconToView:(UIView *)view {
    BOOL large = (view == self.imageView);
    
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    effectView.userInteractionEnabled = false;
    effectView.tag = LINK_ATTACHMENT_PLAY_VIEW_TAG;
    effectView.frame = CGRectMake(0, 0, 36 * (large ? 1.25 : 1), 36 * (view == self.imageView ? 1.25 : 1));
    effectView.backgroundColor = [UIColor colorWithWhite:0.94 alpha:0.3];
    effectView.layer.masksToBounds = true;
    effectView.layer.cornerRadius = effectView.frame.size.height / 2;
    
    UIImageView *playIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:large?@"playIcon_large":@"playIcon"]];
    playIcon.contentMode = UIViewContentModeScaleAspectFill;
    playIcon.center = CGPointMake(effectView.frame.size.width / 2 + 2, effectView.frame.size.height / 2);
    [effectView.contentView addSubview:playIcon];
    
    [view addSubview:effectView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self resizeHeight];
    
    CGFloat bottomY = 0;
    UIEdgeInsets contentInsets = LINK_ATTACHMENT_EDGE_INSETS;
    
    if (![self.imageView isHidden]) {
        self.imageView.frame = CGRectMake(0, 0, self.frame.size.width, LINK_ATTACHMENT_IMAGE_HEIGHT);
        UIView *imageSeparator = [self.imageView viewWithTag:1];
        imageSeparator.frame = CGRectMake(self.contentView.layer.borderWidth, self.imageView.frame.size.height - self.contentView.layer.borderWidth, self.imageView.frame.size.width - (self.contentView.layer.borderWidth * 2), self.contentView.layer.borderWidth);
        imageSeparator.backgroundColor = [UIColor colorWithCGColor:self.contentView.layer.borderColor];
        UIImageView *blankImage = [self.imageView viewWithTag:2];
        blankImage.center = CGPointMake(self.imageView.frame.size.width / 2, self.imageView.frame.size.height / 2);
        
        if (![[self.imageView viewWithTag:LINK_ATTACHMENT_PLAY_VIEW_TAG] isHidden]) {
            [self.imageView viewWithTag:LINK_ATTACHMENT_PLAY_VIEW_TAG].center = CGPointMake(self.imageView.frame.size.width / 2, self.imageView.frame.size.height / 2);
        }
        
        bottomY = self.imageView.frame.origin.y + self.imageView.frame.size.height;
    }
    
    CGFloat detailsHeight = self.frame.size.height - ([self.imageView isHidden] ? 0 : self.imageView.frame.size.height);
    if (![self.sourceImageView isHidden]) {
        // show the source image view
        CGFloat sourceImageViewX = self.frame.size.width - LINK_ATTACHMENT_SOURCE_IMAGE_SIZE - LINK_ATTACHMENT_EDGE_INSETS.right;
        self.sourceImageView.frame = CGRectMake(sourceImageViewX, self.frame.size.height - detailsHeight / 2 -  LINK_ATTACHMENT_SOURCE_IMAGE_SIZE / 2, LINK_ATTACHMENT_SOURCE_IMAGE_SIZE, LINK_ATTACHMENT_SOURCE_IMAGE_SIZE);
    }
    
    CGFloat iconSize = detailsHeight - (LINK_ATTACHMENT_EDGE_INSETS.bottom + LINK_ATTACHMENT_EDGE_INSETS.top);
    CGFloat iconPadding = ceilf(iconSize / 5);
    if (![self.iconImageView isHidden]) {
        // show the icon image view
        self.iconImageView.frame = CGRectMake(LINK_ATTACHMENT_EDGE_INSETS.left, LINK_ATTACHMENT_EDGE_INSETS.top, iconSize, iconSize);
        
        if (![[self.iconImageView viewWithTag:LINK_ATTACHMENT_PLAY_VIEW_TAG] isHidden]) {
            [self.iconImageView viewWithTag:LINK_ATTACHMENT_PLAY_VIEW_TAG].center = CGPointMake(self.iconImageView.frame.size.width / 2, self.iconImageView.frame.size.height / 2);
        }
    }
    
    CGFloat contentWidth = self.frame.size.width - (contentInsets.left + contentInsets.right) - ([self.iconImageView isHidden] ? 0 : (self.iconImageView.frame.size.width + iconPadding)) - ([self.sourceImageView isHidden] ? 0 : (self.sourceImageView.frame.size.width + LINK_ATTACHMENT_SOURCE_IMAGE_VIEW_PADDING)); // 8pt of padding between source image view and content
    CGFloat contentX = LINK_ATTACHMENT_EDGE_INSETS.left + ([self.iconImageView isHidden] ? 0 : self.iconImageView.frame.size.width + iconPadding);
    if (![self.sourceImageView isHidden]) {
        if (self.link.attributes.contentIdentifier == BFLinkAttachmentContentIdentifierNone) {
            contentX = self.sourceImageView.frame.origin.x + self.sourceImageView.frame.size.width + LINK_ATTACHMENT_SOURCE_IMAGE_VIEW_PADDING;
        }
    }
    
    // text label
    if (self.textLabel.text.length > 0) {
        self.textLabel.frame = CGRectMake(contentX, bottomY + LINK_ATTACHMENT_EDGE_INSETS.top, contentWidth, ceilf(LINK_ATTACHMENT_TITLE_FONT.lineHeight));
        bottomY = self.textLabel.frame.origin.y + self.textLabel.frame.size.height;
    }
    
    // detail text label
    if (![self.detailTextLabel isHidden] && self.detailTextLabel.text.length > 0) {
        self.detailTextLabel.frame = CGRectMake(contentX, bottomY + LINK_ATTACHMENT_TITLE_BOTTOM_PADDING, contentWidth, ceilf(self.detailTextLabel.font.lineHeight));
        bottomY = self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height;
    }
    
    // source text label
    if (self.sourceLabel.text.length > 0) {
        self.sourceLabel.frame = CGRectMake(contentX, bottomY + LINK_ATTACHMENT_DETAIL_BOTTOM_PADDING, contentWidth, ceilf(self.sourceLabel.font.lineHeight));
    }
    
    self.iconImageView.layer.borderColor = self.contentView.layer.borderColor;
}

- (void)resizeHeight {
    CGFloat height = 0;
    if (self.link) height = [BFLinkAttachmentView heightForLink:self.link width:self.frame.size.width];
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
    self.contentView.frame = self.bounds;
}

- (void)setLink:(BFLink *)link {
    if (link != _link) {
        _link = link;
        
        self.textLabel.text = link.attributes.linkTitle;
        self.detailTextLabel.text = link.attributes.theDescription;
        [self setSourceLabelText];
        
        self.contentType = [BFLinkAttachmentView contentTypeForLink:link];
        
        [self resizeHeight];
    }
}
- (void)setSourceLabelText {
    UIFont *font = LINK_ATTACHMENT_SOURCE_FONT;
    
    NSMutableAttributedString *mutableString = [NSMutableAttributedString new];
    
    if (self.link.attributes.contentIdentifier != BFLinkAttachmentContentIdentifierNone) {
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        if (self.link.attributes.contentIdentifier == BFLinkAttachmentContentIdentifierYouTubeVideo) {
            // youtube link
            attachment.image = [UIImage imageNamed:@"content_logo_youtube"];
        }
        else if (self.link.attributes.contentIdentifier == BFLinkAttachmentContentIdentifierSpotifySong ||
                 self.link.attributes.contentIdentifier == BFLinkAttachmentContentIdentifierSpotifyPlaylist) {
            // spotify song
            // https://open.spotify.com/track/47n6zyO3Uf9axGAPIY0ZOd?si=EzRVMTfJTv2qygVe1BrV4Q
            attachment.image = [UIImage imageNamed:@"content_logo_spotify"];
        }
        else if (self.link.attributes.contentIdentifier == BFLinkAttachmentContentIdentifierAppleMusicSong ||
                 self.link.attributes.contentIdentifier == BFLinkAttachmentContentIdentifierAppleMusicAlbum) {
            // apple music album
            attachment.image = [UIImage imageNamed:@"content_logo_apple_music"];
        }
        else if (self.link.attributes.contentIdentifier == BFLinkAttachmentContentIdentifierSoundCloud) {
            // soundcloud
            attachment.image = [UIImage imageNamed:@"content_logo_soundcloud"];
        }
        else if (self.link.attributes.contentIdentifier == BFLinkAttachmentContentIdentifierApplePodcast) {
            // apple podcast (episode|show)
            attachment.image = [UIImage imageNamed:@"content_logo_podcasts"];
        }
        [attachment setBounds:CGRectMake(0, roundf(font.capHeight - 14)/2.f, 14, 14)];
        
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        [mutableString appendAttributedString:attachmentString];
        
        // create spacer
        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
        [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
        
        // spacer
        [mutableString appendAttributedString:spacer];
    }
    
    NSAttributedString *text = [[NSAttributedString alloc] initWithString:self.link.attributes.site attributes:@{NSFontAttributeName: self.sourceLabel.font, NSForegroundColorAttributeName: self.sourceLabel.textColor}];
    [mutableString appendAttributedString:text];
    
    self.sourceLabel.attributedText = mutableString;
}

+ (BFLinkAttachmentContentType)contentTypeForLink:(BFLink *)link {
    BFLinkAttachmentContentIdentifier contentIdentifier = link.attributes.contentIdentifier;
    
    if (([link.attributes.format isEqualToString:POST_LINK_CUSTOM_FORMAT_VIDEO] ||
         contentIdentifier == BFLinkAttachmentContentIdentifierYouTubeVideo) &&
        link.attributes.images.count > 0) {
        // video content type
        return BFLinkAttachmentContentTypeVideo;
    }
    else if ([link.attributes.format isEqualToString:POST_LINK_CUSTOM_FORMAT_AUDIO] ||
             contentIdentifier == BFLinkAttachmentContentIdentifierSpotifySong ||
             contentIdentifier == BFLinkAttachmentContentIdentifierSpotifyPlaylist ||
             contentIdentifier == BFLinkAttachmentContentIdentifierAppleMusicSong ||
             contentIdentifier == BFLinkAttachmentContentIdentifierAppleMusicAlbum ||
             contentIdentifier == BFLinkAttachmentContentIdentifierSoundCloud ||
             contentIdentifier == BFLinkAttachmentContentIdentifierApplePodcast) {
        // audio content type
        return BFLinkAttachmentContentTypeAudio;
    }
    else if (link.attributes.images.count > 0) {
        return BFLinkAttachmentContentTypeImage;
    }
    
    return BFLinkAttachmentContentTypeGeneric;
}
//- (void)styleContentIdentifier {
//    BFLinkAttachmentContentIdentifier contentIdentifier = self.link.attributes.contentIdentifier;
//
//    UIColor *playButtonBackground = [UIColor clearColor];
//    if (contentIdentifier == BFLinkAttachmentContentIdentifierYouTubeVideo) {
//        // youtube link
//        playButtonBackground = [UIColor colorWithDisplayP3Red:1 green:0 blue:0 alpha:1];
//    }
//    else if (contentIdentifier == BFLinkAttachmentContentIdentifierSpotifySong ||
//             contentIdentifier == BFLinkAttachmentContentIdentifierSpotifyPlaylist) {
//        // spotify song
//        // https://open.spotify.com/track/47n6zyO3Uf9axGAPIY0ZOd?si=EzRVMTfJTv2qygVe1BrV4Q
//        playButtonBackground = [UIColor colorWithDisplayP3Red:0.12 green:0.84 blue:0.38 alpha:1.0];
//    }
//    else if (contentIdentifier == BFLinkAttachmentContentIdentifierAppleMusicSong ||
//             contentIdentifier == BFLinkAttachmentContentIdentifierAppleMusicAlbum) {
//        // apple music album
//        playButtonBackground = [UIColor colorWithDisplayP3Red:0.98 green:0.34 blue:0.76 alpha:1.0];
//    }
//    else if (contentIdentifier == BFLinkAttachmentContentIdentifierSoundCloud) {
//        // soundcloud
//        playButtonBackground = [UIColor colorWithDisplayP3Red:1.00 green:0.33 blue:0.00 alpha:1.0];
//    }
//    else if (contentIdentifier == BFLinkAttachmentContentIdentifierApplePodcast) {
//        // apple podcast (episode|show)
//        playButtonBackground = [UIColor colorWithDisplayP3Red:0.42 green:0.16 blue:0.81 alpha:1.0];
//    }
//
//    ((UIVisualEffectView *)[self.iconImageView viewWithTag:LINK_ATTACHMENT_PLAY_VIEW_TAG]).contentView.backgroundColor = playButtonBackground;
//}
- (void)setContentType:(BFLinkAttachmentContentType)contentType {
    if (contentType != _contentType) {
        _contentType = contentType;
    }
    
    if (contentType == BFLinkAttachmentContentTypeGeneric) {
        // small image (icon)
        self.imageView.hidden = true;
        
        self.detailTextLabel.hidden = true;
        
        self.iconImageView.hidden = false;
        [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:self.link.attributes.iconUrl] placeholderImage:[UIImage imageNamed:@"emptyLinkIcon"] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            if (error) {
                self.iconImageView.image = [UIImage imageNamed:@"emptyLinkIcon"];
                self.iconImageView.contentMode = UIViewContentModeCenter;
            }
            else {
                self.iconImageView.image = image;
                if (image.size.width < self.iconImageView.frame.size.width && image.size.height < self.iconImageView.frame.size.height) {
                    self.iconImageView.contentMode = UIViewContentModeCenter;
                }
                else {
                    self.iconImageView.contentMode = UIViewContentModeScaleAspectFill;
                }
            }
        }];
        [self.iconImageView viewWithTag:LINK_ATTACHMENT_PLAY_VIEW_TAG].hidden = true;
    }
    else if (contentType == BFLinkAttachmentContentTypeAudio) {
        // small image (cover art)
        self.imageView.hidden = true;
        
        self.detailTextLabel.hidden = false;
        
        self.iconImageView.hidden = false;
        if (self.link.attributes.images.count > 0) {
            [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:self.link.attributes.images[0]] completed:nil];
            self.iconImageView.contentMode = UIViewContentModeScaleAspectFill;
        }
        else {
            [self.iconImageView setImage:[UIImage imageNamed:@"emptyMusicLinkIcon"]];
            self.iconImageView.contentMode = UIViewContentModeCenter;
        }
        [self.iconImageView viewWithTag:LINK_ATTACHMENT_PLAY_VIEW_TAG].hidden = false;
    }
    else if (contentType == BFLinkAttachmentContentTypeImage ||
             contentType == BFLinkAttachmentContentTypeVideo) {
        // large image
        self.imageView.hidden = false;
        if (![self.imageView isHidden]) {
            NSString *imageURL = self.link.attributes.images.count > 0 ? self.link.attributes.images[0] : @"";
            [self.imageView sd_setImageWithURL:[NSURL URLWithString:imageURL] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                UIImageView *blankImage = [self.imageView viewWithTag:2];
                blankImage.hidden = !error;
            }];
        }
        [self.imageView viewWithTag:LINK_ATTACHMENT_PLAY_VIEW_TAG].hidden = !(contentType == BFLinkAttachmentContentTypeVideo);
        
        self.detailTextLabel.hidden = true;
        
        self.iconImageView.hidden = true;
    }
}

+ (CGFloat)heightForLink:(BFLink *)link width:(CGFloat)width {
    BFLinkAttachmentContentType contentType = [BFLinkAttachmentView contentTypeForLink:link];
    //BFLinkAttachmentContentIdentifier contentIdentifier = [BFLinkAttachmentView contentIdentifierForLink:link];
    
    // calculate details height
    // BOOL hasSourceImageView = (contentIdentifier != BFLinkAttachmentContentIdentifierNone);
    //CGFloat detailsContentWidth = width - (hasSourceImageView ? LINK_ATTACHMENT_SOURCE_IMAGE_SIZE +  LINK_ATTACHMENT_SOURCE_IMAGE_VIEW_PADDING : 0);
    //CGFloat titleHeight = link.attributes.metadata.title.length > 0 ? ceilf(LINK_ATTACHMENT_TITLE_FONT.lineHeight) + LINK_ATTACHMENT_TITLE_BOTTOM_PADDING : 0;
    //CGFloat descriptionHeight = link.attributes.metadata.detail.length > 0 ? ceilf(LINK_ATTACHMENT_DETAIL_FONT.lineHeight) + LINK_ATTACHMENT_DETAIL_BOTTOM_PADDING : 0;
    CGFloat detailsHeight = (contentType == BFLinkAttachmentContentTypeAudio ? LINK_ATTACHMENT_DETAILS_HEIGHT : LINK_ATTACHMENT_DETAILS_HEIGHT_SMALL);
    
    switch (contentType) {
        case BFLinkAttachmentContentTypeGeneric:
            return detailsHeight;
            break;
        case BFLinkAttachmentContentTypeAudio:
            return detailsHeight;
            break;
            
        case BFLinkAttachmentContentTypeImage:
            return detailsHeight + LINK_ATTACHMENT_IMAGE_HEIGHT;
            break;
            
        case BFLinkAttachmentContentTypeVideo:
            return detailsHeight + LINK_ATTACHMENT_VIDEO_HEIGHT;
            break;
            
        default:
            return detailsHeight;
            break;
    }
    
    return detailsHeight;
}


- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(nonnull UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location  API_AVAILABLE(ios(13.0)){
    if (self.link) {
        UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[]];
        
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:self.link.attributes.actionUrl]];
        safariVC.preferredBarTintColor = [UIColor contentBackgroundColor];
        safariVC.preferredControlTintColor = [UIColor bonfirePrimaryColor];
        
        UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:@"safari_link_preview" previewProvider:^(){return safariVC;} actionProvider:^(NSArray* suggestedAction){return menu;}];
        return configuration;
    }
    
    return nil;
}

- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    [animator addCompletion:^{
        wait(0, ^{
            if (self.link) {
                [Launcher openURL:self.link.attributes.actionUrl];
            }
        });
    }];
}

@end
