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
#import <JGProgressHUD.h>
#import <HapticHelper/HapticHelper.h>
#import "UIColor+Palette.h"

#define TWUValidUsername                @"[@][a-z0-9_]{1,20}"
#define TWUValidCampDisplayId           @"[#][a-z0-9_]{1,30}"

@implementation PostTextView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = true;
        self.layer.masksToBounds = false;
        
        self.edgeInsets = UIEdgeInsetsZero;

        self.translatesAutoresizingMaskIntoConstraints = YES;
        
        _messageLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];
        _messageLabel.extendsLinkTouchArea = false;
        _messageLabel.userInteractionEnabled = true;
        _messageLabel.font = textViewFont;
        _messageLabel.textColor = [UIColor colorWithWhite:0 alpha:1];
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.numberOfLines = 0;
        _messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _messageLabel.enabledTextCheckingTypes = (NSTextCheckingTypeLink);
        _messageLabel.delegate = self;
        
        NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithBool:NO] forKey:(NSString *)kCTUnderlineStyleAttributeName];
        [mutableActiveLinkAttributes setValue:(__bridge id)[[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.1f] CGColor] forKey:(NSString *)kTTTBackgroundFillColorAttributeName];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithFloat:4.0f] forKey:(NSString *)kTTTBackgroundCornerRadiusAttributeName];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithFloat:0] forKey:(NSString *)kTTTBackgroundLineWidthAttributeName];
        _messageLabel.activeLinkAttributes = mutableActiveLinkAttributes;
        
        // update tint color
        NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
        [mutableLinkAttributes setObject:[UIColor bonfireBlue] forKey:(__bridge NSString *)kCTForegroundColorAttributeName];
        _messageLabel.linkAttributes = mutableLinkAttributes;
        
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

- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url {
    NSLog(@"did select link with url: %@", url);
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if ([url.scheme isEqualToString:@"bonfireapp"]) {
            // local url
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                NSLog(@"opened url!");
            }];
        }
        else {
            // extern url
            [[Launcher sharedInstance] openURL:url.absoluteString];
        }
    }
}
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithPhoneNumber:(NSString *)phoneNumber {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:phoneNumber message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", phoneNumber]];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        UIAlertAction *call = [UIAlertAction actionWithTitle:@"Call Phone Number" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        }];
        [alertController addAction:call];
    }
    
    UIAlertAction *copy = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = phoneNumber;
        
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
        HUD.textLabel.text = @"Copied Phone Number!";
        HUD.vibrancyEnabled = false;
        HUD.animation = [[JGProgressHUDFadeZoomAnimation alloc] init];
        HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
        
        [HUD showInView:[[Launcher sharedInstance] activeViewController].view animated:YES];
        [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        
        [HUD dismissAfterDelay:1.5f];
    }];
    [alertController addAction:copy];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancel];
    
    [[[Launcher sharedInstance] activeViewController] presentViewController:alertController animated:YES completion:nil];
}

- (void)update {
    // resize
    CGSize messageSize = [PostTextView sizeOfBubbleWithMessage:self.message withConstraints:CGSizeMake(self.frame.size.width-(self.edgeInsets.left+self.edgeInsets.right), CGFLOAT_MAX) font:self.messageLabel.font];
    
    CGFloat width = (UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, self.edgeInsets) ? self.frame.size.width : messageSize.width + self.edgeInsets.left + self.edgeInsets.right);
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, messageSize.height + self.edgeInsets.top + self.edgeInsets.bottom);
    _messageLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.messageLabel.frame = CGRectMake(self.edgeInsets.left, self.edgeInsets.top, messageSize.width, messageSize.height);
}

- (void)setMessage:(NSString *)message {
    if (message != _message) {
        _message = message;
        
        self.messageLabel.text = message;
        
        NSRegularExpression *usernameRegex = [[NSRegularExpression alloc] initWithPattern:TWUValidUsername options:NSRegularExpressionCaseInsensitive error:nil];
        for (NSTextCheckingResult* match in [usernameRegex matchesInString:self.message options:0 range:NSMakeRange(0, [self.message length])]) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"bonfireapp://user?username=%@", [[self.message substringWithRange:match.range] stringByReplacingOccurrencesOfString:@"@" withString:@""]]];
            [self.messageLabel addLinkToURL:url withRange:match.range];
        }
        
        NSRegularExpression *campRegex = [[NSRegularExpression alloc] initWithPattern:TWUValidCampDisplayId options:NSRegularExpressionCaseInsensitive error:nil];
        for (NSTextCheckingResult* match in [campRegex matchesInString:self.message options:0 range:NSMakeRange(0, [self.message length])]) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"bonfireapp://camp?display_id=%@", [[self.message substringWithRange:match.range] stringByReplacingOccurrencesOfString:@"#" withString:@""]]];
            [self.messageLabel addLinkToURL:url withRange:match.range];
        }
    }
}

-(void)singleTap:(UITapGestureRecognizer*)tap
{
    if (UIGestureRecognizerStateEnded == tap.state)
    {
        NSLog(@"single tap!");
    }
}

-(void)doubleTap:(UITapGestureRecognizer*)tap
{
    if (UIGestureRecognizerStateEnded == tap.state)
    {
        [self.delegate postTextViewDidDoubleTap:self];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint location = [touch locationInView:self.messageLabel];
    
    return ![self.messageLabel containslinkAtPoint:location];
}

+ (CGSize)sizeOfBubbleWithMessage:(NSString *)text withConstraints:(CGSize)constraints font:(UIFont *)font {
    TTTAttributedLabel *label = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, 0, constraints.width, constraints.height)];
    label.font = font;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.text = text;
    
    CGSize size = [TTTAttributedLabel sizeThatFitsAttributedString:label.attributedText withConstraints:constraints limitedToNumberOfLines:CGFLOAT_MAX];
    
    return CGSizeMake(ceilf(size.width), ceilf(size.height));
}

@end
