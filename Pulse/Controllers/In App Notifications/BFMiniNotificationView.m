//
//  BFTipView.m
//  Pulse
//
//  Created by Austin Valleskey on 5/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFMiniNotificationView.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "BFMiniNotificationManager.h"

@interface BFMiniNotificationView ()

@property (nonatomic) CGPoint centerBegin;
@property (nonatomic) CGPoint centerFinal;

@end

@implementation BFMiniNotificationView

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithObject:(BFMiniNotificationObject *)object {
    self = [super init];
    if (self) {
        [self setObject:object];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor bonfireDetailColor];
    self.frame = CGRectMake(12, -58, 200, 48);
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.4].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 8);
    self.layer.shadowRadius = 40;
    self.layer.shadowOpacity = 1;
    self.layer.masksToBounds = false;
    self.layer.cornerRadius = self.frame.size.height / 2;
    
    self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(24, 0, [UIScreen mainScreen].bounds.size.width, self.frame.size.height)];
    self.textLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    self.textLabel.numberOfLines = 0;
    self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.textLabel.textAlignment = NSTextAlignmentLeft;
    self.textLabel.textColor = [UIColor bonfireSecondaryColor];
    self.textLabel.tintColor = [UIColor bonfireSecondaryColor];
    [self addSubview:self.textLabel];
            
    [self layoutSubviews];
}

- (void)setObject:(BFMiniNotificationObject *)object {
    if (object != _object) {
        _object = object;
                
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@", _object.text, (object.action ? @"  " : @"")] attributes:@{NSFontAttributeName: self.textLabel.font, NSForegroundColorAttributeName: self.textLabel.textColor}];
        
        if (object.action) {
            // add detail disclosure icon
            NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
            attachment.image = [[UIImage imageNamed:@"pillDetailDisclosureIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [attachment setBounds:CGRectMake(0, roundf(self.textLabel.font.capHeight - 10)/2.f, 10 * (attachment.image.size.width / attachment.image.size.height), 10)];
            
            NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
            [attributedString appendAttributedString:attachmentString];
        }
        
        self.textLabel.attributedText = attributedString;
        
        [self layoutSubviews];
        
        [self bk_removeAllBlockObservers];
        if (object.action) {
            [self bk_whenTapped:^{
                [[BFMiniNotificationManager manager] hideAllNotifications];
                
                object.action();
            }];
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
        
    if (self.transform.a == 1) {
        CGSize textSize = [self.textLabel.attributedText boundingRectWithSize:CGSizeMake(self.frame.size.width - (self.textLabel.frame.origin.x * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) context:nil].size;
        self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, 0, ceilf(textSize.width), self.frame.size.height);
        
        SetWidth(self, self.textLabel.frame.size.width + (self.textLabel.frame.origin.x * 2));
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.tag = 1;
    if (self.object.action) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:nil];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.tag = 0;
    }];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.tag = 0;
    }];
}

@end

@implementation BFMiniNotificationObject

- (id)init {
    if (self = [super  init]) {
        
    }
    return self;
}
+ (BFMiniNotificationObject *)notificationWithText:(NSString *)text action:(void (^ __nullable)(void))actionHandler {
    BFMiniNotificationObject *tipObject = [BFMiniNotificationObject new];
    
    tipObject.text = text;
    
    tipObject.action = actionHandler;
    
    return tipObject;
}

@end
