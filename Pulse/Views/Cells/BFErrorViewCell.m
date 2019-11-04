//
//  ErrorViewCell.m
//  Pulse
//
//  Created by Austin Valleskey on 10/9/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFErrorViewCell.h"
#import "UIColor+Palette.h"

@implementation BFErrorViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.backgroundColor = [UIColor contentBackgroundColor];
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.visualErrorView = [[BFVisualErrorView alloc] init];
        [self.contentView addSubview:self.visualErrorView];
        
        self.separator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - HALF_PIXEL, self.frame.size.width, HALF_PIXEL)];
        self.separator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self.contentView addSubview:self.separator];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.visualErrorView.center = self.contentView.center;
    
    self.separator.frame = CGRectMake(0, self.frame.size.height - HALF_PIXEL, self.contentView.frame.size.width, HALF_PIXEL);
}

- (void)setVisualError:(BFVisualError *)visualError {
    if (visualError != _visualError) {
        _visualError = visualError;
        
        self.visualErrorView.visualError = visualError;
    }
}

+ (CGFloat)heightForVisualError:(BFVisualError *)visualError {
    UIEdgeInsets padding = UIEdgeInsetsMake(32, 0, 32, 0);
    
    BFVisualErrorView *visualErrorView = [[BFVisualErrorView alloc] initWithVisualError:visualError];
    
    return padding.top + visualErrorView.frame.size.height + padding.bottom;
}

@end
