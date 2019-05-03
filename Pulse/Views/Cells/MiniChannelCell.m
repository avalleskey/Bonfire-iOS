//
//  MiniChannelCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "MiniChannelCell.h"
#import "UIColor+Palette.h"

#define padding 16

@implementation MiniChannelCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.room = [[Room alloc] init];
    
    [self continuityRadiusForCell:self withRadius:10.f];
    /*self.layer.cornerRadius = 12.f;
    self.layer.masksToBounds = true;
    self.layer.shadowRadius = 2.f;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowColor = [UIColor colorWithWhite:1 alpha:0.08f].CGColor;
    self.layer.shadowOpacity = 1;*/
    
    UIView *profilepictureContainer = [[UIView alloc] initWithFrame:CGRectMake(16, 16, 64, 64)];
    profilepictureContainer.layer.cornerRadius = profilepictureContainer.frame.size.width / 2;
    profilepictureContainer.layer.shadowOffset = CGSizeMake(0, 2);
    profilepictureContainer.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12f].CGColor;
    profilepictureContainer.layer.shadowRadius = 6.f;
    self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, profilepictureContainer.frame.size.width, profilepictureContainer.frame.size.height)];
    self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.width / 2;
    self.profilePicture.layer.masksToBounds = true;
    self.profilePicture.image = [[UIImage imageNamed:@"anonymousGroup"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.profilePicture.tintColor = [UIColor whiteColor];
    [profilepictureContainer addSubview:self.profilePicture];
    [self.contentView addSubview:profilepictureContainer];
    
    self.title = [[UILabel alloc] init];
    self.title.font = [UIFont systemFontOfSize:22.f weight:UIFontWeightHeavy];
    self.title.textAlignment = NSTextAlignmentLeft;
    self.title.numberOfLines = 0;
    self.title.lineBreakMode = NSLineBreakByWordWrapping;
    self.title.textColor = [UIColor whiteColor];
    self.title.text = @"Baseball Fans";
    [self.contentView addSubview:self.title];
    
    self.ticker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.ticker.backgroundColor = [UIColor whiteColor];
    self.ticker.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
    [self.ticker setTitleColor:[UIColor colorWithDisplayP3Red:0.87 green:0.09 blue:0.09 alpha:1] forState:UIControlStateNormal];
    self.ticker.layer.cornerRadius = 15.f;
    self.ticker.layer.masksToBounds = true;
    self.ticker.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.ticker.titleEdgeInsets = UIEdgeInsetsMake(0, 28, 0, 0);
    [self.contentView addSubview:self.ticker];
    
    self.tickerPulse = [[UIView alloc] initWithFrame:CGRectMake(10, 30 / 2 - 6, 12, 12)];
    self.tickerPulse.layer.cornerRadius = self.tickerPulse.frame.size.height / 2;
    self.tickerPulse.layer.masksToBounds = true;
    self.tickerPulse.backgroundColor = self.ticker.currentTitleColor;
    [self.ticker addSubview:self.tickerPulse];
    
    _membersView = [[UIView alloc] initWithFrame:CGRectMake(padding, 0, self.frame.size.width - (padding * 2), 30)];
    
    float lastX = 2 * (_membersView.frame.size.height * .5) + _membersView.frame.size.height;
    for (NSInteger i = 2; i >= 0; i--) {
        UIImageView *userImage = [[UIImageView alloc] initWithFrame:CGRectMake(i * (_membersView.frame.size.height * 0.5), 0, _membersView.frame.size.height, _membersView.frame.size.height)];
        userImage.tag = i;
        userImage.backgroundColor = [UIColor whiteColor];
        userImage.layer.borderColor = [UIColor whiteColor].CGColor;
        userImage.layer.borderWidth = 2.f;
        userImage.layer.cornerRadius = userImage.frame.size.height / 2;
        userImage.layer.masksToBounds = true;
        userImage.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        userImage.tintColor = [UIColor bonfireGray];
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
}

- (void)addTickerPulseAnimation {
    [self.tickerPulse.layer removeAllAnimations];
    CABasicAnimation *theAnimation;
    
    theAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    theAnimation.duration=0.8;
    theAnimation.repeatCount=HUGE_VALF;
    theAnimation.autoreverses=YES;
    theAnimation.fromValue=[NSNumber numberWithFloat:1.0];
    theAnimation.toValue=[NSNumber numberWithFloat:0.2];
    [self.tickerPulse.layer addAnimation:theAnimation forKey:@"animateOpacity"];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize maxSize = CGSizeMake(self.frame.size.width - (padding*2), 256);
    
    // title
    CGRect titleRect = [self.title.text boundingRectWithSize:maxSize
                                                       options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                    attributes:@{NSFontAttributeName:self.title.font}
                                                       context:nil];
    titleRect.origin.x = padding;
    titleRect.origin.y = 90;
    titleRect.size.width = roundf(titleRect.size.width);
    titleRect.size.height = ceil(titleRect.size.height);
    self.title.frame = titleRect;
    
    // ticker
    CGRect tickerRect = [self.ticker.currentTitle boundingRectWithSize:CGSizeMake((self.frame.size.width / 2) - padding, 36)
                                                 options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                              attributes:@{NSFontAttributeName:self.ticker.titleLabel.font}
                                                 context:nil];
    tickerRect.size.height = 30;
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
}

- (void)resizeWidth:(UILabel *)label withHeight:(CGFloat)height withPadding:(CGFloat)p {
    CGRect rect = [label.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, height) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:label.font} context:nil];
    
    label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, rect.size.width + (p * 2), height);
}

- (void)continuityRadiusForCell:(UICollectionViewCell *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
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
