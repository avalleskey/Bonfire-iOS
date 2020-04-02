//
//  PostContextView.m
//  Pulse
//
//  Created by Austin Valleskey on 1/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "PostContextView.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

@implementation PostContextView

- (id)init {
    return [self initWithFrame:CGRectMake(0, 0, 0, 0)];
}
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    //self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.04];
    self.layer.cornerRadius = 6.f;
    
    self.contextIcon = [[UIImageView alloc] initWithFrame:CGRectMake(42 - 20, postContextHeight / 2 - 10, 20, 20)];
    self.contextIcon.backgroundColor = [UIColor bonfireSecondaryColor];
    self.contextIcon.layer.cornerRadius = self.contextIcon.frame.size.height / 2;
    self.contextIcon.layer.masksToBounds = true;
    self.contextIcon.contentMode = UIViewContentModeCenter;
    self.contextIcon.tintColor = [UIColor whiteColor];
    [self addSubview:self.contextIcon];
    
    self.contextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, postContextHeight)];
    self.contextLabel.textColor = self.tintColor;
    self.contextLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightMedium];
    self.contextLabel.textAlignment = NSTextAlignmentLeft;
    //self.contextLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    [self addSubview:self.contextLabel];
    
    self.highlightView = [UIButton buttonWithType:UIButtonTypeCustom];
    self.highlightView.frame = self.bounds;
    [self.highlightView bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.alpha = 0.7;
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [self.highlightView bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.alpha = 1;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
    [self addSubview:self.highlightView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.highlightView.frame = self.bounds;
    
    self.contextIcon.frame = CGRectMake(42 - self.contextIcon.frame.size.width, self.frame.size.height / 2 - self.contextIcon.frame.size.height / 2, self.contextIcon.frame.size.width, self.contextIcon.frame.size.height);
    self.contextLabel.frame = CGRectMake(64 - self.frame.origin.x, self.contextLabel.frame.origin.y, self.frame.size.width - (64 - self.frame.origin.x), self.contextLabel.frame.size.height);
}

- (void)setText:(NSString *)text {
    if (![text isEqualToString:_text]) {
        _text = text;
        
        self.contextLabel.text = text;
        
        [self layoutSubviews];
    }
}
- (void)setAttributedText:(NSAttributedString *)attributedText {
    if (![attributedText isEqualToAttributedString:_attributedText]) {
        _attributedText = attributedText;
        
        self.contextLabel.attributedText = attributedText;
        
        [self layoutSubviews];
    }
}
- (void)setIcon:(UIImage *)icon {
    if (icon != _icon) {
        _icon = icon;
        
        self.contextIcon.image = icon;
    }
}

@end
