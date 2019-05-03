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
        [self.contentView addSubview:self.toggle];
        
        self.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
        self.textLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightMedium];
        self.textLabel.textColor = [UIColor bonfireBlack];
        
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.toggle.frame = CGRectMake(self.contentView.bounds.size.width - 51 - 16, self.contentView.bounds.size.height / 2 - (31 / 2), 51, 31);
    self.textLabel.frame = CGRectMake(16, 0, self.frame.size.width - 32, self.contentView.bounds.size.height);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
