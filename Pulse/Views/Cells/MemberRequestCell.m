//
//  MemberRequestCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "MemberRequestCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIColor+Palette.h"

@implementation MemberRequestCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, 10, 48, 48)];
        [self.contentView addSubview:self.profilePicture];
        
        self.textLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
        self.textLabel.textColor = [UIColor bonfirePrimaryColor];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
        self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
        self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        
        // general cell styling
        self.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.approveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.approveButton.backgroundColor = [UIColor colorWithDisplayP3Red:0.20 green:0.79 blue:0.14 alpha:1.0];
        [self.approveButton setTitle:@"Approve" forState:UIControlStateNormal];
        [self.approveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.approveButton.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightBold]];
        self.approveButton.layer.cornerRadius = 10.f;
        self.approveButton.layer.masksToBounds = true;
        [self addPressDownEffectsToButton:self.approveButton];
        [self.contentView addSubview:self.approveButton];
        
        self.declineButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.declineButton setTitle:@"Decline" forState:UIControlStateNormal];
        [self.declineButton setTitleColor:[UIColor colorWithRed:0.33 green:0.33 blue:0.33 alpha:1.0] forState:UIControlStateNormal];
        [self.declineButton.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold]];
        self.declineButton.layer.cornerRadius = 10.f;
        self.declineButton.layer.masksToBounds = true;
        self.declineButton.layer.borderWidth = 1.f;
        [self addPressDownEffectsToButton:self.declineButton];
        [self.contentView addSubview:self.declineButton];
    }
    return self;
}

- (void)addPressDownEffectsToButton:(UIButton *)button {
    [button bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            button.transform = CGAffineTransformMakeScale(0.92, 0.92);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    
    [button bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            button.transform = CGAffineTransformIdentity;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // text label
    self.textLabel.frame = CGRectMake(70, 14, self.frame.size.width - 70 - 12, 18);
    
    // detail text label
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 2, self.textLabel.frame.size.width, 16);
    
    CGFloat buttonContainerWidth = self.frame.size.width - 70 - 12;
    self.approveButton.frame = CGRectMake(70, 60, buttonContainerWidth / 2 - 6, 34);
    self.declineButton.frame = CGRectMake(self.approveButton.frame.origin.x + self.approveButton.frame.size.width + 12, self.approveButton.frame.origin.y, self.approveButton.frame.size.width, self.approveButton.frame.size.height);
    
    // added in layout subviews for dark mode support
    self.declineButton.layer.borderColor = [UIColor tableViewSeparatorColor].CGColor;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (highlighted) {
        [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor contentHighlightedColor];
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.15f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        } completion:nil];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
