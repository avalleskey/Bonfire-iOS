//
//  InsightTableViewCell.m
//  Pulse
//
//  Created by Austin Valleskey on 5/27/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "InsightTableViewCell.h"
#import "UIColor+Palette.h"

@implementation InsightTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    self.clipsToBounds = false;
    self.contentView.clipsToBounds = false;
    self.backgroundColor = [UIColor contentBackgroundColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, HALF_PIXEL)];
    self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    self.lineSeparator.hidden = true;
    [self addSubview:self.lineSeparator];
    
    self.textLabel.textColor = [UIColor bonfirePrimaryColor];
    self.textLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
    
    self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
    self.detailTextLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
    self.detailTextLabel.textAlignment = NSTextAlignmentRight;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 12, 0, 12);
    
    if (self.imageView.image) {
        self.imageView.frame = CGRectMake(contentInsets.left, self.frame.size.height / 2 - 18 / 2, 18, 18);
        
        contentInsets.left = self.imageView.frame.origin.x + self.imageView.frame.size.width + 10;
    }
    
    if (![self.detailTextLabel isHidden] && self.detailTextLabel.text.length > 0) {
        self.detailTextLabel.frame = CGRectMake(self.frame.size.width - 120 - contentInsets.right, 0, 120, self.frame.size.height);
        
        contentInsets.right = self.frame.size.width - self.detailTextLabel.frame.origin.x - 10;
    }
    
    self.textLabel.frame = CGRectMake(contentInsets.left, 0, self.frame.size.width - contentInsets.left - contentInsets.right, self.frame.size.height);
    
    if (![self.lineSeparator isHidden]) {
        self.lineSeparator.frame = CGRectMake(contentInsets.left, self.frame.size.height - HALF_PIXEL, self.frame.size.width - contentInsets.left, HALF_PIXEL);
    }
}

+ (CGFloat)height {
    return 48;
}

@end
