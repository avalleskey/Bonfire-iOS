//
//  SearchResultCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/1/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SearchResultCell.h"
#import <SDWebImage/UIImageView+WebCache.h>

@implementation SearchResultCell

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
        
        self.lineSeparator = [[UIView alloc] init];
        self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
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
    
    // line separator
    self.lineSeparator.frame = CGRectMake(62, self.frame.size.height - (1 / [UIScreen mainScreen].scale), self.frame.size.width - 62, 1 / [UIScreen mainScreen].scale);
    
    // selection view
    self.selectionBackground.frame = CGRectMake(6, 0, self.frame.size.width - 12, self.frame.size.height);
    
    // image view
    self.imageView.frame = CGRectMake(16, self.frame.size.height / 2 - 16, 32, 32);
    
    // text label
    CGRect textLabelRect = [self.textLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - 62 - 62, self.frame.size.height) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.textLabel.font} context:nil];
    self.textLabel.frame = CGRectMake(62, 0, textLabelRect.size.width, self.frame.size.height);
    
    // detail text label
    CGFloat detailX = self.textLabel.frame.origin.x + self.textLabel.frame.size.width + 16;
    self.detailTextLabel.frame = CGRectMake(detailX, 0, self.frame.size.width - detailX - 16, self.frame.size.height);
    
    // type-specific settings
    if (self.type == 1) {
        // -- Room --
        
        // image view
        self.imageView.image = [UIImage imageNamed:@"searchRoomIcon"];
        self.imageView.layer.cornerRadius = self.imageView.frame.size.height * .25;
    }
    else {
        self.imageView.layer.cornerRadius = (self.type == 0) ? self.imageView.frame.size.height / 2 : self.imageView.frame.size.height * .25;
    }
    if (self.type == 2) {
        self.imageView.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
    }
    else {
        self.imageView.layer.borderColor = [UIColor clearColor].CGColor;
    }
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
