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

        self.translatesAutoresizingMaskIntoConstraints = YES;
        
        _messageLabel = [[TTTAttributedLabel alloc] initWithFrame:frame];
        _messageLabel.extendsLinkTouchArea = false;
        _messageLabel.userInteractionEnabled = true;
        _messageLabel.font = textViewFont;
        _messageLabel.textColor = [UIColor colorNamed:@"FullContrastColor"];
        _messageLabel.backgroundColor = [UIColor clearColor];
        _messageLabel.numberOfLines = 0;
        _messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _messageLabel.delegate = self;
        //_messageLabel.translatesAutoresizingMaskIntoConstraints = YES;
        
        NSMutableDictionary *mutableActiveLinkAttributes = [NSMutableDictionary dictionary];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithBool:NO] forKey:(NSString *)kCTUnderlineStyleAttributeName];
        [mutableActiveLinkAttributes setValue:(__bridge id)[[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.1f] CGColor] forKey:(NSString *)kTTTBackgroundFillColorAttributeName];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithFloat:4.0f] forKey:(NSString *)kTTTBackgroundCornerRadiusAttributeName];
        [mutableActiveLinkAttributes setValue:[NSNumber numberWithFloat:0] forKey:(NSString *)kTTTBackgroundLineWidthAttributeName];
        _messageLabel.activeLinkAttributes = mutableActiveLinkAttributes;
        
        // update tint color
        NSMutableDictionary *mutableLinkAttributes = [NSMutableDictionary dictionary];
        [mutableLinkAttributes setObject:[UIColor linkColor] forKey:(__bridge NSString *)kCTForegroundColorAttributeName];
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
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if ([url.scheme isEqualToString:LOCAL_APP_URI]) {
            // local url
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                // NSLog(@"opened url!");
            }];
        }
        else {
            // extern url
            [Launcher openURL:url.absoluteString];
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
        
        [HUD showInView:[Launcher activeViewController].view animated:YES];
        [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        
        [HUD dismissAfterDelay:1.5f];
    }];
    [alertController addAction:copy];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancel];
    
    [[Launcher activeViewController] presentViewController:alertController animated:YES completion:nil];
}

- (void)update {
    CGFloat messageHeight = [PostTextView sizeOfBubbleWithMessage:self.messageLabel.text withConstraints:CGSizeMake(self.frame.size.width, CGFLOAT_MAX) font:self.messageLabel.font maxCharacters:self.entityBasedMaxCharacters].height;
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, messageHeight);
    
    self.messageLabel.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

- (void)setMessage:(NSString *)message entities:(NSArray<PostEntity *><PostEntity> *)entities {
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
                
        NSAttributedString *seeMore = [[NSAttributedString alloc] initWithString:@"See More" attributes:@{NSFontAttributeName: self.messageLabel.font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];

        [self.messageLabel setText:truncatedMessage afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            [mutableAttributedString appendAttributedString:seeMore];
            
            return mutableAttributedString;
        }];
    }
    else {
        //NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:message attributes:@{NSFontAttributeName: self.messageLabel.font, NSForegroundColorAttributeName: [UIColor colorNamed:@"FullContrastColor"]}];
                
        [self.messageLabel setText:message afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
            return mutableAttributedString;
        }];
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
    if (self.message.length == 0 || !self.entities || self.entities.count == 0) return;
    
    for (PostEntity *entity in self.entities) {
        if ([entity.type isEqualToString:POST_ENTITY_TYPE_PROFILE]) {
            NSArray *usernameRanges = [self.message rangesForUsernameMatches];
            for (NSValue *value in usernameRanges) {
                NSRange range = [value rangeValue];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://user?username=%@", LOCAL_APP_URI, [[self.message substringWithRange:range] stringByReplacingOccurrencesOfString:@"@" withString:@""]]];
                
                if (range.length + range.location <= self.entityBasedMaxCharacters && range.length + range.location <= self.message.length) {
                    [self.messageLabel addLinkToURL:url withRange:range];
                }
            }
            
            continue;
        }
        
        if ([entity.type isEqualToString:POST_ENTITY_TYPE_CAMP]) {
            NSArray *campRanges = [self.message rangesForCampTagMatches];

            for (NSValue *value in campRanges) {
                NSRange range = [value rangeValue];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://camp?display_id=%@", LOCAL_APP_URI, [[self.message substringWithRange:range] stringByReplacingOccurrencesOfString:@"#" withString:@""]]];
                if (range.length + range.location <= self.entityBasedMaxCharacters && range.length + range.location <= self.message.length) {
                    [self.messageLabel addLinkToURL:url withRange:range];
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
                
                TTTAttributedLabelLink *link = [[TTTAttributedLabelLink alloc] initWithAttributesFromLabel:self.messageLabel textCheckingResult:[NSTextCheckingResult linkCheckingResultWithRange:range URL:[NSURL URLWithString:entity.actionUrl]]];
                [link setLinkLongPressBlock:^(TTTAttributedLabel *label, TTTAttributedLabelLink *link) {
                    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL URLWithString:entity.actionUrl]] applicationActivities:nil];
                    [[Launcher topMostViewController] presentViewController:activityViewController animated:YES completion:nil];
                }];
                [self.messageLabel addLink:link];
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint location = [touch locationInView:self.messageLabel];
    
    return ![self.messageLabel containslinkAtPoint:location];
}

+ (CGSize)sizeOfBubbleWithMessage:(NSString *)message withConstraints:(CGSize)constraints font:(UIFont *)font maxCharacters:(CGFloat)maxCharacters {
    if (message.length == 0) return CGSizeZero;
    
    if (message.length > maxCharacters) {
        NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:[[[message  substringToIndex:maxCharacters] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByAppendingString:@"... "] attributes:@{NSFontAttributeName: font}];
        
        NSAttributedString *seeMore = [[NSAttributedString alloc] initWithString:@"See More" attributes:@{NSFontAttributeName: textViewFont}];
        [attributedMessage appendAttributedString:seeMore];
        
//        CGSize size = [TTTAttributedLabel sizeThatFitsAttributedString:attributedMessage withConstraints:constraints limitedToNumberOfLines:CGFLOAT_MAX];
        
        CGSize size = [attributedMessage boundingRectWithSize:constraints options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil].size;
        
        return CGSizeMake(constraints.width, ceilf(size.height));
    }
    else {
        NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:message  attributes:@{NSFontAttributeName: font}];
        
        CGSize size = [attributedMessage boundingRectWithSize:constraints options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil].size;
        
//        CGSize size = [TTTAttributedLabel sizeThatFitsAttributedString:attributedMessage withConstraints:constraints limitedToNumberOfLines:CGFLOAT_MAX];
        
        return CGSizeMake(constraints.width, ceilf(size.height));
    }
}

@end
