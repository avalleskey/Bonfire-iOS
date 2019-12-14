//
//  BFAttachmentView.m
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFAttachmentView.h"
#import "UIColor+Palette.h"

@interface BFAttachmentView ()

@property (nonatomic, strong) UIButton *highlightView;

@end

@implementation BFAttachmentView

- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self setup];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.layer.cornerRadius = 14.f;
    self.layer.masksToBounds = false;
    self.backgroundColor = [UIColor contentBackgroundColor];
    
    self.contentView = [[UIView alloc] initWithFrame:self.bounds];
    self.contentView.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.14f].CGColor;
    self.contentView.layer.cornerRadius = self.layer.cornerRadius;
    self.contentView.layer.masksToBounds = true;
    self.contentView.layer.borderWidth = HALF_PIXEL;
    [self addSubview:self.contentView];
    
    self.highlightView = [UIButton buttonWithType:UIButtonTypeCustom];
    self.highlightView.frame = self.contentView.bounds;
    self.highlightView.userInteractionEnabled = false;
    self.highlightView.alpha = 0;
    self.highlightView.layer.cornerRadius = self.layer.cornerRadius;
    self.highlightView.layer.masksToBounds = true;
    [self addSubview:self.highlightView];
    
    [self defaults];
}

- (void)defaults {
    self.selectable = true;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.contentView.frame = self.bounds;
    self.contentView.layer.cornerRadius = self.layer.cornerRadius;
    self.highlightView.layer.cornerRadius = self.layer.cornerRadius;
    
    self.highlightView.frame = self.contentView.bounds;
    
    self.contentView.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.14f].CGColor;
    self.highlightView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.08f];
}

- (void)touchCancel {
    [UIView animateWithDuration:0.15f animations:^{
        self.highlightView.alpha = 0;
    }];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.selectable) {
        self.touchDown = YES;
        
        [UIView animateWithDuration:0.2f animations:^{
            self.highlightView.alpha = 1;
        }];
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Triggered when touch is released
    if (self.selectable) {
        if (self.touchDown) {
            self.touchDown = NO;
            
            [self touchCancel];
        }
    }
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Triggered if touch leaves view
    if (self.selectable) {
        if (self.touchDown) {
            self.touchDown = NO;
            
            [self touchCancel];
        }
    }
}

- (CGFloat)height {
    return 200;
}

@end
