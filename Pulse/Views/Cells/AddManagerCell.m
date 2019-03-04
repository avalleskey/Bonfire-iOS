//
//  AddManagerCell.m
//  Pulse
//
//  Created by Austin Valleskey on 3/4/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "AddManagerCell.h"

@implementation AddManagerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.imageView.image = [[UIImage imageNamed:@"tableRowAddMemberIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.imageView.frame = CGRectMake(12, 0, 42, 42);
        
        self.textLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
        self.textLabel.textColor = self.superview.tintColor;
        
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.imageView.center = CGPointMake(self.imageView.center.x, self.frame.size.height / 2);
    self.textLabel.frame = CGRectMake(68, 0, self.frame.size.width - 68 - 12, self.contentView.bounds.size.height);
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
