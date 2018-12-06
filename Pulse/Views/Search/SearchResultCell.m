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

@implementation SearchResultCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.imageView.image = [UIImage new];
        self.imageView.layer.masksToBounds = true;
        self.imageView.layer.borderColor = [UIColor clearColor].CGColor;
        self.imageView.layer.borderWidth = 1 / [UIScreen mainScreen].scale;
        self.imageView.backgroundColor = [UIColor whiteColor];
        
        self.textLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightBold];
        self.textLabel.textColor = [UIColor colorWithWhite:0.07 alpha:1];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
        self.detailTextLabel.textAlignment = NSTextAlignmentLeft;
        self.detailTextLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        
        // general cell styling
        self.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
        self.selectionStyle = UITableViewCellSelectionStyleNone;
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
    self.imageView.frame = CGRectMake(16, self.frame.size.height / 2 - 20, 40, 40);
    
    // text label
    self.textLabel.frame = CGRectMake(68, 16, self.frame.size.width - 68 - 16, 16);
    
    // detail text label
    self.detailTextLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 1, self.textLabel.frame.size.width, 16);
    
    // type-specific settings
    if (self.type == 1) {
        // -- Room --
        
        // image view
        self.imageView.image = [[UIImage imageNamed:@"anonymousGroup"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.imageView.layer.cornerRadius = self.imageView.frame.size.height / 2;
    }
    else {
        self.imageView.layer.cornerRadius = self.imageView.frame.size.height * .25;
    }
    if (self.type == 2) {
        self.imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
    }
    else {
        self.imageView.layer.borderColor = [UIColor clearColor].CGColor;
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
