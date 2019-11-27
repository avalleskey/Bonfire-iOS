//
//  PostTextView.m
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "PostTextView.h"
#import "UITextView+Placeholder.h"
#import "Launcher.h"
#import "JGProgressHUD.h"
#import <HapticHelper/HapticHelper.h>
#import "UIColor+Palette.h"
#import "NSString+Validation.h"
#import "GTMNSString+HTML.h"
#import "NSString+UTF.h"

#define TWUValidUsername                @"[@][a-z0-9_]{1,20}"
#define TWUValidCampDisplayId           @"[#][a-z0-9_]{1,30}"

@implementation PostTextView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = true;
        self.layer.masksToBounds = false;
        
        self.edgeInsets = UIEdgeInsetsZero;
        self.maxCharacters = 10000;
        self.textColor = [UIColor bonfirePrimaryColor];

        self.translatesAutoresizingMaskIntoConstraints = YES;
        
        _messageLabel = [[JKRichTextView alloc] initWithFrame:frame];
        [self addSubview:_messageLabel];
        
        // [self initPatternDetections];
        UITapGestureRecognizer* doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
        doubleTap.numberOfTapsRequired = 2;
        doubleTap.numberOfTouchesRequired = 1;
        // [self addGestureRecognizer:doubleTap];
        
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
        singleTap.numberOfTapsRequired = 1;
        singleTap.numberOfTouchesRequired = 1;
        singleTap.delegate = self;
        // [self addGestureRecognizer:singleTap];
        
        [singleTap setDelaysTouchesBegan:true];
        [singleTap setCancelsTouchesInView:false];
    }
    return self;
}


//- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
//    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:phoneNumber message:nil preferredStyle:UIAlertControllerStyleActionSheet];
//
//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
//    if ([[UIApplication sharedApplication] canOpenURL:url]) {
//        UIAlertAction *call = [UIAlertAction actionWithTitle:@"Call Phone Number" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
//        }];
//        [alertController addAction:call];
//    }
//
//    UIAlertAction *copy = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
//        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
//        pasteboard.string = phoneNumber;
//
//        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
//        HUD.textLabel.text = @"Copied Phone Number!";
//        HUD.vibrancyEnabled = false;
//        HUD.animation = [[JGProgressHUDFadeZoomAnimation alloc] init];
//        HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
//        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
//        HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
//
//        [HUD showInView:[Launcher activeViewController].view animated:YES];
//        [HapticHelper generateFeedback:FeedbackType_Notification_Success];
//
//        [HUD dismissAfterDelay:1.5f];
//    }];
//    [alertController addAction:copy];
//
//    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
//    [alertController addAction:cancel];
//
//    [[Launcher activeViewController] presentViewController:alertController animated:YES completion:nil];
//}

- (void)setStyleAsBubble:(BOOL)styleAsBubble {
    if (styleAsBubble != _styleAsBubble) {
        _styleAsBubble = styleAsBubble;
        
        [self update];
    }
}
- (void)update {
    CGSize constraints = CGSizeMake(self.frame.size.width, CGFLOAT_MAX);
    CGSize messageSize = [PostTextView sizeOfBubbleWithMessage:self.messageLabel.text withConstraints:constraints font:self.messageLabel.font maxCharacters:self.entityBasedMaxCharacters styleAsBubble:self.styleAsBubble];
        
    if (self.styleAsBubble) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, ceilf(messageSize.width), ceilf(messageSize.height));
    }
    else {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, ceilf(messageSize.height));
    }
    
    self.messageLabel.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    [self.messageLabel layoutSubviews];
}
- (void)setMessage:(NSString *)message entities:(NSArray<PostEntity *><PostEntity> * _Nullable)entities {
    // don't run if this has already been set
    if ([message isEqualToString:_message] && entities == _entities) return;
    
    if (![message isEqualToString:_message]) {
        _message = [message gtm_stringByUnescapingFromHTML];
    }
    if (entities != _entities) {
        _entities = entities;
    }
    
    if (!entities || entities.count == 0) {
        self.entityBasedMaxCharacters = self.maxCharacters;
    }
    else {
        self.entityBasedMaxCharacters = [PostTextView entityBasedMaxCharactersForMessage:self.message maxCharacters:self.maxCharacters entities:entities];
    }
        
//    NSLog(@"self.maxCharacters = %ld", (long)self.maxCharacters);
//    NSLog(@"entity based max characters: %ld", (long)self.entityBasedMaxCharacters);
    
    if (message.length > self.entityBasedMaxCharacters) {
        NSLog(@"needs to be truncated");
        
        NSString *truncatedMessage = [[[message substringToIndex:self.entityBasedMaxCharacters] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAppendingString:@"... "];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:truncatedMessage attributes:@{NSFontAttributeName: self.messageLabel.font, NSForegroundColorAttributeName: self.textColor}];
                
        NSAttributedString *seeMore = [[NSAttributedString alloc] initWithString:@"See More" attributes:@{NSFontAttributeName: self.messageLabel.font, NSForegroundColorAttributeName: [self.textColor colorWithAlphaComponent:0.7]}];
        
        [attributedString appendAttributedString:seeMore];

        self.messageLabel.attributedText = attributedString;
    }
    else if (message.length > 0) {
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:message attributes:@{NSFontAttributeName: self.messageLabel.font, NSForegroundColorAttributeName: self.textColor}];
        
        self.messageLabel.attributedText = attributedString;
    }
    else {
        self.messageLabel.text = @"";
    }
    
    // clear all entities
//    - (NSArray *)allDataDetectionHandlers;
//
//    - (void)addDataDetectionHandler:(id<JKRichTextViewDataDetectionHandler>)handler;
//
//    - (void)removeDataDetectionHandler:(id<JKRichTextViewDataDetectionHandler>)handler;
    for (id handler in [self.messageLabel allDataDetectionHandlers]) {
        [self.messageLabel removeDataDetectionHandler:handler];
    }
    if (entities && entities.count > 0) {
        [self addEntities];
    }
    
    [self update];
}
+ (NSInteger)entityBasedMaxCharactersForMessage:(NSString *)message maxCharacters:(NSInteger)maxCharacters entities:(NSArray <PostEntity *> <PostEntity> *)entities {
    NSInteger max = maxCharacters;
    if (!entities || entities.count == 0) {
        return maxCharacters;
    }
    
    for (PostEntity *entity in entities) {
        if ([entity.type isEqualToString:POST_ENTITY_TYPE_PROFILE]) {
            NSArray *usernameRanges = [message rangesForUsernameMatches];
            for (NSValue *value in usernameRanges) {
                NSRange range = [value rangeValue];
                if (maxCharacters >= range.location && maxCharacters <= range.location + range.length) {
                    max = range.location + range.length;
                }
            }
            
            continue;
        }
        
        if ([entity.type isEqualToString:POST_ENTITY_TYPE_CAMP]) {
            NSArray *campRanges = [message rangesForCampTagMatches];
            
            for (NSValue *value in campRanges) {
                NSRange range = [value rangeValue];
                if (maxCharacters >= range.location && maxCharacters <= range.location + range.length) {
                    max = range.location + range.length;
                }
            }
            
            continue;
        }
        
        if ([entity.type isEqualToString:POST_ENTITY_TYPE_URL] && entity.indices.count == 2) {
            NSInteger location = [entity.indices[0] integerValue];
            NSInteger length = [entity.indices[1] integerValue] - [entity.indices[0] integerValue];
            
//            NSLog(@"location: %ld", (long)location);
//            NSLog(@"max characters: %ld", (long)maxCharacters);
//            NSLog(@"location + length: %ld", location + length);
            
            if (maxCharacters >= location && maxCharacters <= location + length) {
                max = location + length;
            }
            
            continue;
        }
    }
    
    return max;
}

- (void)addEntities {
    if (!self.message || self.message.length == 0 || !self.entities || self.entities.count == 0) return;
    
    [self.messageLabel.textStorage removeAttribute:NSLinkAttributeName range:NSMakeRange(0, self.messageLabel.text.length)];
    
    for (PostEntity *entity in self.entities) {
        if ([entity.type isEqualToString:POST_ENTITY_TYPE_PROFILE]) {
            NSArray *usernameRanges = [self.message rangesForUsernameMatches];
            for (NSValue *value in usernameRanges) {
                NSRange range = [value rangeValue];
                NSURL *url;
                
                #ifdef DEBUG
                url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://user?username=%@", LOCAL_APP_URI, [[self.message substringWithRange:range] stringByReplacingOccurrencesOfString:@"@" withString:@""]]];
                #else
                url = [NSURL URLWithString:entity.actionUrl];
                #endif
                
                if (range.length + range.location <= self.entityBasedMaxCharacters && range.length + range.location <= self.message.length) {
                    [self.messageLabel setCustomLink:url forTextAtRange:range];
                }
            }
            
            continue;
        }
        
        if ([entity.type isEqualToString:POST_ENTITY_TYPE_CAMP]) {
            NSArray *campRanges = [self.message rangesForCampTagMatches];

            for (NSValue *value in campRanges) {
                NSRange range = [value rangeValue];
                NSURL *url;
                
                #ifdef DEBUG
                url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://camp?display_id=%@", LOCAL_APP_URI, [[self.message substringWithRange:range] stringByReplacingOccurrencesOfString:@"#" withString:@""]]];
                #else
                url = [NSURL URLWithString:entity.actionUrl];
                #endif
                                
                if (range.length + range.location <= self.entityBasedMaxCharacters && range.length + range.location <= self.message.length) {
                    [self.messageLabel setCustomLink:url forTextAtRange:range];
                }
            }
            
            continue;
        }
        
        if ([entity.type isEqualToString:POST_ENTITY_TYPE_URL] && entity.indices.count == 2) {
            NSInteger loc1 = [entity.indices[0] integerValue];
            NSInteger len1 = [entity.indices[1] integerValue] - [entity.indices[0] integerValue];
            NSRange range = [self.message composedRangeWithRange:NSMakeRange(loc1, len1)];
            NSInteger endSpot = range.location + range.length;
            
            if (endSpot <= self.entityBasedMaxCharacters && endSpot > range.location && endSpot <= self.message.length && range.location >= 0 && [NSURL URLWithString:entity.actionUrl]) {
                [self.messageLabel setCustomLink:[NSURL URLWithString:entity.actionUrl] forTextAtRange:range];
            }
            
            continue;
        }
    }
}

-(void)singleTap:(UITapGestureRecognizer*)tap
{
    if (UIGestureRecognizerStateEnded == tap.state)
    {
        // NSLog(@"single tap!");
    }
}

-(void)doubleTap:(UITapGestureRecognizer*)tap
{
    if (UIGestureRecognizerStateEnded == tap.state)
    {
        [self.delegate postTextViewDidDoubleTap:self];
    }
}
//
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
//    CGPoint location = [touch locationInView:self.messageLabel];
//    
//    return ![self.messageLabel containslinkAtPoint:location];
//}

+ (CGSize)sizeOfBubbleWithMessage:(NSString *)message withConstraints:(CGSize)constraints font:(UIFont *)font maxCharacters:(CGFloat)maxCharacters styleAsBubble:(BOOL)styleAsBubble {
    if (message.length == 0) return CGSizeZero;
    
    NSMutableAttributedString *attributedMessage;
    if (message.length > maxCharacters) {
        attributedMessage = [[NSMutableAttributedString alloc] initWithString:[[[message  substringToIndex:maxCharacters] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAppendingString:@"... "] attributes:@{NSFontAttributeName: font}];
        
        NSAttributedString *seeMore = [[NSAttributedString alloc] initWithString:@"See More" attributes:@{NSFontAttributeName: font}];
        [attributedMessage appendAttributedString:seeMore];
        
    }
    else {
        attributedMessage = [[NSMutableAttributedString alloc] initWithString:message  attributes:@{NSFontAttributeName: font}];
    }
    
    CGSize size = [attributedMessage boundingRectWithSize:constraints options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil].size;
//     CGSize size2 = [TTTAttributedLabel sizeThatFitsAttributedString:attributedMessage withConstraints:constraints limitedToNumberOfLines:CGFLOAT_MAX];
    
    if (styleAsBubble) {
        return CGSizeMake(ceilf(size.width), ceilf(size.height));
    }
    else {
        return CGSizeMake(constraints.width, ceilf(size.height));
    }
}

@end
