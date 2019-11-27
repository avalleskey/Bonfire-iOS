//
//  ToggleCell.m
//  Ingenious, Inc.
//
//  Copyright © 2018 Ingenious, Inc. All rights reserved.
//

#import "ToggleCell.h"
#import "UIColor+Palette.h"

@implementation ToggleCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.toggle = [[UISwitch alloc] init];
        self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        [self.contentView addSubview:self.toggle];
        
        self.textLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        self.textLabel.textColor = [UIColor bonfireSecondaryColor];
        
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.bottomSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - HALF_PIXEL, self.frame.size.width, HALF_PIXEL)];
        self.bottomSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        self.bottomSeparator.hidden = true;
        [self.contentView addSubview:self.bottomSeparator];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.toggle.frame = CGRectMake(self.contentView.bounds.size.width - 51 - 12, self.contentView.bounds.size.height / 2 - (31 / 2), 51, 31);
    self.textLabel.frame = CGRectMake(12, 0, self.frame.size.width - 24, self.contentView.bounds.size.height);
    
    self.bottomSeparator.frame = CGRectMake(self.bottomSeparator.frame.origin.x, self.frame.size.height - self.bottomSeparator.frame.size.height, self.frame.size.width - self.bottomSeparator.frame.origin.x, self.bottomSeparator.frame.size.height);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
