//
//  SearchResultCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SearchResultCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>

@implementation SearchResultCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(12, self.frame.size.height / 2 - 21, 42, 42)];
        self.profilePicture.userInteractionEnabled = false;
        [self.contentView addSubview:self.profilePicture];
        
        self.textLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightBold];
        self.textLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
        self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        
        // general cell styling
        self.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.checkIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
        self.checkIcon.image = [[UIImage imageNamed:@"tableCellCheckIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.checkIcon.tintColor = self.tintColor;
        self.checkIcon.hidden = true;
        [self.contentView addSubview:self.checkIcon];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // image view
    self.profilePicture.frame = CGRectMake(12, self.frame.size.height / 2 - 21, 42, 42);
    
    // text label
    self.textLabel.frame = CGRectMake(68, 14, self.frame.size.width - 68 - 16 - (self.selected ? 32 : 0), 18);
    
    // detail text label
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 1, self.textLabel.frame.size.width, 16);
    
    // check icon
    self.checkIcon.frame = CGRectMake(self.frame.size.width - self.checkIcon.frame.size.width - 16, self.frame.size.height / 2 - (self.checkIcon.frame.size.height / 2), self.checkIcon.frame.size.width, self.checkIcon.frame.size.height);
    self.checkIcon.hidden = !self.selected;
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
