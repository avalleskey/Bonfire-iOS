//
//  PostTextView.m
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "PostTextView.h"
#import "UITextView+Placeholder.h"

#define maxCharacters 140

@implementation PostTextView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _textView = [[UITextView alloc] initWithFrame:frame];
        _textView.editable = false;
        _textView.scrollEnabled = false;
        _textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _textView.textContainer.lineFragmentPadding = 0;
        _textView.contentInset = UIEdgeInsetsZero;
        _textView.scrollEnabled = false;
        _textView.textContainerInset = UIEdgeInsetsMake(6, 12, 6, 12);
        _textView.textColor = [UIColor colorWithWhite:0.07f alpha:1];
        _textView.backgroundColor = [UIColor clearColor];
        _textView.delegate = self;
        _textView.backgroundColor = [UIColor colorWithRed:0.92 green:0.93 blue:0.94 alpha:1.0];
        _textView.layer.cornerRadius = 17;
        _textView.layer.masksToBounds = true;
        _textView.dataDetectorTypes = UIDataDetectorTypeLink;
        
        [self addSubview:_textView];
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}

- (void)textViewDidChange:(UITextView *)textView {
    NSLog(@"textview text: %@", textView.text);
    [self resize];
}

- (CGSize)size {
    CGSize size = [self.textView sizeThatFits:CGSizeMake((self.superview.frame.size.width - self.frame.origin.x - 16) - (_textView.contentInset.left + _textView.contentInset.right), CGFLOAT_MAX)];
    CGFloat height = _textView.contentInset.top + size.height + _textView.contentInset.bottom;
    
    CGSize resized = CGSizeMake(ceilf(size.width) + (_textView.contentInset.left + _textView.contentInset.right), ceilf(height));
    return resized;
}

- (void)resize {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.size.width, self.size.height);
    self.textView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

@end
