//
//  InputCell.h
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UITextView+Placeholder.h"

NS_ASSUME_NONNULL_BEGIN

#define INPUT_CELL_FONT [UIFont systemFontOfSize:16.f weight:UIFontWeightMedium]
#define INPUT_CELL_LABEL_LEFT_PADDING 12
#define INPUT_CELL_LABEL_WIDTH 88
#define INPUT_CELL_TEXTVIEW_INSETS UIEdgeInsetsMake(14, 12, 14, INPUT_CELL_LABEL_LEFT_PADDING)

@interface InputCell : UITableViewCell

typedef enum {
    InputCellTypeTextField = 0,
    InputCellTypeTextView = 1
} InputCellType;

@property (strong, nonatomic) UILabel *inputLabel;
@property (strong, nonatomic) UITextField *input;
@property (strong, nonatomic) UITextView *textView;

@property (strong, nonatomic) UILabel *charactersRemainingLabel;

@property (strong, nonatomic) UIView *lineSeparator;

@property (nonatomic) InputCellType type;

@end

NS_ASSUME_NONNULL_END
