//
//  ChannelCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ChannelCell.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

#define padding 24

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
    __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
    })

@implementation ChannelCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    // [self continuityRadiusForCell:self withRadius:12.f];
    self.layer.cornerRadius = 16.f;
    self.layer.masksToBounds = true;
    self.layer.shadowOffset = CGSizeMake(0, 6.f);
    
    self.layer.shadowRadius = 22.f;
    self.layer.shadowOpacity = 1;
    self.clipsToBounds = false;
    
    self.shimmerContainer = [[FBShimmeringView alloc] initWithFrame:self.bounds];
    self.shimmerContainer.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.shimmerContainer.shimmering = true;
    self.shimmerContainer.shimmeringSpeed = 400;
    //[self.contentView addSubview:self.shimmerContainer];
    
    UIView *viewToShimmer = [[UIView alloc] initWithFrame:self.shimmerContainer.bounds];
    viewToShimmer.tag = 10;
    [self.shimmerContainer.contentView addSubview:viewToShimmer];
    
    UIView *profilepictureContainer = [[UIView alloc] initWithFrame:CGRectMake(24, 30, 72, 72)];
    profilepictureContainer.layer.cornerRadius = profilepictureContainer.frame.size.width / 2;
    profilepictureContainer.layer.shadowOffset = CGSizeMake(0, 2);
    profilepictureContainer.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12f].CGColor;
    profilepictureContainer.layer.shadowRadius = 6.f;
    self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, profilepictureContainer.frame.size.width, profilepictureContainer.frame.size.height)];
    self.profilePicture.backgroundColor = [UIColor colorWithWhite:1 alpha:0.4f];
    self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width / 2;
    self.profilePicture.layer.masksToBounds = true;
    [profilepictureContainer addSubview:self.profilePicture];
    [self.contentView addSubview:profilepictureContainer];
    
    self.title = [[UILabel alloc] init];
    self.title.font = [UIFont systemFontOfSize:32.f weight:UIFontWeightHeavy];
    self.title.textAlignment = NSTextAlignmentLeft;
    self.title.numberOfLines = 0;
    self.title.textColor = [UIColor whiteColor];
    [self.contentView addSubview:self.title];
    
    self.bio = [[UILabel alloc] init];
    self.bio.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
    self.bio.textAlignment = NSTextAlignmentLeft;
    self.bio.numberOfLines = 0;
    self.bio.textColor = [UIColor colorWithWhite:1 alpha:0.75];
    [self.contentView addSubview:self.bio];
    
    self.ticker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.ticker.backgroundColor = [UIColor whiteColor];
    self.ticker.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    [self.ticker setTitleColor:[UIColor colorWithDisplayP3Red:0.87 green:0.09 blue:0.09 alpha:1] forState:UIControlStateNormal];
    self.ticker.layer.cornerRadius = 18.f;
    self.ticker.layer.masksToBounds = true;
    self.ticker.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.ticker.titleEdgeInsets = UIEdgeInsetsMake(0, 28, 0, 0);
    [self.contentView addSubview:self.ticker];
    
    self.tickerPulse = [[UIView alloc] initWithFrame:CGRectMake(10, 36 / 2 - 6, 12, 12)];
    self.tickerPulse.layer.cornerRadius = self.tickerPulse.frame.size.height / 2;
    self.tickerPulse.layer.masksToBounds = true;
    self.tickerPulse.backgroundColor = self.ticker.currentTitleColor;
    [self.ticker addSubview:self.tickerPulse];
    
    _membersView = [[UIView alloc] initWithFrame:CGRectMake(24, 0, self.frame.size.width - 48 - 69, 36)];
    
    float lastX = 2 * (_membersView.frame.size.height * .5) + _membersView.frame.size.height;
    for (NSInteger i = 2; i >= 0; i--) {
        UIImageView *userImage = [[UIImageView alloc] initWithFrame:CGRectMake(i * (_membersView.frame.size.height * 0.5), 0, _membersView.frame.size.height, _membersView.frame.size.height)];
        userImage.tag = i;
        userImage.backgroundColor = [UIColor whiteColor];
        userImage.layer.borderColor = [UIColor whiteColor].CGColor;
        userImage.layer.borderWidth = 2.f;
        userImage.layer.cornerRadius = userImage.frame.size.height / 2;
        userImage.layer.masksToBounds = true;
        [_membersView addSubview:userImage];
    }

    _andMoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(lastX + 6, 0, 39, _membersView.frame.size.height)];
    _andMoreLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
    _andMoreLabel.textAlignment = NSTextAlignmentCenter;
    _andMoreLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.25f];
    _andMoreLabel.layer.cornerRadius = _andMoreLabel.frame.size.height / 2;
    _andMoreLabel.layer.masksToBounds = true;
    _andMoreLabel.textColor = [UIColor whiteColor];
    [_membersView addSubview:_andMoreLabel];
    
    [self addSubview:_membersView];
    
    self.inviteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.inviteButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2f];
    self.inviteButton.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    [self.inviteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.inviteButton setTitle:@"Invite" forState:UIControlStateNormal];
    self.inviteButton.layer.cornerRadius = 18.f;
    self.inviteButton.layer.masksToBounds = true;
    [self.contentView addSubview:self.inviteButton];
    
    [self.inviteButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.inviteButton.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [self.inviteButton bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.inviteButton.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    
    [self.inviteButton bk_whenTapped:^{
        [self showShareRoomSheet];
    }];
}

- (void)showShareRoomSheet {
    UIImage *shareImage = [self roomShareImage];
    
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[shareImage, @"hi insta"] applicationActivities:nil];
    
    // and present it
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [UIViewParentController(self) presentViewController:controller animated:YES completion:nil];
}

- (UIImage *)roomShareImage {
    UIView *shareView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1080, 1080)];
    shareView.backgroundColor = self.backgroundColor;
    
    UIImageView *roomShareArt = [[UIImageView alloc] initWithFrame:shareView.bounds];
    roomShareArt.image = [UIImage imageNamed:@"roomShareArt"];
    [shareView addSubview:roomShareArt];
    
    UILabel *roomNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(shareView.frame.size.width / 2 - (590 / 2), 178, 590, 400)];
    roomNameLabel.font = [UIFont systemFontOfSize:80.f weight:UIFontWeightHeavy];
    roomNameLabel.textColor = [UIColor whiteColor];
    roomNameLabel.text = self.room.attributes.details.title;
    roomNameLabel.numberOfLines = 0;
    roomNameLabel.lineBreakMode = NSLineBreakByWordWrapping;
    CGRect nameRect = [roomNameLabel.text boundingRectWithSize:CGSizeMake(roomNameLabel.frame.size.width, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                    attributes:@{NSFontAttributeName:roomNameLabel.font}
                                                       context:nil];
    roomNameLabel.frame = CGRectMake(roomNameLabel.frame.origin.x, roomNameLabel.frame.origin.y, roomNameLabel.frame.size.width, nameRect.size.height);
    [shareView addSubview:roomNameLabel];
    
    UILabel *roomDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(shareView.frame.size.width / 2 - (roomNameLabel.frame.size.width / 2), roomNameLabel.frame.origin.y + roomNameLabel.frame.size.height, roomNameLabel.frame.size.width, 400)];
    roomDescriptionLabel.font = [UIFont systemFontOfSize:42.f weight:UIFontWeightBold];
    roomDescriptionLabel.textColor = [UIColor whiteColor];
    roomDescriptionLabel.text = self.room.attributes.details.theDescription;
    roomDescriptionLabel.alpha = 0.8;
    roomDescriptionLabel.numberOfLines = 0;
    roomDescriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    CGRect descriptionRect = [roomDescriptionLabel.text boundingRectWithSize:CGSizeMake(roomDescriptionLabel.frame.size.width, CGFLOAT_MAX)
                                                                     options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                                  attributes:@{NSFontAttributeName:roomDescriptionLabel.font}
                                                                     context:nil];
    roomDescriptionLabel.frame = CGRectMake(roomDescriptionLabel.frame.origin.x, roomNameLabel.frame.origin.y + roomNameLabel.frame.size.height + 20, roomDescriptionLabel.frame.size.width, descriptionRect.size.height);
    [shareView addSubview:roomDescriptionLabel];
    
    
    UILabel *getRoomsLabel = [[UILabel alloc] initWithFrame:CGRectMake(shareView.frame.size.width / 2 - (roomNameLabel.frame.size.width / 2), 868, roomNameLabel.frame.size.width, 50)];
    getRoomsLabel.font = [UIFont systemFontOfSize:36.f weight:UIFontWeightBold];
    getRoomsLabel.textColor = [UIColor whiteColor];
    getRoomsLabel.text = @"https://getrooms.com";
    getRoomsLabel.alpha = 1;
    [shareView addSubview:getRoomsLabel];
    
    
    UIGraphicsBeginImageContextWithOptions(shareView.bounds.size, NO, [UIScreen mainScreen].scale);
    
    [shareView drawViewHierarchyInRect:shareView.bounds afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)addTickerPulseAnimation {
    [self.tickerPulse.layer removeAllAnimations];
    CABasicAnimation *theAnimation;
    
    theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    theAnimation.duration=0.7;
    theAnimation.repeatCount=HUGE_VALF;
    theAnimation.autoreverses=YES;
    theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
    theAnimation.toValue=[NSNumber numberWithFloat:0.2];
    [self.tickerPulse.layer addAnimation:theAnimation forKey:@"animateOpacity"];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.shimmerContainer.frame = self.bounds;
    UIView *viewToShimmer = [self.shimmerContainer viewWithTag:10];
    viewToShimmer.frame = self.shimmerContainer.bounds;
    
    CGSize maxSize = CGSizeMake(self.frame.size.width - (padding*2), 256);
    
    // title
    CGRect titleRect = [self.title.text boundingRectWithSize:maxSize
                                                       options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                    attributes:@{NSFontAttributeName:self.title.font}
                                                       context:nil];
    titleRect.origin.x = padding;
    titleRect.origin.y = self.profilePicture.superview.frame.origin.y + self.profilePicture.superview.frame.size.height + 16;
    titleRect.size.width = ceilf(titleRect.size.width);
    titleRect.size.height = ceilf(titleRect.size.height);
    self.title.frame = titleRect;
    
    // bio
    CGRect bioRect = [self.bio.text boundingRectWithSize:maxSize
                                                     options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                  attributes:@{NSFontAttributeName:self.bio.font}
                                                     context:nil];
    bioRect.origin.x = padding;
    bioRect.origin.y = self.title.frame.origin.y + self.title.frame.size.height + 6;
    bioRect.size.width = ceilf(bioRect.size.width);
    bioRect.size.height = ceilf(bioRect.size.height);
    self.bio.frame = bioRect;
    
    // ticker
    CGRect tickerRect = [self.ticker.currentTitle boundingRectWithSize:CGSizeMake((self.frame.size.width / 2) - padding, 36)
                                                 options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                              attributes:@{NSFontAttributeName:self.ticker.titleLabel.font}
                                                 context:nil];
    tickerRect.size.height = 36;
    tickerRect.size.width = 28 + tickerRect.size.width + 10;
    tickerRect.origin.x = self.frame.size.width - padding - tickerRect.size.width;
    tickerRect.origin.y = self.frame.size.height - tickerRect.size.height - padding;
    self.ticker.frame = tickerRect;
    [self addTickerPulseAnimation];
    
    // members
    CGRect membersRect = self.membersView.frame;
    membersRect.origin.y = self.frame.size.height - membersRect.size.height - padding;
    self.membersView.frame = membersRect;
    if (self.room.attributes.summaries.counts.members <= 3) {
        _andMoreLabel.hidden = true;
    }
    else {
        _andMoreLabel.hidden = false;
        _andMoreLabel.text = [NSString stringWithFormat:@"+%lu", self.room.attributes.summaries.counts.members - self.room.attributes.summaries.members.count];
        [self resizeWidth:_andMoreLabel withHeight:_andMoreLabel.frame.size.height withPadding:10];
    }
    
    self.inviteButton.frame = CGRectMake(self.frame.size.width - 69 - padding, self.membersView.frame.origin.y, 69, self.membersView.frame.size.height);
}

- (void)continuityRadiusForCell:(UICollectionViewCell *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (void)resizeHeight:(UILabel *)label withWidth:(CGFloat)width {
    CGRect rect = [label.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:label.font} context:nil];
    
    label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, width, rect.size.height);
}

- (void)resizeWidth:(UILabel *)label withHeight:(CGFloat)height withPadding:(CGFloat)p {
    CGRect rect = [label.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, height) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:label.font} context:nil];
    
    label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, rect.size.width + (p * 2), height);
}

- (void)setHighlighted:(BOOL)highlighted {
    if (highlighted) {
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            //self.alpha = 0.75;
            self.transform = CGAffineTransformMakeScale(0.96, 0.96);
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.alpha = 1;
            self.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

@end
