//
//  InputCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "InputCell.h"

@implementation InputCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.inputLabel = [[UILabel alloc] init];
        self.inputLabel.text = @"Input Label";
        self.inputLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium];
        self.inputLabel.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        [self.contentView addSubview:self.inputLabel];
        
        self.input = [[UITextField alloc] init];
        self.input.font = [UIFont systemFontOfSize:22.f weight:UIFontWeightSemibold];
        self.input.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        self.input.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.input];
        
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 16, 26)];
        self.input.leftView = paddingView;
        self.input.leftViewMode = UITextFieldViewModeAlways;
        self.input.rightView = paddingView;
        self.input.rightViewMode = UITextFieldViewModeAlways;
        
    }
    
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.inputLabel.frame = CGRectMake(16, 16, self.frame.size.width - 32, 19);
    
    self.input.frame = CGRectMake(0, 41, self.inputLabel.frame.size.width, 26);
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    if (selected) { [self.input becomeFirstResponder]; }
}

@end
