//
//  MediumCampCardCell.h.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "MediumCampCardCell.h"
#import "UIColor+Palette.h"
#import <HapticHelper/HapticHelper.h>
#import <UIView+WebCache.h>

#import "Launcher.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

#define padding 16

#define CAMP_TITLE_FONT [UIFont systemFontOfSize:26.f weight:UIFontWeightHeavy]
#define CAMP_DETAIL_FONT [UIFont systemFontOfSize:16.f weight:UIFontWeightBold]
#define CAMP_BIO_FONT [UIFont systemFontOfSize:12.f weight:UIFontWeightRegular]

@implementation MediumCampCardCell

@synthesize camp = _camp;

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
    self.camp = [[Camp alloc] init];
    
    self.backgroundColor = [UIColor cardBackgroundColor];
    
    self.backgroundImageView = [UIImageView new];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundImageView.alpha = 1;//0;
    self.backgroundImageView.clipsToBounds = true;
    [self.contentView addSubview:self.backgroundImageView];
    
    self.campAvatarContainer = [[UIView alloc] initWithFrame:CGRectMake(16, 24, 88, 88)];
    self.campAvatarContainer.userInteractionEnabled = false;
    self.campAvatarContainer.backgroundColor = [UIColor whiteColor];
    self.campAvatarContainer.layer.cornerRadius = self.campAvatarContainer.frame.size.width * .5;
    self.campAvatarContainer.layer.masksToBounds = false;
    self.campAvatarContainer.layer.borderWidth = HALF_PIXEL;
    self.campAvatarContainer.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.08].CGColor;
    self.campAvatarContainer.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.06].CGColor;
    self.campAvatarContainer.layer.shadowOffset = CGSizeMake(0, 1.5);
    self.campAvatarContainer.layer.shadowRadius = roundf((1.5) * 0.75);
    self.campAvatarContainer.layer.shadowOpacity = 1;
    self.campAvatarContainer.layer.shouldRasterize = true;
    self.campAvatarContainer.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    self.campAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(6, 6, 76, 76)];
    self.campAvatar.center = CGPointMake(self.campAvatarContainer.frame.size.width / 2, self.campAvatarContainer.frame.size.height / 2);
    [self.campAvatarContainer addSubview:self.campAvatar];
    [self.contentView addSubview:self.campAvatarContainer];
    
    self.campAvatarReasonView = [[UIView alloc] init];
    self.campAvatarReasonView.hidden = true;
    self.campAvatarReasonView.backgroundColor = [UIColor bonfireDetailColor];
    self.campAvatarReasonView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.campAvatarReasonView.layer.shadowOffset = CGSizeMake(0, 1);
    self.campAvatarReasonView.layer.shadowRadius = 1.f;
    self.campAvatarReasonView.layer.shadowOpacity = 0.12;
    self.campAvatarReasonView.frame = CGRectMake(self.campAvatarContainer.frame.origin.x + self.campAvatarContainer.frame.size.width - 28, self.campAvatarContainer.frame.origin.y, 28, 28);
    self.campAvatarReasonView.layer.cornerRadius = self.campAvatarReasonView.frame.size.height / 2;
    self.campAvatarReasonView.layer.masksToBounds = false;
    [self.contentView addSubview:self.campAvatarReasonView];
    
    self.campAvatarReasonLabel = [[UILabel alloc] initWithFrame:self.campAvatarReasonView.bounds];
    self.campAvatarReasonLabel.textAlignment = NSTextAlignmentCenter;
    self.campAvatarReasonLabel.font = [UIFont systemFontOfSize:10.f weight:UIFontWeightSemibold];
    self.campAvatarReasonLabel.text = @"🔥";
    [self.campAvatarReasonView addSubview:self.campAvatarReasonLabel];
    
    self.campAvatarReasonImageView = [[UIImageView alloc] initWithFrame:self.campAvatarReasonView.bounds];
    self.campAvatarReasonImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.campAvatarReasonImageView.hidden = true;
    self.campAvatarReasonImageView.layer.cornerRadius = self.campAvatarReasonView.layer.cornerRadius;
    self.campAvatarReasonImageView.layer.masksToBounds = true;
    [self.campAvatarReasonView addSubview:self.campAvatarReasonImageView];
    
    self.campTitleLabel = [[MarqueeLabel alloc] initWithFrame:CGRectMake(16, 118, self.frame.size.width - 32, ceilf(CAMP_TITLE_FONT.lineHeight)) rate:(self.frame.size.width/7) andFadeLength:12.f];
    self.campTitleLabel.font = CAMP_TITLE_FONT;
    self.campTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.campTitleLabel.numberOfLines = 0;
    self.campTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.campTitleLabel.animationDelay = 2.f;
    self.campTitleLabel.trailingBuffer = 16.f;
    self.campTitleLabel.textColor = [UIColor whiteColor];
    self.campTitleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.campTitleLabel.layer.shadowOpacity = 0.16f;
    self.campTitleLabel.layer.shadowOffset = CGSizeMake(0, 0.5);
    self.campTitleLabel.layer.shadowRadius = 2.f;
    [self.contentView addSubview:self.campTitleLabel];
    
    self.campTagLabel = [[MarqueeLabel alloc] initWithFrame:CGRectMake(12, self.campTitleLabel.frame.origin.y + self.campTitleLabel.frame.size.height + 2, self.frame.size.width - 24, ceilf(CAMP_DETAIL_FONT.lineHeight)) rate:(self.frame.size.width/7) andFadeLength:6.f];
    self.campTagLabel.font = CAMP_DETAIL_FONT;
    self.campTagLabel.textAlignment = NSTextAlignmentCenter;
    self.campTagLabel.numberOfLines = 0;
    self.campTagLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.campTagLabel.animationDelay = 2.f;
    self.campTagLabel.trailingBuffer = 16.f;
    self.campTagLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.campTagLabel.layer.shadowOpacity = 0.16f;
    self.campTagLabel.layer.shadowOffset = CGSizeMake(0, 0.5);
    self.campTagLabel.layer.shadowRadius = 2.f;
    self.campTagLabel.textColor = [UIColor whiteColor];
    [self.contentView addSubview:self.campTagLabel];
    
    self.campDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, self.campTagLabel.frame.origin.y + self.campTagLabel.frame.size.height + 4, self.frame.size.width - 32, ceilf(CAMP_BIO_FONT.lineHeight) * 2)];
    self.campDescriptionLabel.font = CAMP_BIO_FONT;
    self.campDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.campDescriptionLabel.numberOfLines = 2;
    self.campDescriptionLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.campDescriptionLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    self.campDescriptionLabel.layer.shadowOpacity = 0.16f;
    self.campDescriptionLabel.layer.shadowOffset = CGSizeMake(0, 0.5);
    self.campDescriptionLabel.layer.shadowRadius = 2.f;
    self.campDescriptionLabel.contentMode = UIViewContentModeTop;
    self.campDescriptionLabel.textColor = [UIColor colorWithWhite:1 alpha:0.75];
    [self.contentView addSubview:self.campDescriptionLabel];
    
    [self initMembersSnapshotView];
}

- (void)initMembersSnapshotView {
    // need to initialize the snapshot view
    self.membersSnaphotView = [[UIView alloc] init];
    self.membersSnaphotView.frame = CGRectMake(0, 0, self.frame.size.width, 32);
    [self.contentView addSubview:self.membersSnaphotView];
    
    self.memberCountButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.membersSnaphotView.frame.size.height, self.membersSnaphotView.frame.size.height)];
    self.memberCountButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16f];
    self.memberCountButton.layer.cornerRadius = self.memberCountButton.frame.size.height / 2;
    [self.memberCountButton setImage:[[UIImage imageNamed:@"details_label_members"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.memberCountButton.tintColor = [UIColor whiteColor];
    [self.memberCountButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.memberCountButton setTitle:@"24" forState:UIControlStateNormal];
    self.memberCountButton.userInteractionEnabled = false;
    [self.memberCountButton.titleLabel setFont:[UIFont systemFontOfSize:12.f weight:UIFontWeightSemibold]];
    [self.memberCountButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 0)];
    [self.memberCountButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 4)];
    [self.membersSnaphotView addSubview:self.memberCountButton];
    
    self.shareButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.membersSnaphotView.frame.size.height, self.membersSnaphotView.frame.size.height)];
    self.shareButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16f];
    self.shareButton.layer.cornerRadius = self.shareButton.frame.size.height / 2;
    [self.shareButton setImage:[[UIImage imageNamed:@"campCardShareIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.shareButton.tintColor = [UIColor whiteColor];
    [self.shareButton bk_addEventHandler:^(id sender) {
        [HapticHelper generateFeedback:FeedbackType_Selection];
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.shareButton.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:^(BOOL finished) {
            
        }];
    } forControlEvents:UIControlEventTouchDown];
    [self.shareButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.shareButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:^(BOOL finished) {
            
        }];
    } forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit];
    [self.shareButton bk_whenTapped:^{
        [Launcher shareCamp:self.camp];
    }];
    [self.membersSnaphotView addSubview:self.shareButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.backgroundImageView.frame = CGRectMake(0, 0, self.contentView.frame.size.width, 80);
    
    self.campAvatarContainer.center = CGPointMake(self.contentView.frame.size.width / 2, self.campAvatarContainer.center.y);
    
    if (![self.campAvatarReasonView isHidden]) {
        self.campAvatarReasonView.frame = CGRectMake(self.campAvatarContainer.frame.origin.x + self.campAvatarContainer.frame.size.width - self.campAvatarReasonView.frame.size.width - 2, self.campAvatarContainer.frame.origin.y + self.campAvatarContainer.frame.size.height - self.campAvatarReasonView.frame.size.height - 2, self.campAvatarReasonView.frame.size.width, self.campAvatarReasonView.frame.size.height);
    }
    
    CGFloat contentPadding = 16;
    CGFloat contentWidth = self.frame.size.width - (contentPadding * 2);
    
    // title
    self.campTitleLabel.frame = CGRectMake(24, self.campTitleLabel.frame.origin.y, self.frame.size.width - (24 * 2), self.campTitleLabel.frame.size.height);

    if (![self.campTagLabel isHidden]) {
        self.campTagLabel.frame = CGRectMake(contentPadding, self.campTagLabel.frame.origin.y, contentWidth, self.campTagLabel.frame.size.height);
    }
    
    if (![self.campDescriptionLabel isHidden]) {
        self.campDescriptionLabel.frame = CGRectMake(16, self.campDescriptionLabel.frame.origin.y, self.frame.size.width - (16 * 2), self.campDescriptionLabel.frame.size.height);
    }
    
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
    self.contentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
    
    self.membersSnaphotView.frame = CGRectMake(contentPadding, self.contentView.frame.size.height - contentPadding - 32, self.contentView.frame.size.width - (contentPadding * 2), 32);
    self.memberCountButton.frame = CGRectMake(0, 0, ceilf(self.memberCountButton.intrinsicContentSize.width) + (12 * 2) + self.memberCountButton.titleEdgeInsets.left, self.membersSnaphotView.frame.size.height);
    self.shareButton.frame = CGRectMake(self.membersSnaphotView.frame.size.width - self.membersSnaphotView.frame.size.height, 0, self.membersSnaphotView.frame.size.height, self.membersSnaphotView.frame.size.height);
}

- (void)setHighlighted:(BOOL)highlighted {
    if (highlighted) {
        [HapticHelper generateFeedback:FeedbackType_Selection];
        
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.transform = CGAffineTransformMakeScale(0.92, 0.92);
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)setCamp:(Camp *)camp {
    if (camp != _camp) {
        _camp = camp;
        
        UIColor *themeColor = [UIColor fromHex:camp.attributes.color];
        UIColor *adjustedThemeColor = [UIColor fromHex:camp.attributes.color adjustForOptimalContrast:true];
                        
        self.campAvatar.camp = camp;
        
        self.tintColor = themeColor;
        self.backgroundImageView.backgroundColor = themeColor;
//        [self.backgroundImageView sd_cancelCurrentImageLoad];
//        if (camp.attributes.media.avatar.suggested.url.length > 0) {
//            [self.backgroundImageView sd_setImageWithURL:[NSURL URLWithString:camp.attributes.media.avatar.suggested.url] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
//                if (image && !error) {
//                    dispatch_async(dispatch_get_main_queue(), ^(void) {
//                        self.backgroundImageView.image = image;
//
//                        if (cacheType == SDImageCacheTypeNone) {
//                            self.backgroundImageView.alpha = 0;
//                            [UIView animateWithDuration:1.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
//                                self.backgroundImageView.alpha = 0.08;
//                            } completion:nil];
//                        }
//                        else {
//                            self.backgroundImageView.alpha = 0.08;
//                        }
//                    });
//                }
//            }];
//        }
//        else {
//            self.backgroundImageView.image = nil;
//        }
        
        // adjust colors to theme
        UIColor *foreground = [UIColor bonfirePrimaryColor];//[UIColor highContrastForegroundForBackground:self.contentView.backgroundColor];
        UIColor *shadowColor = [UIColor clearColor];//[UIColor highContrastForegroundForBackground:foreground];
        self.campTitleLabel.textColor = foreground;
        self.memberCountButton.backgroundColor = [foreground colorWithAlphaComponent:0.08];
        [self.memberCountButton setTitleColor:foreground forState:UIControlStateNormal];
        self.memberCountButton.tintColor = foreground;
        self.shareButton.backgroundColor = self.memberCountButton.backgroundColor;
        self.shareButton.tintColor = foreground;
        self.campDescriptionLabel.textColor = [foreground colorWithAlphaComponent:0.75];
        self.campTitleLabel.layer.shadowColor = shadowColor.CGColor;
        self.campTagLabel.layer.shadowColor = shadowColor.CGColor;
        self.campDescriptionLabel.layer.shadowColor = shadowColor.CGColor;
        
        NSString *campTitle;
        if (camp.attributes.title.length > 0) {
            campTitle = camp.attributes.title;
        }
        else if (camp.attributes.identifier.length > 0) {
            campTitle = [NSString stringWithFormat:@"@%@", camp.attributes.identifier];
        }
        else {
            campTitle = @"Secret Camp";
        }
        NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:campTitle attributes:@{NSFontAttributeName:CAMP_TITLE_FONT}];
        if ([camp isVerified]) {
            NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
            [spacer addAttribute:NSFontAttributeName value:CAMP_TITLE_FONT range:NSMakeRange(0, spacer.length)];
            [displayNameAttributedString appendAttributedString:spacer];
            
            // verified icon ☑️
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [UIImage imageNamed:@"verifiedIcon_small"];
            
            CGFloat attachmentHeight = MIN(ceilf(CAMP_TITLE_FONT.lineHeight), attachment.image.size.height);
            CGFloat attachmentWidth = attachmentHeight * (attachment.image.size.width / attachment.image.size.height);
           
            [attachment setBounds:CGRectMake(0, roundf(CAMP_TITLE_FONT.capHeight - attachmentHeight)/2.25f, attachmentWidth, attachmentHeight)];
                        
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [displayNameAttributedString appendAttributedString:attachmentString];
        }
        self.campTitleLabel.attributedText = displayNameAttributedString;
        
        UIColor *detailTextColor = [foreground colorWithAlphaComponent:0.75];
        if (camp.attributes.identifier.length > 0) {
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
            
            NSAttributedString *detailAttributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"#%@", camp.attributes.identifier] attributes:@{NSForegroundColorAttributeName: adjustedThemeColor, NSFontAttributeName: CAMP_DETAIL_FONT}];
            [attributedString appendAttributedString:detailAttributedText];

            self.campTagLabel.attributedText = attributedString;
        }
        else if ([camp isPrivate]) {
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self privateIconAttributedStringWithColor:nil]];
                       
            NSAttributedString *detailAttributedText = [[NSAttributedString alloc] initWithString:@" Private" attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor], NSFontAttributeName: [UIFont systemFontOfSize:CAMP_DETAIL_FONT.pointSize weight:UIFontWeightBold]}];
            [attributedString appendAttributedString:detailAttributedText];
            
            self.campTagLabel.attributedText = attributedString;
        }
        else if ([camp isFeed]) {
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
            
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [self colorImage:[UIImage imageNamed:@"details_label_feed"] color:detailTextColor];
            CGFloat attachmentHeight = MIN(ceilf(self.campTagLabel.font.lineHeight * 0.7), attachment.image.size.height);
            CGFloat attachmentWidth = attachmentHeight * (attachment.image.size.width / attachment.image.size.height);
            [attachment setBounds:CGRectMake(0, roundf(self.campTagLabel.font.capHeight - attachmentHeight)/2.f + 0.5, attachmentWidth, attachmentHeight)];
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [attributedString appendAttributedString:attachmentString];
                       
            NSAttributedString *detailAttributedText = [[NSAttributedString alloc] initWithString:@" Feed" attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor], NSFontAttributeName: [UIFont systemFontOfSize:CAMP_DETAIL_FONT.pointSize weight:UIFontWeightBold]}];
            [attributedString appendAttributedString:detailAttributedText];
            
            self.campTagLabel.attributedText = attributedString;
        }
        else {
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self publicIconAttributedStringWithColor:detailTextColor]];
                       
            NSAttributedString *detailAttributedText = [[NSAttributedString alloc] initWithString:@" Public" attributes:@{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor], NSFontAttributeName: [UIFont systemFontOfSize:CAMP_DETAIL_FONT.pointSize weight:UIFontWeightBold]}];
            [attributedString appendAttributedString:detailAttributedText];
            
            self.campTagLabel.attributedText = attributedString;
        }
        self.campTagLabel.hidden = self.campTagLabel.attributedText.length == 0;
        
        self.campDescriptionLabel.text = camp.attributes.theDescription;
        [self.campDescriptionLabel sizeToFit];
                
        BOOL useText = false;
        BOOL useImage = false;

        NSDateComponents *components;
        if (camp.attributes.createdAt.length > 0) {
            NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
                [inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
            NSDate *date = [inputFormatter dateFromString:camp.attributes.createdAt];
            
            NSUInteger unitFlags = NSCalendarUnitDay;
            NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            components = [calendar components:unitFlags fromDate:date toDate:[NSDate new] options:0];
        }
        
        if (camp.attributes.summaries.counts.scoreIndex > 0) {
            useImage = true;
            self.campAvatarReasonLabel.text = @"";
            self.campAvatarReasonImageView.image = [UIImage imageNamed:@"hotIcon"];
            self.campAvatarReasonImageView.backgroundColor = [UIColor fromHex:camp.scoreColor];
        }
        else if (components && [components day] < 7) {
            useImage = true;
            self.campAvatarReasonImageView.image = [UIImage imageNamed:@"newIcon"];
        }
        if (useImage) {
            self.campAvatarReasonImageView.contentMode = UIViewContentModeScaleAspectFill;
        }
        
        self.campAvatarReasonView.hidden = !useText && !useImage;
        self.campAvatarReasonImageView.hidden = !useImage;
        self.campAvatarReasonLabel.hidden = !useText;
        
        NSString *memberString = [camp memberCountTieredRepresentation];
        
        [self.memberCountButton setTitle:memberString forState:UIControlStateNormal];
    }
}

- (NSAttributedString *)publicIconAttributedStringWithColor:(UIColor * _Nullable)tintColor {
    if (!tintColor) tintColor = [UIColor bonfireSecondaryColor];
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [self colorImage:[UIImage imageNamed:@"details_label_public"] color:tintColor];
    CGFloat attachmentHeight = MIN(ceilf(self.campTagLabel.font.lineHeight * 0.75), attachment.image.size.height);
    CGFloat attachmentWidth = attachmentHeight * (attachment.image.size.width / attachment.image.size.height);
    [attachment setBounds:CGRectMake(0, roundf(self.campTagLabel.font.capHeight - attachmentHeight)/2.f + 0.5, attachmentWidth, attachmentHeight)];
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    
    return attachmentString;
}

- (NSAttributedString *)privateIconAttributedStringWithColor:(UIColor * _Nullable)tintColor {
    if (!tintColor) tintColor = [UIColor bonfireSecondaryColor];
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [self colorImage:[UIImage imageNamed:@"details_label_private"] color:tintColor];
    CGFloat attachmentHeight = MIN(ceilf(self.campTagLabel.font.lineHeight * 0.75), attachment.image.size.height);
    CGFloat attachmentWidth = attachmentHeight * (attachment.image.size.width / attachment.image.size.height);
    [attachment setBounds:CGRectMake(0, roundf(self.campTagLabel.font.capHeight - attachmentHeight)/2.f + 0.5, attachmentWidth, attachmentHeight)];
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    
    return attachmentString;
}

- (NSAttributedString *)sourceIconAttributedStringWithColor:(UIColor * _Nullable)tintColor {
    if (!tintColor) tintColor = [UIColor bonfireSecondaryColor];
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [self colorImage:[UIImage imageNamed:@"mini_source_icon"] color:tintColor];
    CGFloat attachmentHeight = MIN(ceilf(self.campTagLabel.font.lineHeight * 1.1), attachment.image.size.height);
    CGFloat attachmentWidth = attachmentHeight * (attachment.image.size.width / attachment.image.size.height);
    [attachment setBounds:CGRectMake(0, roundf(self.campTagLabel.font.capHeight - attachmentHeight)/2.f + 0.5, attachmentWidth, attachmentHeight)];
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    
    return attachmentString;
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
