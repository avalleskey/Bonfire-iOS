//
//  SmallCampCardCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SmallCampCardCell.h"
#import "UIColor+Palette.h"
#import "Session.h"

#define padding 16

@implementation SmallCampCardCell

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
        self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
        self.contentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
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
    
    self.backgroundColor = [UIColor contentBackgroundColor];
    self.layer.cornerRadius = 12.f;
    self.layer.masksToBounds = false;
    self.layer.shadowRadius = 2.f;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.1f].CGColor;
    self.layer.shadowOpacity = 1.f;
    self.contentView.layer.cornerRadius = self.layer.cornerRadius;
    self.contentView.layer.masksToBounds = true;
    self.layer.shouldRasterize = true;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(16, 12, 48, 48)];
    self.profilePicture.userInteractionEnabled = false;
    [self.contentView addSubview:self.profilePicture];
    
    self.member1 = [[BFAvatarView alloc] initWithFrame:CGRectMake(76, 70, 16, 16)];
    self.member1.tag = 0;
    self.member2 = [[BFAvatarView alloc] initWithFrame:CGRectMake(self.member1.frame.origin.x + 10, self.member1.frame.origin.y, self.member1.frame.size.width, self.member1.frame.size.height)];
    self.member2.tag = 1;
    self.member3 = [[BFAvatarView alloc] initWithFrame:CGRectMake(self.member2.frame.origin.x + 10, self.member1.frame.origin.y, self.member1.frame.size.width, self.member1.frame.size.height)];
    self.member3.tag = 2;
    
    [self.contentView addSubview:self.member3];
    [self.contentView addSubview:self.member2];
    [self.contentView addSubview:self.member1];
    
    [self styleMemberProfilePictureView:self.member1];
    [self styleMemberProfilePictureView:self.member2];
    [self styleMemberProfilePictureView:self.member3];
    
    self.campTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(76, 12, self.frame.size.width - 76 - 16, 19)];
    self.campTitleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    self.campTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.campTitleLabel.numberOfLines = 1;
    self.campTitleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.campTitleLabel.textColor = [UIColor bonfirePrimaryColor];
    self.campTitleLabel.text = @"";
    [self.contentView addSubview:self.campTitleLabel];
    
    self.campDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.campTitleLabel.frame.origin.x, self.campTitleLabel.frame.origin.y + self.campTitleLabel.frame.size.height + 2, self.campTitleLabel.frame.size.width, 28)];
    self.campDescriptionLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightRegular];
    self.campDescriptionLabel.textAlignment = NSTextAlignmentLeft;
    self.campDescriptionLabel.numberOfLines = 0;
    self.campDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.campDescriptionLabel.textColor = [UIColor bonfireSecondaryColor];
    self.campDescriptionLabel.text = @"";
    [self.contentView addSubview:self.campDescriptionLabel];
    
    self.membersLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.member3.frame.origin.x + self.member3.frame.size.width + 6, self.member1.frame.origin.y, 110, self.member1.frame.size.height)];
    self.membersLabel.textAlignment = NSTextAlignmentLeft;
    self.membersLabel.font = [UIFont systemFontOfSize:10.f weight:UIFontWeightMedium];
    self.membersLabel.textColor = [UIColor bonfireSecondaryColor];
    [self.contentView addSubview:self.membersLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // title
    CGRect titleLabelRect = self.campTitleLabel.frame;
    titleLabelRect.size.width = self.frame.size.width - 76 - 16;
    self.campTitleLabel.frame = titleLabelRect;
    
    // description
    CGSize descriptionSize = [self.campDescriptionLabel.text boundingRectWithSize:CGSizeMake(self.campDescriptionLabel.frame.size.width, self.campDescriptionLabel.font.lineHeight * 2)
                                                              options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                           attributes:@{NSFontAttributeName:self.campDescriptionLabel.font}
                                                              context:nil].size;
    CGRect descriptionLabelRect = self.campTitleLabel.frame;
    descriptionLabelRect.origin.y = titleLabelRect.origin.y + titleLabelRect.size.height + 2;
    descriptionLabelRect.size.width = titleLabelRect.size.width;
    descriptionLabelRect.size.height = self.campDescriptionLabel.text.length == 0 ? 0 :  ceilf(descriptionSize.height);
    self.campDescriptionLabel.frame = descriptionLabelRect;
    
    CGRect membersLabelFrame = self.membersLabel.frame;
    CGFloat membersLabelLeftPadding = 6;
    if (self.member1.isHidden) {
        membersLabelFrame.origin.x = self.member1.frame.origin.x;
    }
    else if (self.member2.isHidden) {
        membersLabelFrame.origin.x = self.member1.frame.origin.x + self.member1.frame.size.width + membersLabelLeftPadding;
    }
    else if (self.member3.isHidden) {
        membersLabelFrame.origin.x = self.member2.frame.origin.x + self.member2.frame.size.width + membersLabelLeftPadding;
    }
    else {
        membersLabelFrame.origin.x = self.member3.frame.origin.x + self.member3.frame.size.width + membersLabelLeftPadding;
    }
    membersLabelFrame.size.width = self.frame.size.width - membersLabelFrame.origin.x - 16;
    self.membersLabel.frame = membersLabelFrame;
}

- (void)setHighlighted:(BOOL)highlighted {
    if (!self.loading) {
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
}

- (void)styleMemberProfilePictureView:(UIView *)imageView  {
    imageView.userInteractionEnabled = false;
    
    CGFloat borderWidth = 2.f;
    UIView *borderVeiw = [[UIView alloc] initWithFrame:CGRectMake(imageView.frame.origin.x - borderWidth, imageView.frame.origin.y - borderWidth, imageView.frame.size.width + (borderWidth * 2), imageView.frame.size.height + (borderWidth * 2))];
    borderVeiw.backgroundColor = [UIColor cardBackgroundColor];
    borderVeiw.layer.cornerRadius = borderVeiw.frame.size.height / 2;
    borderVeiw.layer.masksToBounds = true;
    [self.contentView insertSubview:borderVeiw belowSubview:imageView];
}

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    
    if (_loading) {
        self.campTitleLabel.text = @"Loading Camp";
        self.campTitleLabel.textColor = [UIColor clearColor];
        self.campTitleLabel.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        self.campTitleLabel.layer.masksToBounds = true;
        self.campTitleLabel.layer.cornerRadius = 4.f;
        
        self.profilePicture.camp = nil;
        self.profilePicture.tintColor = [UIColor bonfireGrayWithLevel:500];
        
        self.campDescriptionLabel.hidden =
        self.membersLabel.hidden =
        self.member1.superview.hidden =
        self.member2.superview.hidden =
        self.member3.superview.hidden = true;
    }
    else {
        self.campTitleLabel.textColor = [UIColor bonfirePrimaryColor];
        self.campTitleLabel.backgroundColor = [UIColor clearColor];
        self.campTitleLabel.layer.masksToBounds = false;
        self.campTitleLabel.layer.cornerRadius = 0;
        
        self.campDescriptionLabel.hidden =
        self.membersLabel.hidden = false;
    }
}

- (void)setCamp:(Camp *)camp {
    if (camp != _camp) {
        _camp = camp;
        
        self.tintColor = [UIColor fromHex:self.camp.attributes.color];
                
        self.campTitleLabel.text = self.camp.attributes.title;
        self.campDescriptionLabel.text = self.camp.attributes.theDescription;
        
        self.profilePicture.camp = self.camp;
        
        if (self.camp.attributes.summaries.counts.members) {
            NSInteger members = self.camp.attributes.summaries.counts.members;
            self.membersLabel.text = [NSString stringWithFormat:@"%ld %@", members, members == 1 ? @"camper" : @"campers"];
            
            if (members > 0) {
                // setup the replies view
                for (NSInteger i = 0; i < 3; i++) {
                    BFAvatarView *avatarView;
                    if (i == 0) avatarView = self.member1;
                    if (i == 1) avatarView = self.member2;
                    if (i == 2) avatarView = self.member3;
                    
                    if (self.camp.attributes.summaries.members.count > i) {
                        avatarView.hidden = false;
                        
                        User *userForImageView = self.camp.attributes.summaries.members[i];
                        
                        avatarView.user = userForImageView;
                    }
                    else {
                        avatarView.hidden = true;
                    }
                }
            }
        }
        else {
            self.membersLabel.text = [NSString stringWithFormat:@"0 campers"];
        }
    }
}

@end
