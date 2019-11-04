//
//  SpacerCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/9/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "SpacerCell.h"
#import "UIColor+Palette.h"

@implementation SpacerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.backgroundColor = [UIColor tableViewBackgroundColor];
        
        self.topSeparator = [[UIView alloc] init];
        self.topSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self.contentView addSubview:self.topSeparator];
        
        self.bottomSeparator = [[UIView alloc] init];
        self.bottomSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self.contentView addSubview:self.bottomSeparator];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.topSeparator.frame = CGRectMake(0, 0, self.frame.size.width, HALF_PIXEL);
    self.bottomSeparator.frame = CGRectMake(0, self.frame.size.height - HALF_PIXEL, self.frame.size.width, HALF_PIXEL);
}

+ (CGFloat)height {
    return 8;
}

@end
