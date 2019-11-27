//
//  SmallMediumCampCardCell.h.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SmallMediumCampCardCell.h"
#import "UIColor+Palette.h"
#import <HapticHelper/HapticHelper.h>

#define padding 16

@implementation SmallMediumCampCardCell

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
    self.layer.cornerRadius = 15.f;
    self.layer.masksToBounds = false;
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08f].CGColor;
    self.layer.shadowOpacity = 1.f;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowRadius = 1.f;
    self.contentView.layer.cornerRadius = self.layer.cornerRadius;
    self.contentView.layer.masksToBounds = true;
    self.layer.shouldRasterize = true;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    self.campHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 46)];
    self.campHeaderView.backgroundColor = [UIColor bonfireOrange];
    [self.contentView addSubview:self.campHeaderView];
    
    self.campAvatarContainer = [[UIView alloc] initWithFrame:CGRectMake(20, 9, 54, 54)];
    self.campAvatarContainer.userInteractionEnabled = false;
    self.campAvatarContainer.backgroundColor = [UIColor cardBackgroundColor];
    self.campAvatarContainer.layer.cornerRadius = self.campAvatarContainer.frame.size.width * .5;
    self.campAvatarContainer.layer.masksToBounds = false;
    self.campAvatarContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.campAvatarContainer.layer.shadowOffset = CGSizeMake(0, 1);
    self.campAvatarContainer.layer.shadowRadius = 1.f;
    self.campAvatarContainer.layer.shadowOpacity = 0.1;
    
    self.campAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(3, 3, 48, 48)];
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
    self.campAvatarReasonView.frame = CGRectMake(self.campAvatarContainer.frame.origin.x + self.campAvatarContainer.frame.size.width - 24, self.campAvatarContainer.frame.origin.y, 24, 24);
    self.campAvatarReasonView.layer.cornerRadius = self.campAvatarReasonView.frame.size.height / 2;
    self.campAvatarReasonView.layer.masksToBounds = false;
    [self.contentView addSubview:self.campAvatarReasonView];
    
    self.campAvatarReasonLabel = [[UILabel alloc] initWithFrame:self.campAvatarReasonView.bounds];
    self.campAvatarReasonLabel.textAlignment = NSTextAlignmentCenter;
    self.campAvatarReasonLabel.font = [UIFont systemFontOfSize:10.f weight:UIFontWeightSemibold];
    self.campAvatarReasonLabel.text = @"🔥";
    [self.campAvatarReasonView addSubview:self.campAvatarReasonLabel];
    
    self.campAvatarReasonImageView = [[UIImageView alloc] initWithFrame:self.campAvatarReasonView.bounds];
    self.campAvatarReasonImageView.contentMode = UIViewContentModeCenter;
    self.campAvatarReasonImageView.hidden = true;
    [self.campAvatarReasonView addSubview:self.campAvatarReasonImageView];
    
    self.campTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, self.campAvatarContainer.frame.origin.y + self.campAvatarContainer.frame.size.height + 4, self.frame.size.width - 24, 14)];
    self.campTitleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightBold];
    self.campTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.campTitleLabel.numberOfLines = 1;
    self.campTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.campTitleLabel.textColor = [UIColor bonfirePrimaryColor];
    [self.contentView addSubview:self.campTitleLabel];
    
    self.campTagLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.campTitleLabel.frame.origin.y + self.campTitleLabel.frame.size.height + 3, self.frame.size.width - 20, 12)];
    self.campTagLabel.font = [UIFont systemFontOfSize:10.f weight:UIFontWeightBold];
    self.campTagLabel.textAlignment = NSTextAlignmentCenter;
    self.campTagLabel.numberOfLines = 1;
    self.campTagLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.campTagLabel.textColor = [UIColor bonfirePrimaryColor];
    [self.contentView addSubview:self.campTagLabel];
    
    self.membersDetailsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.membersDetailsButton.userInteractionEnabled = false;
    self.membersDetailsButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.membersDetailsButton.frame = CGRectMake(16, self.frame.size.height - 12 - 24, self.frame.size.width - 32, 24);
    self.membersDetailsButton.titleLabel.font = [UIFont systemFontOfSize:9 weight:UIFontWeightRegular];
    [self.membersDetailsButton setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
    [self.membersDetailsButton setImage:[[UIImage imageNamed:@"mini_members_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.membersDetailsButton.tintColor = [UIColor bonfireSecondaryColor];
    [self.membersDetailsButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 4)];
    [self.membersDetailsButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 0)];
    [self.membersDetailsButton setContentEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 8)];
    self.membersDetailsButton.backgroundColor = [UIColor bonfireDetailColor];
    self.membersDetailsButton.layer.cornerRadius = self.membersDetailsButton.frame.size.height / 2;
    [self.contentView addSubview:self.membersDetailsButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.campHeaderView.frame = CGRectMake(self.campHeaderView.frame.origin.x, self.campHeaderView.frame.origin.y, self.frame.size.width, self.campHeaderView.frame.size.height);
    self.campAvatarContainer.center = CGPointMake(self.campHeaderView.frame.size.width / 2, self.campAvatarContainer.center.y);
    
    if (![self.campAvatarReasonView isHidden]) {
        if (self.tapToJoin) {
            self.campAvatarReasonView.frame = CGRectMake(self.campAvatarContainer.frame.origin.x + self.campAvatarContainer.frame.size.width - self.campAvatarReasonView.frame.size.width, self.campAvatarContainer.frame.origin.y, self.campAvatarReasonView.frame.size.width, self.campAvatarReasonView.frame.size.height);
        }
        else {
            self.campAvatarReasonView.frame = CGRectMake(self.campAvatarContainer.frame.origin.x + self.campAvatarContainer.frame.size.width - self.campAvatarReasonView.frame.size.width, self.campAvatarContainer.frame.origin.y + self.campAvatarContainer.frame.size.height - self.campAvatarReasonView.frame.size.height, self.campAvatarReasonView.frame.size.width, self.campAvatarReasonView.frame.size.height);
        }
    }
    
    CGFloat contentPadding = 10;
    CGFloat contentWidth = self.frame.size.width - (contentPadding * 2);
    
    // title
    self.campTitleLabel.frame = CGRectMake(contentPadding, self.campTitleLabel.frame.origin.y, contentWidth, self.campTitleLabel.frame.size.height);;

    if (![self.campTagLabel isHidden]) {
        self.campTagLabel.frame = CGRectMake(contentPadding, self.campTagLabel.frame.origin.y, contentWidth, self.campTagLabel.frame.size.height);
    }

    CGFloat membersDetailsWidth = MIN(self.frame.size.width - (12 * 2), self.membersDetailsButton.intrinsicContentSize.width + self.membersDetailsButton.imageEdgeInsets.right);
    self.membersDetailsButton.frame = CGRectMake(self.frame.size.width / 2 - (membersDetailsWidth / 2), self.frame.size.height - 12 - self.membersDetailsButton.frame.size.height, membersDetailsWidth, self.membersDetailsButton.frame.size.height);
    
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
    self.contentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
}

- (void)setHighlighted:(BOOL)highlighted {
    if (highlighted) {
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            self.transform = CGAffineTransformMakeScale(0.96, 0.96);
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
        
        self.tintColor = [UIColor fromHex:camp.attributes.color];
        
        self.campHeaderView.backgroundColor = [UIColor fromHex:camp.attributes.color];
        
        NSString *campTitle;
        UIFont *font = [UIFont systemFontOfSize:12.f weight:UIFontWeightBold];
        if (camp.attributes.title.length > 0) {
            campTitle = camp.attributes.title;
        }
        else if (camp.attributes.identifier.length > 0) {
            campTitle = [NSString stringWithFormat:@"@%@", camp.attributes.identifier];
        }
        else {
            campTitle = @"Secret Camp";
        }
        NSMutableAttributedString *displayNameAttributedString = [[NSMutableAttributedString alloc] initWithString:campTitle attributes:@{NSFontAttributeName:font}];
        if ([camp isVerified]) {
            NSMutableAttributedString *spacer = [[NSMutableAttributedString alloc] initWithString:@" "];
            [spacer addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, spacer.length)];
            [displayNameAttributedString appendAttributedString:spacer];
            
            // verified icon ☑️
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [UIImage imageNamed:@"verifiedIcon_small"];
            
            CGFloat attachmentHeight = MIN(ceilf(font.lineHeight), attachment.image.size.height);
            CGFloat attachmentWidth = attachmentHeight * (attachment.image.size.width / attachment.image.size.height);
           
            [attachment setBounds:CGRectMake(0, roundf(font.capHeight - attachmentHeight)/2.25f, attachmentWidth, attachmentHeight)];
                        
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [displayNameAttributedString appendAttributedString:attachmentString];
        }
        self.campTitleLabel.attributedText = displayNameAttributedString;
        
        self.campTagLabel.hidden = (camp.attributes.identifier.length == 0);
        if (![self.campTagLabel isHidden]) {
            self.campTagLabel.text = [NSString stringWithFormat:@"#%@", camp.attributes.identifier];
            self.campTagLabel.textColor = [UIColor fromHex:camp.attributes.color adjustForOptimalContrast:true];
        }
        
        self.campAvatar.camp = camp;
        
        // set details view up with members
        BFDetailItem *detailItem;
        
        // set details view up with members
        if ([camp isChannel] && (camp.attributes.display.sourceLink || camp.attributes.display.sourceUser))  {
            if (camp.attributes.display.sourceLink) {
                detailItem = [[BFDetailItem alloc] initWithType:BFDetailItemTypeSourceLink value:[NSString stringWithFormat:@"%@", camp.attributes.display.sourceLink.attributes.canonicalUrl] action:nil];
            }
            else if (camp.attributes.display.sourceUser) {
                detailItem = [[BFDetailItem alloc] initWithType:BFDetailItemTypeSourceUser value:[NSString stringWithFormat:@"%@", camp.attributes.display.sourceUser.attributes.identifier] action:nil];
            }
            [self.membersDetailsButton setImage:[[UIImage imageNamed:@"mini_source_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else {
            detailItem = [[BFDetailItem alloc] initWithType:[camp isChannel]?BFDetailItemTypeSubscribers:BFDetailItemTypeMembers value:[NSString stringWithFormat:@"%ld", (long)camp.attributes.summaries.counts.members] action:nil];
            [self.membersDetailsButton setImage:[[UIImage imageNamed:@"mini_members_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        
        [self.membersDetailsButton setTitle:[detailItem prettyValue] forState:UIControlStateNormal];
        
        if (!self.tapToJoin) {
            BOOL showIndicator = false;
            
            if (camp.attributes.summaries.counts.live > 5) {
                showIndicator = true;
                self.campAvatarReasonLabel.text = @"🔥";
            }
            else if (camp.attributes.createdAt.length > 0) {
                NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
                    [inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
                NSDate *date = [inputFormatter dateFromString:camp.attributes.createdAt];
                
                NSUInteger unitFlags = NSCalendarUnitDay;
                NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
                NSDateComponents *components = [calendar components:unitFlags fromDate:date toDate:[NSDate new] options:0];
                
                if ([components day] < 7) {
                    showIndicator = true;
                    self.campAvatarReasonLabel.text = @"🆕";
                }
            }
            
            self.campAvatarReasonView.hidden = !showIndicator;
            self.campAvatarReasonImageView.hidden = showIndicator;
            self.campAvatarReasonLabel.hidden = !showIndicator;
        }
    }
}

- (void)setTapToJoin:(BOOL)tapToJoin {
    if (_tapToJoin != tapToJoin) {
        _tapToJoin = tapToJoin;
        
        if (tapToJoin) {
            self.campAvatarReasonView.hidden = false;
            self.campAvatarReasonImageView.hidden = false;
            self.campAvatarReasonLabel.hidden = true;
            
            self.campAvatarReasonImageView.image = [[UIImage imageNamed:@"joinCampMiniIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            [self setJoined:self.joined animated:false];
        }
    }
}
- (void)setJoined:(BOOL)joined animated:(BOOL)animated {
    [self setJoined:joined];
    
    if (self.tapToJoin) {
        if (animated && joined) {
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        }
        
        [UIView animateWithDuration:animated?0.45f:0 delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState) animations:^{
            if (joined) {
                self.transform = CGAffineTransformMakeScale(0.94, 0.94);
                
                self.campAvatarReasonView.transform = CGAffineTransformMakeScale(0.5, 0.5);
                self.campAvatarReasonView.alpha = 0;
            }
            else {
                self.transform = CGAffineTransformMakeScale(1, 1);
                
                self.campAvatarReasonView.transform = CGAffineTransformMakeScale(1, 1);
                self.campAvatarReasonView.alpha = 1;
            }
        } completion:nil];
        
        [UIView animateWithDuration:0.5f delay:0 options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState) animations:^{
            if (joined) {
                self.contentView.backgroundColor = [[UIColor fromHex:self.camp.attributes.color] colorWithAlphaComponent:0.06];
                self.membersDetailsButton.backgroundColor = self.backgroundColor;
            }
            else {
                self.contentView.backgroundColor = [UIColor cardBackgroundColor];
                self.membersDetailsButton.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.985 alpha:1];
            }
        } completion:nil];
    }
}

@end
