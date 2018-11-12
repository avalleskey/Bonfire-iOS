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

@implementation MemberRequestCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.imageView.image = [UIImage new];
        self.imageView.layer.masksToBounds = true;
        self.imageView.layer.borderColor = [UIColor clearColor].CGColor;
        self.imageView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
        self.imageView.backgroundColor = [UIColor whiteColor];
        
        self.textLabel.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightBold];
        self.textLabel.textColor = [UIColor colorWithWhite:0.07 alpha:1];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightBold];
        self.detailTextLabel.textAlignment = NSTextAlignmentRight;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        
        self.selectionBackground = [[UIView alloc] init];
        self.selectionBackground.hidden = true;
        self.selectionBackground.layer.cornerRadius = 14.f;
        self.selectionBackground.backgroundColor = [UIColor colorWithDisplayP3Red:0 green:0.46 blue:1 alpha:0.06f];
        [self.contentView insertSubview:self.selectionBackground atIndex:0];
        
        // general cell styling
        self.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
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
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        [self.contentView addSubview:self.lineSeparator];
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
    
    // line separator
    self.lineSeparator.frame = CGRectMake(62, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width - 62, 1 / [UIScreen mainScreen].scale);
    
    // selection view
    self.selectionBackground.frame = CGRectMake(6, 0, self.frame.size.width - 12, self.frame.size.height);
    
    // image view
    self.imageView.frame = CGRectMake(16, 10, 32, 32);
    
    // text label
    self.textLabel.frame = CGRectMake(62, self.imageView.frame.origin.y, self.frame.size.width - 62 - 116, self.imageView.frame.size.height);
    
    // detail text label
    self.detailTextLabel.frame = CGRectMake(self.frame.size.width - 116, self.textLabel.frame.origin.y, 100, self.textLabel.frame.size.height);
    
    // type-specific settings
    self.imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
    self.imageView.layer.cornerRadius = self.imageView.frame.size.height * .25;
    
    CGFloat buttonContainerWidth = self.frame.size.width - 62 - 16;
    self.approveButton.frame = CGRectMake(62, 52, buttonContainerWidth / 2 - 6, 34);
    self.declineButton.frame = CGRectMake(self.approveButton.frame.origin.x + self.approveButton.frame.size.width + 12, self.approveButton.frame.origin.y, self.approveButton.frame.size.width, self.approveButton.frame.size.height);
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    if (self.selectionBackground.isHidden) {
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
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
