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
#import <Tweaks/FBTweakInline.h>

@implementation MemberRequestCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.imageView.image = [UIImage new];
        self.imageView.layer.masksToBounds = true;
        self.imageView.layer.borderColor = [UIColor clearColor].CGColor;
        self.imageView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
        self.imageView.backgroundColor = [UIColor whiteColor];
        
        self.textLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightBold];
        self.textLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
        self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        
        // general cell styling
        self.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.approveButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.approveButton setTitle:@"Approve" forState:UIControlStateNormal];
        [self.approveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.approveButton.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightBold]];
        self.approveButton.layer.cornerRadius = 8.f;
        self.approveButton.layer.masksToBounds = true;
        self.approveButton.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
        self.approveButton.layer.borderWidth = 1.f;
        [self addPressDownEffectsToButton:self.approveButton];
        [self.contentView addSubview:self.approveButton];
        
        self.declineButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.declineButton setTitle:@"Decline" forState:UIControlStateNormal];
        [self.declineButton setTitleColor:[UIColor colorWithRed:0.33 green:0.33 blue:0.33 alpha:1.0] forState:UIControlStateNormal];
        [self.declineButton.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold]];
        self.declineButton.layer.cornerRadius = 8.f;
        self.declineButton.layer.masksToBounds = true;
        self.declineButton.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
        self.declineButton.layer.borderWidth = 1.f;
        [self addPressDownEffectsToButton:self.declineButton];
        [self.contentView addSubview:self.declineButton];
    }
    return self;
}

- (void)addPressDownEffectsToButton:(UIButton *)button {
    [button bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.2 animations:^{
            button.alpha = 0.5;
        }];
    } forControlEvents:UIControlEventTouchDown];
    
    [button bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.2 animations:^{
            button.alpha = 1;
        }];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // image view
    self.imageView.frame = CGRectMake(16, 10, 42, 42);
    
    // text label
    self.textLabel.frame = CGRectMake(70, 13, self.frame.size.width - 70 - 16, 18);
    
    // detail text label
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 1, self.textLabel.frame.size.width, 16);
    
    // type-specific settings
    self.imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
    
    BOOL circleProfilePictures = FBTweakValue(@"Post", @"General", @"Circle Profile Pictures", NO);
    if (circleProfilePictures) {
        self.imageView.layer.cornerRadius = self.imageView.frame.size.height * .5;
    }
    else {
        self.imageView.layer.cornerRadius = self.imageView.frame.size.height * .25;
    }
    
    CGFloat buttonContainerWidth = self.frame.size.width - 70 - 16;
    self.approveButton.frame = CGRectMake(70, 60, buttonContainerWidth / 2 - 6, 34);
    self.declineButton.frame = CGRectMake(self.approveButton.frame.origin.x + self.approveButton.frame.size.width + 12, self.approveButton.frame.origin.y, self.approveButton.frame.size.width, self.approveButton.frame.size.height);
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
