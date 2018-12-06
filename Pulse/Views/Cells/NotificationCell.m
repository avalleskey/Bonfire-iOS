//
//  NotificationCell.m
//  Pulse
//
//  Created by Austin Valleskey on 12/5/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "NotificationCell.h"
#import "UIColor+Palette.h"
#import "Session.h"
#import "NSDate+NVTimeAgo.h"

@implementation NotificationCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.separatorInset = UIEdgeInsetsMake(0, screenWidth, 0, 0);
        
        self.profilePicture = [[UIImageView alloc] initWithFrame:CGRectMake(16, 12, 40, 40)];
        self.profilePicture.layer.cornerRadius = self.profilePicture.frame.size.height * .25;
        self.profilePicture.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
        self.profilePicture.layer.borderWidth = 1.f;
        self.profilePicture.layer.masksToBounds = true;
        self.profilePicture.contentMode = UIViewContentModeScaleAspectFill;
        [self.profilePicture setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.profilePicture.tintColor = [UIColor bonfireGray];
        [self.contentView addSubview:self.profilePicture];
        
        self.typeIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(self.profilePicture.frame.origin.x + self.profilePicture.frame.size.width - 18 + 2, self.profilePicture.frame.origin.y + self.profilePicture.frame.size.height - 18 + 2, 18, 18)];
        self.typeIndicator.layer.cornerRadius = self.typeIndicator.frame.size.height / 2;
        self.typeIndicator.layer.masksToBounds = false;
        self.typeIndicator.backgroundColor = [UIColor colorWithWhite:0.2f alpha:1];
        self.typeIndicator.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.16f].CGColor;
        self.typeIndicator.layer.shadowOpacity = 1;
        self.typeIndicator.layer.shadowOffset = CGSizeMake(0, 1);
        self.typeIndicator.layer.shadowRadius = 3.f;
        self.typeIndicator.contentMode = UIViewContentModeCenter;
        self.typeIndicator.tintColor = [UIColor whiteColor];
        [self.contentView addSubview:self.typeIndicator];
        
        self.actionButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 96 - 16, 16, 96, 32)];
        self.actionButton.layer.cornerRadius = 6.f;
        self.actionButton.layer.masksToBounds = true;
        self.actionButton.layer.borderColor = [UIColor colorWithRed:0.92 green:0.93 blue:0.94 alpha:1.0].CGColor;
        self.actionButton.layer.borderWidth = 0;
        self.actionButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        [self.contentView addSubview:self.actionButton];
        
        self.textLabel.frame = CGRectMake(68, 16, self.frame.size.width - 68 - self.actionButton.frame.size.width - 10, 32);
        self.textLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
        self.textLabel.textColor = [UIColor colorWithWhite:0.07 alpha:1];
    }
    else {
        
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.actionButton.frame = CGRectMake(self.frame.size.width - self.actionButton.frame.size.width - 16, self.actionButton.frame.origin.y, self.actionButton.frame.size.width, self.actionButton.frame.size.height);
    
    CGFloat textLabelWidth = self.frame.size.width - 68 - self.actionButton.frame.size.width - 16  - 10;
    CGRect textLabelRect = [self.textLabel.attributedText boundingRectWithSize:CGSizeMake(textLabelWidth, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil];
    CGFloat textLabelHeight = textLabelRect.size.height;
    
    long charSize = lroundf(self.textLabel.font.lineHeight);
    long rHeight = lroundf(textLabelHeight);
    int lineCount = roundf(rHeight/charSize);
    
    if (lineCount == 1) {
        self.textLabel.frame = CGRectMake(68, 16, textLabelWidth, textLabelRect.size.height);
        self.textLabel.center = CGPointMake(self.textLabel.center.x, self.profilePicture.center.y);
    }
    else {
        self.textLabel.frame = CGRectMake(68, 16, textLabelWidth, textLabelRect.size.height);
    }
}

- (void)setType:(NotificationType)type {
    if (type != _type) {
        _type = type;
        
        // if type is unkown, hide the indicator
        self.typeIndicator.hidden = (type == NotificationTypeUnkown);
        
        switch (type) {
            case NotificationTypeUserNewFollower:
                NSLog(@"NotificationTypeUserNewFollower");
                self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_profile"];
                self.typeIndicator.backgroundColor = [UIColor bonfireBlue];
                // TODO: set dynamically based on following context
                [self.actionButton setTitle:@"Follow" forState:UIControlStateNormal];
                self.state = NotificationStateFilled;
                break;
            case NotificationTypeRoomJoinRequest:
                self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_clock"];
                self.typeIndicator.backgroundColor = [UIColor colorWithRed:0.52 green:0.53 blue:0.55 alpha:1.0];
                [self.actionButton setTitle:@"Open" forState:UIControlStateNormal];
                self.state = NotificationStateOutline;
                break;
            case NotificationTypeRoomNewMember:
                self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_plus"];
                self.typeIndicator.backgroundColor = [UIColor bonfireGreen];
                [self.actionButton setTitle:@"Open" forState:UIControlStateNormal];
                self.state = NotificationStateOutline;
                break;
            case NotificationTypeRoomApprovedRequest:
                self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_check"];
                self.typeIndicator.backgroundColor = [UIColor bonfireGreen];
                [self.actionButton setTitle:@"Open" forState:UIControlStateNormal];
                self.state = NotificationStateOutline;
                break;
            case NotificationTypePostReply:
                self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_reply"];
                self.typeIndicator.backgroundColor = [UIColor bonfireOrange];
                [self.actionButton setTitle:@"View" forState:UIControlStateNormal];
                self.state = NotificationStateOutline;
                break;
            case NotificationTypePostSparks:
                self.typeIndicator.image = [UIImage imageNamed:@"notificationIndicator_spark"];
                self.typeIndicator.backgroundColor = [UIColor bonfireRed];
                [self.actionButton setTitle:@"View" forState:UIControlStateNormal];
                self.state = NotificationStateOutline;
                break;
                
            default:
                break;
        }
    }
}
- (void)setState:(NotificationState)state {
    if (state != _state) {
        _state = state;
        
        switch (state) {
            case NotificationStateOutline:
                self.actionButton.backgroundColor = [UIColor clearColor];
                self.actionButton.layer.borderWidth = 1.f;
                [self.actionButton setTitleColor:[UIColor colorWithWhite:0.2f alpha:1] forState:UIControlStateNormal];
                break;
            case NotificationStateFilled:
                self.actionButton.backgroundColor = [Session sharedInstance].themeColor;
                self.actionButton.layer.borderWidth = 0;
                [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                break;
                
            default:
                break;
        }
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.04f];
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor clearColor];
        } completion:nil];
    }
}

@end
