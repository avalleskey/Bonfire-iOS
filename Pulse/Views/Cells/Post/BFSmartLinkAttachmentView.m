//
//  BFSmartLinkAttachmentView.m
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFSmartLinkAttachmentView.h"
#import "UIColor+Palette.h"
#import "NSString+Validation.h"
#import "Launcher.h"
#import "NSURL+WebsiteTypeValidation.h"
#import <UIFont+Poppins.h>
#import "LinkConversationsViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/UIView+WebCache.h>

#define SMART_LINK_ATTACHMENT_EDGE_INSETS UIEdgeInsetsMake(0, 12, 12, 12)

// title macros
#define SMART_LINK_ATTACHMENT_TITLE_FONT [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize weight:UIFontWeightBold]
#define SMART_LINK_ATTACHMENT_TITLE_BOTTOM_PADDING roundf(ceilf(SMART_LINK_ATTACHMENT_TITLE_FONT.lineHeight)/7)
// detail macros
#define SMART_LINK_ATTACHMENT_DETAIL_FONT [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize-2.f weight:UIFontWeightRegular]

#define SMART_LINK_ATTACHMENT_IMAGE_HEIGHT 114
#define SMART_LINK_ATTACHMENT_NO_IMAGE_HEIGHT 56

@implementation BFSmartLinkAttachmentView

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
    
//    self.backgroundColor = [UIColor contentBackgroundColor];
    
    self.imageView = [[SDAnimatedImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, SMART_LINK_ATTACHMENT_IMAGE_HEIGHT)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = true;
    self.imageView.backgroundColor = [UIColor colorWithRed:0.77 green:0.77 blue:0.79 alpha:1];
    self.imageView.sd_imageTransition = [SDWebImageTransition fadeTransition];
    UIView *imageSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.sourceImageView.layer.borderWidth, self.imageView.frame.size.height - self.contentView.layer.borderWidth, self.imageView.frame.size.width - (self.contentView.layer.borderWidth), self.contentView.layer.borderWidth)];
    imageSeparator.tag = 1;
    [self.imageView addSubview:imageSeparator];
    [self.contentView addSubview:self.imageView];
    
    self.postedInButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.postedInButton.frame = CGRectMake(SMART_LINK_ATTACHMENT_EDGE_INSETS.left, SMART_LINK_ATTACHMENT_IMAGE_HEIGHT - 16, 122, 32);
    self.postedInButton.layer.cornerRadius = self.postedInButton.frame.size.height / 2;
    self.postedInButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.postedInButton.backgroundColor = [UIColor contentBackgroundColor];
    self.postedInButton.layer.shadowOffset = CGSizeMake(0, 1);
    self.postedInButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.postedInButton.layer.shadowRadius = 2.f;
    self.postedInButton.layer.shadowOpacity = 0.12f;
    [self.postedInButton setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
    self.postedInButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
    self.postedInButton.contentEdgeInsets = UIEdgeInsetsMake(0, 32, 0, 10);
    [self.postedInButton bk_whenTapped:^{
        if (self.link.attributes.attribution) {
            [Launcher openCamp:self.link.attributes.attribution];
        }
        else if (self.link.attributes.actionUrl) {
            [Launcher openURL:self.link.attributes.actionUrl];
        }
    }];
    [self.postedInButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.postedInButton.transform = CGAffineTransformMakeScale(0.96, 0.96);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [self.postedInButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.postedInButton.transform = CGAffineTransformIdentity;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    BFAvatarView *postedInAvatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(5, 5, self.postedInButton.frame.size.height - 10, self.postedInButton.frame.size.height - 10)];
    postedInAvatarView.userInteractionEnabled = false;
    postedInAvatarView.dimsViewOnTap = false;
    postedInAvatarView.tag = 10;
    [self.postedInButton addSubview:postedInAvatarView];
    
    [self.contentView addSubview:self.postedInButton];
    
    // display name
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"Link Title that goes on and on and on blahb allollb blah blah lah blah";
    self.titleLabel.font = SMART_LINK_ATTACHMENT_TITLE_FONT;
    self.titleLabel.textColor = [UIColor bonfirePrimaryColor];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.titleLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.titleLabel];
    
    // username
    self.summaryLabel = [[UILabel alloc] init];
    self.summaryLabel.text = @"Link detail text here";
    self.summaryLabel.font = SMART_LINK_ATTACHMENT_DETAIL_FONT;
    self.summaryLabel.textAlignment = NSTextAlignmentLeft;
    self.summaryLabel.textColor = [UIColor bonfireSecondaryColor];
    self.summaryLabel.numberOfLines = 2;
    self.summaryLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.summaryLabel.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.summaryLabel];
    
    self.shareLinkButtonSeparator = [[UIView alloc] initWithFrame:CGRectMake(SMART_LINK_ATTACHMENT_EDGE_INSETS.left, 0, self.frame.size.width - (SMART_LINK_ATTACHMENT_EDGE_INSETS.left + SMART_LINK_ATTACHMENT_EDGE_INSETS.right), HALF_PIXEL)];
    self.shareLinkButtonSeparator.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.14f];
    [self.contentView addSubview:self.shareLinkButtonSeparator];
    
    self.shareLinkButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.shareLinkButton.frame = CGRectMake(0, 0, self.frame.size.width, 40);
    [self.shareLinkButton.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold]];
    [self.shareLinkButton setImage:[[UIImage imageNamed:@"postActionQuote"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.shareLinkButton setTitle:@"Quote" forState:UIControlStateNormal];
    [self.shareLinkButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 8)];
    [self.shareLinkButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
    [self.shareLinkButton bk_whenTapped:^{
        [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil quotedObject:self.link];
    }];
    [self.contentView addSubview:self.shareLinkButton];
    
    [self bk_whenTapped:^{
        [Launcher openLinkConversations:self.link withKeyboard:false];
    }];
    
    if (@available(iOS 13.0, *)) {
        UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [self addInteraction:interaction];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self resizeHeight];
    
    CGFloat bottomY = 0;
    UIEdgeInsets contentInsets = SMART_LINK_ATTACHMENT_EDGE_INSETS;
    
    if (![self.imageView isHidden]) {
        if (self.link.attributes.images.count == 0) {
            self.imageView.frame = CGRectMake(0, 0, self.frame.size.width, SMART_LINK_ATTACHMENT_NO_IMAGE_HEIGHT);
        }
        else {
            self.imageView.frame = CGRectMake(0, 0, self.frame.size.width, SMART_LINK_ATTACHMENT_IMAGE_HEIGHT);
        }
        UIView *imageSeparator = [self.imageView viewWithTag:1];
        imageSeparator.frame = CGRectMake(self.contentView.layer.borderWidth, self.imageView.frame.size.height - self.contentView.layer.borderWidth, self.imageView.frame.size.width - (self.contentView.layer.borderWidth * 2), self.contentView.layer.borderWidth);
        imageSeparator.backgroundColor = [UIColor colorWithCGColor:self.contentView.layer.borderColor];
        
        bottomY = self.imageView.frame.origin.y + self.imageView.frame.size.height;
    }
    
    if (![self.postedInButton isHidden]) {
        CGFloat postedInButtonWidth = self.postedInButton.intrinsicContentSize.width;
        
        self.postedInButton.frame = CGRectMake(contentInsets.left, bottomY - (self.postedInButton.frame.size.height / 2), postedInButtonWidth, self.postedInButton.frame.size.height);
        
        bottomY = self.postedInButton.frame.origin.y + self.postedInButton.frame.size.height;
    }
    
    // text label
    if (self.titleLabel.text.length > 0) {
        CGFloat titleHeight = ceilf([self.titleLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (contentInsets.left + contentInsets.right), self.titleLabel.font.lineHeight * 2) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: self.titleLabel.font} context:nil].size.height);
        self.titleLabel.frame = CGRectMake(contentInsets.left, bottomY + ([self.postedInButton isHidden] ? 16 : 8), self.frame.size.width - (contentInsets.left + contentInsets.right), titleHeight);
        bottomY = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height;
    }
    
    // detail text label
    if (self.summaryLabel.text.length > 0) {
        CGFloat summaryHeight = ceilf([self.summaryLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (contentInsets.left + contentInsets.right), self.summaryLabel.font.lineHeight * 2) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: self.summaryLabel.font} context:nil].size.height);
        self.summaryLabel.frame = CGRectMake(contentInsets.left, bottomY + SMART_LINK_ATTACHMENT_TITLE_BOTTOM_PADDING, self.frame.size.width - (contentInsets.left + contentInsets.right), summaryHeight);
        bottomY = self.summaryLabel.frame.origin.y + self.summaryLabel.frame.size.height;
    }
    
    if (![self.shareLinkButton isHidden]) {
        self.shareLinkButtonSeparator.frame = CGRectMake(SMART_LINK_ATTACHMENT_EDGE_INSETS.left, bottomY + SMART_LINK_ATTACHMENT_EDGE_INSETS.bottom, self.frame.size.width - (SMART_LINK_ATTACHMENT_EDGE_INSETS.left + SMART_LINK_ATTACHMENT_EDGE_INSETS.right), self.shareLinkButtonSeparator.frame.size.height);
        self.shareLinkButton.frame = CGRectMake(0, self.shareLinkButtonSeparator.frame.origin.y, self.frame.size.width, self.shareLinkButton.frame.size.height);
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    self.iconImageView.layer.borderColor = self.contentView.layer.borderColor;
    
    [self drawAttributionButton];
}

- (void)resizeHeight {
    CGFloat height = 0;
    if (self.link) height = [BFSmartLinkAttachmentView heightForSmartLink:self.link width:self.frame.size.width showActionButton:![self.shareLinkButton isHidden]];
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
    self.contentView.frame = self.bounds;
}

- (void)setLink:(BFLink *)link {
    if (link != _link) {
        _link = link;
        
        UIColor *themeColor = [UIColor bonfirePrimaryColor];
        if (self.link.attributes.attribution) {
            themeColor = [UIColor fromHex:self.link.attributes.attribution.attributes.color];
            [self.shareLinkButton setTitleColor:[UIColor fromHex:[UIColor toHex:themeColor] adjustForOptimalContrast:true] forState:UIControlStateNormal];
        }
        else {
            [self.shareLinkButton setTitleColor:themeColor forState:UIControlStateNormal];
        }
        
        self.shareLinkButton.tintColor = self.shareLinkButton.currentTitleColor;
        
        self.imageView.backgroundColor = themeColor;
        if (self.link.attributes.images.count > 0) {
            [self.imageView sd_setImageWithURL:[NSURL URLWithString:self.link.attributes.images[0]]];
        }
        else {
            self.imageView.image = nil;
        }
        
        self.titleLabel.text = link.attributes.linkTitle;
        self.summaryLabel.text = link.attributes.theDescription;
        
        self.titleLabel.textColor = [UIColor bonfirePrimaryColor];
        self.summaryLabel.textColor = [UIColor bonfireSecondaryColor];
        
        [self drawAttributionButton];
        
        Camp *attribution = self.link.attributes.attribution;
        BFAvatarView *postedInAvatarView = [self.postedInButton viewWithTag:10];
        
        if (attribution) {
            postedInAvatarView.camp = attribution;
        }
        else {
            postedInAvatarView.placeholderAvatar = true;
            postedInAvatarView.layer.masksToBounds = true;
            postedInAvatarView.layer.cornerRadius = postedInAvatarView.frame.size.height / 2;
            
            postedInAvatarView.backgroundColor = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.16];
            postedInAvatarView.imageView.tintColor = [UIColor bonfireSecondaryColor];
            if (link.attributes.iconUrl.length > 0) {
                NSString *linkId = link.identifier;
                
                [postedInAvatarView.imageView sd_cancelCurrentImageLoad];
                [postedInAvatarView.imageView sd_setImageWithURL:[NSURL URLWithString:link.attributes.iconUrl] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                    if (error && [linkId isEqualToString:link.identifier]) {
                        postedInAvatarView.imageView.image =  [[UIImage imageNamed:@"smartLinkGenericWebsiteIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    }
                }];
            }
            else {
                [postedInAvatarView.imageView sd_cancelCurrentImageLoad];
                postedInAvatarView.imageView.image =  [[UIImage imageNamed:@"smartLinkGenericWebsiteIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
        }
        
        [self resizeHeight];
    }
}

- (NSString *)hostString {
    NSURL *url = [NSURL URLWithString:self.link.attributes.canonicalUrl];
    
    if (url) {
        NSString *host = url.host;
        if (host.length > 4 && [[host substringToIndex:4] isEqualToString:@"www."]) {
            host = [host substringWithRange:NSMakeRange(4, host.length - 4)];
        }
        
        return host;
    }
    
    return @"View Site";
}

- (void)drawAttributionButton {
    Camp *attribution = self.link.attributes.attribution;
    
    // create camp attributed string
    NSMutableAttributedString *creatorString = [[NSMutableAttributedString alloc] init];
    
    UIFont *font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
    NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
    [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
    
    NSString *attributionString = [self hostString];
    if (attribution) {
        attributionString = attribution.attributes.title;
        if (attribution.attributes.identifier.length > 0) {
            attributionString = [@"#" stringByAppendingString:attribution.attributes.identifier];
        }
    }
    
    NSMutableAttributedString *attributedAttributionString = [[NSMutableAttributedString alloc] initWithString:(attributionString ? attributionString : @"")];
    [attributedAttributionString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfirePrimaryColor] range:NSMakeRange(0, attributedAttributionString.length)];
    [attributedAttributionString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, attributedAttributionString.length)];
    
    [creatorString appendAttributedString:attributedAttributionString];
    
    if (attribution) {
        if ([attribution isPrivate]) {
            // spacer
            [creatorString appendAttributedString:spacer];
            
            NSTextAttachment *lockAttachment = [[NSTextAttachment alloc] init];
            lockAttachment.image = [self colorImage:[UIImage imageNamed:@"details_label_private"] color:[UIColor bonfirePrimaryColor]];
            
            CGFloat attachmentHeight = MIN(ceilf(font.lineHeight * 0.7), lockAttachment.image.size.height);
            CGFloat attachmentWidth = attachmentHeight * (lockAttachment.image.size.width / lockAttachment.image.size.height);
            
            [lockAttachment setBounds:CGRectMake(0, roundf(font.capHeight - attachmentHeight)/2.f, attachmentWidth, attachmentHeight)];
                        
            NSAttributedString *lockAttachmentString = [NSAttributedString attributedStringWithAttachment:lockAttachment];
            [creatorString appendAttributedString:lockAttachmentString];
        }
        else if ([attribution.attributes.display.format isEqualToString:CAMP_DISPLAY_FORMAT_CHANNEL]) {
            // spacer
            [creatorString appendAttributedString:spacer];
            
            NSTextAttachment *sourceAttachment = [[NSTextAttachment alloc] init];
            sourceAttachment.image = [self colorImage:[UIImage imageNamed:@"details_label_source"] color:[UIColor bonfirePrimaryColor]];
            
            CGFloat attachmentHeight = MIN(ceilf(font.lineHeight * 0.7), sourceAttachment.image.size.height);
            CGFloat attachmentWidth = attachmentHeight * (sourceAttachment.image.size.width / sourceAttachment.image.size.height);
            
            [sourceAttachment setBounds:CGRectMake(0, roundf(font.capHeight - attachmentHeight)/2.f, attachmentWidth, attachmentHeight)];
            
            NSAttributedString *lockAttachmentString = [NSAttributedString attributedStringWithAttachment:sourceAttachment];
            [creatorString appendAttributedString:lockAttachmentString];
        }
    }
    else if (![self.shareLinkButton isHidden]) {
        NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
        [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
        [creatorString appendAttributedString:spacer];
        
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        attachment.image = [UIImage imageNamed:@"headerDetailDisclosureIcon"];
        [attachment setBounds:CGRectMake(0, roundf(font.capHeight - (attachment.image.size.height * .75))/2.f, attachment.image.size.width * .75, attachment.image.size.height * .75)];
        NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
        [creatorString appendAttributedString:attachmentString];
    }
    
    [self.postedInButton setAttributedTitle:creatorString forState:UIControlStateNormal];
}

- (CGFloat)height {
    return [BFSmartLinkAttachmentView heightForSmartLink:self.link width:self.frame.size.width showActionButton:![self.shareLinkButton isHidden]];
}

+ (CGFloat)heightForSmartLink:(BFLink *)link width:(CGFloat)width showActionButton:(BOOL)showActionButton {
    CGFloat height;
    if (link.attributes.images.count == 0) {
        height = SMART_LINK_ATTACHMENT_NO_IMAGE_HEIGHT;
    }
    else {
        height = SMART_LINK_ATTACHMENT_IMAGE_HEIGHT;
    }
    
    CGFloat postedInButtonHeight = (32 / 2);
    height += postedInButtonHeight;
    
    UIEdgeInsets contentInsets = SMART_LINK_ATTACHMENT_EDGE_INSETS;
    
    if (link.attributes.linkTitle.length > 0) {
        CGFloat titleHeight = ceilf([link.attributes.linkTitle boundingRectWithSize:CGSizeMake(width - (contentInsets.left + contentInsets.right), SMART_LINK_ATTACHMENT_TITLE_FONT.lineHeight * 2) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: SMART_LINK_ATTACHMENT_TITLE_FONT} context:nil].size.height);
        height += ((postedInButtonHeight == 0 ? 16 : 8) + titleHeight);
    }
    
    if (link.attributes.theDescription.length > 0) {
        CGFloat summaryHeight = ceilf([link.attributes.theDescription boundingRectWithSize:CGSizeMake(width - (contentInsets.left + contentInsets.right), SMART_LINK_ATTACHMENT_DETAIL_FONT.lineHeight * 2) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: SMART_LINK_ATTACHMENT_DETAIL_FONT} context:nil].size.height);
        height += ((link.attributes.linkTitle.length == 0 ? 16 : SMART_LINK_ATTACHMENT_TITLE_BOTTOM_PADDING) + summaryHeight);
    }
    
    return height + contentInsets.bottom + (showActionButton ? 40 : 0); // 40 == action height
}

- (nullable UIContextMenuConfiguration *)contextMenuInteraction:(nonnull UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location  API_AVAILABLE(ios(13.0)){
    if (self.link) {
        UIMenu *menu = [UIMenu menuWithTitle:@"" children:@[]];
        
        LinkConversationsViewController *p = [[LinkConversationsViewController alloc] init];
        p.link = self.link;
        p.isPreview = true;
        
        NSString *themeCSS;
        if (p.link.attributes.attribution != nil) {
            themeCSS = [p.link.attributes.attribution.attributes.color lowercaseString];
        }
        p.theme = (themeCSS.length == 0) ? [UIColor bonfireGrayWithLevel:800] : [UIColor fromHex:themeCSS];
                
        UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:@"smart_link_preview" previewProvider:^(){return p;} actionProvider:^(NSArray* suggestedAction){return menu;}];
        return configuration;
    }
    
    return nil;
}

- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator  API_AVAILABLE(ios(13.0)){
    [animator addCompletion:^{
        wait(0, ^{
            if (self.link) {
                [Launcher openLinkConversations:self.link withKeyboard:false];
            }
        });
    }];
}

- (UIImage *)colorImage:(UIImage *)image color:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGContextDrawImage(context, rect, image.CGImage);
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [color setFill];
    CGContextFillRect(context, rect);
    
    
    UIImage *coloredImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return coloredImage;
}

@end
