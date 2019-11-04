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
    self.layer.cornerRadius = 14.f;
    self.layer.masksToBounds = false;
    self.layer.shadowRadius = 1.f;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.08f].CGColor;
    self.layer.shadowOpacity = 1.f;
    self.contentView.layer.cornerRadius = self.layer.cornerRadius;
    self.contentView.layer.masksToBounds = true;
    self.layer.shouldRasterize = true;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    self.campHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 72)];
    self.campHeaderView.backgroundColor = [UIColor bonfireOrange];
    [self.contentView addSubview:self.campHeaderView];
    
    self.profilePictureContainerView = [[UIView alloc] initWithFrame:CGRectMake(20, 20, 80, 80)];
    self.profilePictureContainerView.userInteractionEnabled = false;
    self.profilePictureContainerView.backgroundColor = [UIColor contentBackgroundColor];
    self.profilePictureContainerView.layer.cornerRadius = self.profilePictureContainerView.frame.size.width * .5;
    self.profilePictureContainerView.layer.masksToBounds = false;
    self.profilePictureContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.profilePictureContainerView.layer.shadowOffset = CGSizeMake(0, 1);
    self.profilePictureContainerView.layer.shadowRadius = 1.f;
    self.profilePictureContainerView.layer.shadowOpacity = 0.1;
    
    self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(4, 4, 72, 72)];
    self.profilePicture.center = CGPointMake(self.profilePictureContainerView.frame.size.width / 2, self.profilePictureContainerView.frame.size.height / 2);
    [self.profilePictureContainerView addSubview:self.profilePicture];
    [self.contentView addSubview:self.profilePictureContainerView];
    
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
    
    self.campTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, self.profilePictureContainerView.frame.origin.y + self.profilePictureContainerView.frame.size.height + 9, self.frame.size.width - 32, 31)];
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
    self.campDescriptionLabel.numberOfLines = 0;
    self.campDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.campDescriptionLabel.textColor = [UIColor bonfirePrimaryColor];
    [self.contentView addSubview:self.campDescriptionLabel];
    
    self.detailsCollectionView = [[BFDetailsCollectionView alloc] initWithFrame:CGRectMake(16, self.frame.size.height - 16 - 16, self.frame.size.width - 32, 16)];
    self.detailsCollectionView.userInteractionEnabled = false;
    [self.contentView addSubview:self.detailsCollectionView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
        
    self.campHeaderView.frame = CGRectMake(self.campHeaderView.frame.origin.x, self.campHeaderView.frame.origin.y, self.frame.size.width, self.campHeaderView.frame.size.height);
    self.profilePictureContainerView.center = CGPointMake(self.campHeaderView.frame.size.width / 2, self.profilePictureContainerView.center.y);
    
    CGFloat contentPadding = 16;
    CGFloat contentWidth = self.frame.size.width - (contentPadding * 2);
    CGFloat bottomY  = self.campTitleLabel.frame.origin.y;
    
    // title
    CGSize titleSize = [self.campTitleLabel.text boundingRectWithSize:CGSizeMake(contentWidth, self.campTitleLabel.font.lineHeight * 2)
                                                     options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                  attributes:@{NSFontAttributeName:self.campTitleLabel.font}
                                                     context:nil].size;
    self.campTitleLabel.frame = CGRectMake(contentPadding, bottomY, contentWidth, ceilf(titleSize.height));;
    bottomY = self.campTitleLabel.frame.origin.y + self.campTitleLabel.frame.size.height + 8;
    
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
    
    self.detailsCollectionView.frame = CGRectMake(contentPadding, self.frame.size.height - 24 - self.detailsCollectionView.frame.size.height, contentWidth, self.detailsCollectionView.frame.size.height);
    
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
            
            if (camp.attributes.summaries.members.count > i) {
                avatarView.superview.hidden = false;
                
                User *userForImageView = camp.attributes.summaries.members[i];
                
                avatarView.user = userForImageView;
            }
            else {
                avatarView.superview.hidden = true;
            }
        }
        
        self.campTitleLabel.text = camp.attributes.title;
        self.campTagLabel.hidden = camp.attributes.identifier.length == 0;
        if (![self.campTagLabel isHidden]) {
            self.campTagLabel.text = [NSString stringWithFormat:@"#%@", camp.attributes.identifier];
            self.campTagLabel.textColor = [UIColor fromHex:camp.attributes.color adjustForOptimalContrast:true];
        }
        self.campDescriptionLabel.text = camp.attributes.theDescription;
        
        self.profilePicture.camp = camp;
        
        // set details view up with members
        BFDetailItem *members = [[BFDetailItem alloc] initWithType:BFDetailItemTypeMembers value:[NSString stringWithFormat:@"%ld", (long)camp.attributes.summaries.counts.members] action:nil];
        self.detailsCollectionView.details = @[members];
    }
}

@end
