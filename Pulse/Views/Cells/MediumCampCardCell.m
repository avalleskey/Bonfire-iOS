//
//  CampCardCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "MediumCampCardCell.h"
#import "UIColor+Palette.h"

#define padding 16

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
    
    self.campHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 72)];
    self.campHeaderView.backgroundColor = [UIColor bonfireOrange];
    [self.contentView addSubview:self.campHeaderView];
    
    self.campAvatarContainer = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 80, 80)];
    self.campAvatarContainer.userInteractionEnabled = false;
    self.campAvatarContainer.backgroundColor = [UIColor contentBackgroundColor];
    self.campAvatarContainer.layer.cornerRadius = self.campAvatarContainer.frame.size.width * .5;
    self.campAvatarContainer.layer.masksToBounds = false;
    self.campAvatarContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.campAvatarContainer.layer.shadowOffset = CGSizeMake(0, 1);
    self.campAvatarContainer.layer.shadowRadius = 1.f;
    self.campAvatarContainer.layer.shadowOpacity = 0.1;
    
    self.campAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(4, 4, 72, 72)];
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
    self.campAvatarReasonView.frame = CGRectMake(self.campAvatarContainer.frame.origin.x + self.campAvatarContainer.frame.size.width - 30, self.campAvatarContainer.frame.origin.y, 28, 28);
    self.campAvatarReasonView.layer.cornerRadius = self.campAvatarReasonView.frame.size.height / 2;
    self.campAvatarReasonView.layer.masksToBounds = false;
    [self.contentView addSubview:self.campAvatarReasonView];
    
    self.campAvatarReasonLabel = [[UILabel alloc] initWithFrame:self.campAvatarReasonView.bounds];
    self.campAvatarReasonLabel.textAlignment = NSTextAlignmentCenter;
    self.campAvatarReasonLabel.font = [UIFont systemFontOfSize:11.f weight:UIFontWeightSemibold];
    self.campAvatarReasonLabel.text = @"🔥";
    [self.campAvatarReasonView addSubview:self.campAvatarReasonLabel];
    
    self.campAvatarReasonImageView = [[UIImageView alloc] initWithFrame:self.campAvatarReasonView.bounds];
    self.campAvatarReasonImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.campAvatarReasonImageView.hidden = true;
    self.campAvatarReasonImageView.layer.cornerRadius = self.campAvatarReasonView.layer.cornerRadius;
    self.campAvatarReasonImageView.layer.masksToBounds = true;
    [self.campAvatarReasonView addSubview:self.campAvatarReasonImageView];
    
    self.member1 = [[BFAvatarView alloc] initWithFrame:CGRectMake(42, 64, 32, 32)];
    self.member1.tag = 0;
    self.member2 = [[BFAvatarView alloc] initWithFrame:CGRectMake(194, 24, 32, 32)];
    self.member2.tag = 1;
    self.member3 = [[BFAvatarView alloc] initWithFrame:CGRectMake(-10, 24, 32, 32)];
    self.member3.tag = 2;
    self.member4 = [[BFAvatarView alloc] initWithFrame:CGRectMake(244, 64, 32, 32)];
    self.member4.tag = 3;
    
    [self styleMemberProfilePictureView:self.member1];
    [self styleMemberProfilePictureView:self.member2];
    [self styleMemberProfilePictureView:self.member3];
    [self styleMemberProfilePictureView:self.member4];
    
    self.campTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, self.campAvatarContainer.frame.origin.y + self.campAvatarContainer.frame.size.height + 9, self.frame.size.width - 32, 31)];
    self.campTitleLabel.font = [UIFont systemFontOfSize:24.f weight:UIFontWeightHeavy];
    self.campTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.campTitleLabel.numberOfLines = 0;
    self.campTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.campTitleLabel.textColor = [UIColor bonfirePrimaryColor];
    [self.contentView addSubview:self.campTitleLabel];
    
    self.campTagLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, self.campTitleLabel.frame.origin.y + self.campTitleLabel.frame.size.height + 4, self.frame.size.width - 32, 18)];
    self.campTagLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightHeavy];
    self.campTagLabel.textAlignment = NSTextAlignmentCenter;
    self.campTagLabel.numberOfLines = 0;
    self.campTagLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.campTagLabel.textColor = [UIColor bonfirePrimaryColor];
    [self.contentView addSubview:self.campTagLabel];
    
    self.campDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, self.campTitleLabel.frame.origin.y + self.campTitleLabel.frame.size.height + 2, self.frame.size.width - 32, 14)];
    self.campDescriptionLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
    self.campDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.campDescriptionLabel.numberOfLines = 2;
    self.campDescriptionLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.campDescriptionLabel.textColor = [UIColor bonfirePrimaryColor];
    [self.contentView addSubview:self.campDescriptionLabel];
    
    self.detailsCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(16, self.frame.size.height - 16 - 20, self.frame.size.width - 32, 16)];
    self.detailsCollectionView.userInteractionEnabled = false;
    [self.contentView addSubview:self.detailsCollectionView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
        
    self.campHeaderView.frame = CGRectMake(self.campHeaderView.frame.origin.x, self.campHeaderView.frame.origin.y, self.frame.size.width, self.campHeaderView.frame.size.height);
    self.campAvatarContainer.center = CGPointMake(self.campHeaderView.frame.size.width / 2, self.campAvatarContainer.center.y);
    
    if (![self.campAvatarReasonView isHidden]) {
        self.campAvatarReasonView.frame = CGRectMake(self.campAvatarContainer.frame.origin.x + self.campAvatarContainer.frame.size.width - self.campAvatarReasonView.frame.size.width - 2, self.campAvatarContainer.frame.origin.y + self.campAvatarContainer.frame.size.height - self.campAvatarReasonView.frame.size.height - 2, self.campAvatarReasonView.frame.size.width, self.campAvatarReasonView.frame.size.height);
    }
    
    CGFloat contentPadding = 16;
    CGFloat contentWidth = self.frame.size.width - (contentPadding * 2);
    CGFloat bottomY  = self.campTitleLabel.frame.origin.y;
    
    // title
    CGSize titleSize = [self.campTitleLabel.attributedText boundingRectWithSize:CGSizeMake(contentWidth, self.campTitleLabel.font.lineHeight * 2)
                                                     options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                     context:nil].size;
    self.campTitleLabel.frame = CGRectMake(contentPadding, bottomY, contentWidth, ceilf(titleSize.height));;
    bottomY = self.campTitleLabel.frame.origin.y + self.campTitleLabel.frame.size.height + 6;
    
    if (![self.campTagLabel isHidden]) {
        self.campTagLabel.frame = CGRectMake(contentPadding, bottomY, contentWidth, self.campTagLabel.frame.size.height);
        bottomY = self.campTagLabel.frame.origin.y + self.campTagLabel.frame.size.height + 6;
    }
    
    // description
    CGSize descriptionSize = [self.campDescriptionLabel.text boundingRectWithSize:CGSizeMake(contentWidth, self.campDescriptionLabel.font.lineHeight * 2)
                                                              options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                           attributes:@{NSFontAttributeName:self.campDescriptionLabel.font}
                                                              context:nil].size;
    CGRect descriptionLabelRect = self.campDescriptionLabel.frame;
    descriptionLabelRect.origin.y = bottomY;
    descriptionLabelRect.size.height = ceilf(descriptionSize.height);
    descriptionLabelRect.size.width = contentWidth;
    self.campDescriptionLabel.frame = descriptionLabelRect;
//    bottomY = self.campDescriptionLabel.frame.origin.y + self.campDescriptionLabel.frame.size.height;
    
    self.detailsCollectionView.frame = CGRectMake(contentPadding, self.frame.size.height - 20 - self.detailsCollectionView.frame.size.height, contentWidth, self.detailsCollectionView.frame.size.height);
    
    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
    self.contentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
}

- (void)setHighlighted:(BOOL)highlighted {
   if (highlighted) {
       [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
           //self.alpha = 0.75;
           self.transform = CGAffineTransformMakeScale(0.96, 0.96);
       } completion:nil];
   }
   else {
       [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
           self.alpha = 1;
           self.transform = CGAffineTransformIdentity;
       } completion:nil];
   }
}

- (void)styleMemberProfilePictureView:(UIView *)imageView  {
    imageView.userInteractionEnabled = false;
    
    CGFloat borderWidth = 3.f;
    UIView *borderVeiw = [[UIView alloc] initWithFrame:CGRectMake(imageView.frame.origin.x - borderWidth, imageView.frame.origin.y - borderWidth, imageView.frame.size.width + (borderWidth * 2), imageView.frame.size.height + (borderWidth * 2))];
    borderVeiw.backgroundColor = [UIColor bonfireDetailColor];
    borderVeiw.layer.cornerRadius = borderVeiw.frame.size.height / 2;
    borderVeiw.layer.masksToBounds = false;
    borderVeiw.layer.shadowColor = [UIColor blackColor].CGColor;
    borderVeiw.layer.shadowOffset = CGSizeMake(0, HALF_PIXEL);
    borderVeiw.layer.shadowRadius = 1.f;
    borderVeiw.layer.shadowOpacity = 0.12;
    [self.contentView insertSubview:borderVeiw belowSubview:imageView];
    
    // move imageview to child of border view
    [imageView removeFromSuperview];
    imageView.frame = CGRectMake(borderWidth, borderWidth, imageView.frame.size.width, imageView.frame.size.height);
    [borderVeiw addSubview:imageView];
}

- (void)setCamp:(Camp *)camp {
    if (camp != _camp) {
        _camp = camp;
        
        self.tintColor = [UIColor fromHex:camp.attributes.color];
        
        self.campHeaderView.backgroundColor = [UIColor fromHex:camp.attributes.color];
        // set profile pictures
        for (NSInteger i = 0; i < 4; i++) {
            BFAvatarView *avatarView;
            if (i == 0) { avatarView = self.member1; }
            else if (i == 1) { avatarView = self.member2; }
            else if (i == 2) { avatarView = self.member3; }
            else { avatarView = self.member4; }
            
            if (camp.attributes.summaries.members.count > i && ![camp isChannel]) {
                avatarView.superview.hidden = false;
                
                User *userForImageView = camp.attributes.summaries.members[i];
                
                avatarView.user = userForImageView;
            }
            else {
                avatarView.superview.hidden = true;
            }
        }
        
        // camp title
        NSString *campTitle;
        UIFont *font = [UIFont systemFontOfSize:24.f weight:UIFontWeightHeavy];
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
            attachment.image = [UIImage imageNamed:@"verifiedIcon_large"];
            [attachment setBounds:CGRectMake(0, roundf(font.capHeight - attachment.image.size.height)/2.f-1, attachment.image.size.width, attachment.image.size.height)];
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [displayNameAttributedString appendAttributedString:attachmentString];
        }
        self.campTitleLabel.attributedText = displayNameAttributedString;
        
        self.campTagLabel.hidden = camp.attributes.identifier.length == 0;
        if (![self.campTagLabel isHidden]) {
            self.campTagLabel.text = [NSString stringWithFormat:@"#%@", camp.attributes.identifier];
            self.campTagLabel.textColor = [UIColor fromHex:camp.attributes.color adjustForOptimalContrast:true];
        }
        self.campDescriptionLabel.text = camp.attributes.theDescription;
        
        self.campAvatar.camp = camp;
        
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
        else  if ([camp.attributes.context.camp.membership.role.type isEqualToString:CAMP_ROLE_ADMIN]) {
            useImage = true;
            self.campAvatarReasonImageView.image = [UIImage imageNamed:@"directorIcon"];
        }
        if ([camp.attributes.context.camp.membership.role.type isEqualToString:CAMP_ROLE_MODERATOR]) {
            useImage = true;
            self.campAvatarReasonImageView.image = [UIImage imageNamed:@"managerIcon"];
        }
        self.campAvatarReasonView.hidden = !useText && !useImage;
        self.campAvatarReasonImageView.hidden = !useImage;
        self.campAvatarReasonLabel.hidden = !useText;
        
        // set details view up with members
        if ([camp isChannel] && (camp.attributes.display.sourceLink || camp.attributes.display.sourceUser))  {
            if (camp.attributes.display.sourceLink) {
                BFDetailItem *sourceLink = [[BFDetailItem alloc] initWithType:BFDetailItemTypeSourceLink value:[NSString stringWithFormat:@"%@", camp.attributes.display.sourceLink.attributes.canonicalUrl] action:nil];
                sourceLink.selectable = false;
                self.detailsCollectionView.details = @[sourceLink];
            }
            else if (camp.attributes.display.sourceUser) {
                BFDetailItem *sourceUser = [[BFDetailItem alloc] initWithType:BFDetailItemTypeSourceUser value:[NSString stringWithFormat:@"%@", camp.attributes.display.sourceUser.attributes.identifier] action:nil];
                sourceUser.selectable = false;
                self.detailsCollectionView.details = @[sourceUser];
            }
        }
        else {
            BFDetailItem *members = [[BFDetailItem alloc] initWithType:[camp isChannel]?BFDetailItemTypeSubscribers:BFDetailItemTypeMembers value:[NSString stringWithFormat:@"%ld", (long)camp.attributes.summaries.counts.members] action:nil];
            self.detailsCollectionView.details = @[members];
        }
    }
}

@end
