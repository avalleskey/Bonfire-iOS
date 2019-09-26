//
//  InputCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "InputCell.h"
#import "UIColor+Palette.h"

@implementation InputCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        
        self.inputLabel = [[UILabel alloc] init];
        self.inputLabel.text = @"Input Label";
        self.inputLabel.font = [UIFont systemFontOfSize:INPUT_CELL_FONT.pointSize weight:UIFontWeightMedium];
        self.inputLabel.textColor = [UIColor bonfireSecondaryColor];
        [self.contentView addSubview:self.inputLabel];
        
        self.input = [[UITextField alloc] init];
        self.input.font = INPUT_CELL_FONT;
        self.input.textColor = [UIColor bonfirePrimaryColor];
        self.input.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.input];
        
        self.textView = [[UITextView alloc] init];
        self.textView.backgroundColor = [UIColor clearColor];
        self.textView.font = INPUT_CELL_FONT;
        self.textView.textColor = self.input.textColor;
        self.textView.textAlignment = NSTextAlignmentLeft;
        self.textView.textContainerInset = INPUT_CELL_TEXTVIEW_INSETS;
        self.textView.textContainer.lineFragmentPadding = 0;
        self.textView.hidden = true;
//        self.textView.keyboardAppearance = UIKeyboardAppearanceLight;
        self.textView.placeholderColor = [UIColor colorWithRed:0.24 green:0.24 blue:0.26 alpha:0.3];
        [self.contentView addSubview:self.textView];
        
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 26)];
        self.input.leftView = paddingView;
        self.input.leftViewMode = UITextFieldViewModeAlways;
        self.input.rightView = paddingView;
        self.input.rightViewMode = UITextFieldViewModeAlways;
//        self.input.keyboardAppearance = UIKeyboardAppearanceLight;
        
        self.charactersRemainingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.textView.frame.size.width, 12)];
        self.charactersRemainingLabel.textAlignment = NSTextAlignmentRight;
        self.charactersRemainingLabel.textColor = [UIColor bonfireSecondaryColor];
        self.charactersRemainingLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightMedium];
        [self.contentView addSubview:self.charactersRemainingLabel];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
        self.lineSeparator.hidden = true;
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self.contentView addSubview:self.lineSeparator];
    }
    
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.inputLabel.hidden) {
        self.input.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        self.textView.frame = self.bounds;
    }
    else {
        self.inputLabel.frame = CGRectMake(INPUT_CELL_LABEL_LEFT_PADDING, 0, INPUT_CELL_LABEL_WIDTH, (self.type == InputCellTypeTextField ? self.frame.size.height : 48));
        self.input.frame = CGRectMake(self.inputLabel.frame.origin.x + self.inputLabel.frame.size.width, 0, self.frame.size.width - (self.inputLabel.frame.origin.x + self.inputLabel.frame.size.width), self.frame.size.height);
        self.textView.frame = CGRectMake(self.inputLabel.frame.origin.x + self.inputLabel.frame.size.width, 0, self.frame.size.width - (self.inputLabel.frame.origin.x + self.inputLabel.frame.size.width), self.frame.size.height);
        self.charactersRemainingLabel.frame = CGRectMake(self.textView.frame.origin.x + INPUT_CELL_TEXTVIEW_INSETS.left, self.frame.size.height - INPUT_CELL_TEXTVIEW_INSETS.bottom - 12, self.textView.frame.size.width - (INPUT_CELL_TEXTVIEW_INSETS.left + INPUT_CELL_TEXTVIEW_INSETS.right), 12);
    }
    
    if (![self.lineSeparator isHidden]) {
        self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - self.lineSeparator.frame.size.height, self.frame.size.width, self.lineSeparator.frame.size.height);
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    if (selected) { [self.input becomeFirstResponder]; }
}

- (void)setType:(InputCellType)type {
    if (type != _type) {
        _type = type;
        
        if (type == InputCellTypeTextField) {
            // text field
            self.input.hidden = false;
            self.textView.hidden = true;
        }
        else {
            // text view
            self.input.hidden = true;
            self.textView.hidden = false;
        }
    }
}

@end
