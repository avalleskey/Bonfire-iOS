//
//  ContactCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ContactCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>

@implementation ContactCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.imageView.image = [UIImage new];
        self.imageView.layer.masksToBounds = true;
        self.imageView.layer.borderColor = [UIColor clearColor].CGColor;
        self.imageView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
        self.imageView.backgroundColor = [UIColor whiteColor];
        
        self.textLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
        self.textLabel.textColor = [UIColor colorWithWhite:0.07 alpha:1];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightMedium];
        self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        
        self.checkIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
        self.checkIcon.image = [[UIImage imageNamed:@"tableCellCheckIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.checkIcon.tintColor = [UIColor bonfireBrand];
        self.checkIcon.hidden = true;
        [self.contentView addSubview:self.checkIcon];
        
        // general cell styling
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        [self.contentView addSubview:self.lineSeparator];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // selection view
    self.checkIcon.frame = CGRectMake(self.contentView.frame.size.width - self.checkIcon.frame.size.width - 16, self.frame.size.height / 2 - (self.checkIcon.frame.size.height / 2), self.checkIcon.frame.size.width, self.checkIcon.frame.size.height);
    
    // image view
    self.imageView.frame = CGRectMake(12, self.frame.size.height / 2 - 18, 36, 36);
    
    // text label
    if (self.isSearching) {
        self.textLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
        self.textLabel.frame = CGRectMake(60, 9, self.frame.size.width - 60 - self.checkIcon.frame.size.width - 16 - 8, 19);
        
        self.detailTextLabel.hidden = false;
        self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, 30, self.textLabel.frame.size.width, 14);
    }
    else {
        self.textLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
        self.textLabel.frame = CGRectMake(60, 0, self.frame.size.width - 60 - self.checkIcon.frame.size.width - 16 - 8, self.frame.size.height);
        self.detailTextLabel.hidden = true;
    }
    
    BOOL circleProfilePictures = FBTweakValue(@"Post", @"General", @"Circle Profile Pictures", YES);
    if (circleProfilePictures) {
        self.imageView.layer.cornerRadius = self.imageView.frame.size.height * .5;
    }
    else {
        self.imageView.layer.cornerRadius = self.imageView.frame.size.height * .25;
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

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
