//
//  ProfilePictureCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ProfilePictureCell.h"

@implementation ProfilePictureCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(0, 24, 72, 72)];
        [self continuityRadiusForView:self.profilePicture withRadius:self.profilePicture.frame.size.height * .25];
        self.profilePicture.image = [[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.profilePicture.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.profilePicture];
        
        self.changeProfilePictureLabel = [[UILabel alloc] init];
        self.changeProfilePictureLabel.text = @"Change Profile Photo";
        self.changeProfilePictureLabel.textAlignment = NSTextAlignmentCenter;
        self.changeProfilePictureLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        self.changeProfilePictureLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        [self.contentView addSubview:self.changeProfilePictureLabel];
    }
    
    return self;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        [UIView animateWithDuration:0.2f animations:^{
            self.backgroundColor = [UIColor colorWithDisplayP3Red:0.92 green:0.92 blue:0.92 alpha:1.00];
        }];
    }
    else {
        [UIView animateWithDuration:0.2f animations:^{
            self.backgroundColor = [UIColor whiteColor];
        }];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.profilePicture.center = CGPointMake(self.frame.size.width / 2, self.profilePicture.center.y);
    self.changeProfilePictureLabel.frame = CGRectMake(0, 112, self.frame.size.width, 19);
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
