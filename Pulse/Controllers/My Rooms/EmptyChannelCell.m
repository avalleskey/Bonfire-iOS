//
//  ChannelCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "EmptyChannelCell.h"

#define padding 24

@implementation EmptyChannelCell

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    [self continuityRadiusForCell:self withRadius:12.f];
    self.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
    
    self.container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 295, 288)];
    [self.contentView addSubview:self.container];
    
    self.circleImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 128, 128)];
    self.circleImageView.image = [UIImage imageNamed:@"myRoomsGraphic"];
    [self.container addSubview:self.circleImageView];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.circleImageView.frame.origin.y + self.circleImageView.frame.size.height + 20, self.container.frame.size.width, 42)];
    self.titleLabel.font = [UIFont systemFontOfSize:24.f weight:UIFontWeightHeavy];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
    self.titleLabel.text = @"My Rooms";
    [self.container addSubview:self.titleLabel];
    
    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.descriptionLabel.numberOfLines = 0;
    self.descriptionLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
    self.descriptionLabel.text = @"Everything you care about, in one place. Discover new Rooms to follow by scrolling down or searching above.";
    [self.container addSubview:self.descriptionLabel];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize maxSize = CGSizeMake(self.frame.size.width - (padding*2), 512);
    
    // title
    CGRect titleRect = [self.titleLabel.text boundingRectWithSize:maxSize
                                                     options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                                  attributes:@{NSFontAttributeName:self.titleLabel.font}
                                                     context:nil];
    titleRect.origin.x = 0;
    titleRect.origin.y = self.titleLabel.frame.origin.y;
    titleRect.size.width = maxSize.width;
    self.titleLabel.frame = titleRect;
    
    // bio
    CGRect descriptionRect = [self.descriptionLabel.text boundingRectWithSize:maxSize
                                                 options:NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingUsesFontLeading
                                              attributes:@{NSFontAttributeName:self.descriptionLabel.font}
                                                 context:nil];
    descriptionRect.origin.x = 0;
    descriptionRect.origin.y = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 6;
    descriptionRect.size.width = maxSize.width;
    self.descriptionLabel.frame = descriptionRect;
    
    // ticker
    CGFloat newHeight = self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height;
    self.container.frame = CGRectMake(padding, (self.frame.size.height / 2) - (newHeight * .55), maxSize.width, newHeight);
    self.circleImageView.center = CGPointMake(self.container.frame.size.width / 2, self.circleImageView.center.y);
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

@end
