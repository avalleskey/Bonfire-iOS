//
//  BFTipView.m
//  Pulse
//
//  Created by Austin Valleskey on 5/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFTipView.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "BFTipsManager.h"

@interface BFTipView ()

@property (nonatomic) CGPoint centerBegin;
@property (nonatomic) CGPoint centerFinal;

@end

@implementation BFTipView

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
- (id)initWithObject:(BFTipObject *)object {
    self = [super init];
    if (self) {
        [self setObject:object];
    }
    return self;
}

- (void)setup {
    self.frame = CGRectMake(12, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width - 24, 0);
    self.layer.cornerRadius = 14.f;
    self.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 1);
    self.layer.shadowRadius = 2.f;
    self.layer.shadowOpacity = 1;
    self.layer.masksToBounds = false;
        
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.blurView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.blurView.layer.cornerRadius = self.layer.cornerRadius;
    self.blurView.layer.masksToBounds = true;
    [self addSubview:self.blurView];
    
    self.closeButton = [[TappableButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 14 - 16, 0, 14, 14)];
    self.closeButton.padding = UIEdgeInsetsMake(12, 12, 12, 12);
    [self.closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeButton.contentMode = UIViewContentModeScaleAspectFill;
    [self.closeButton bk_whenTapped:^{
        [[BFTipsManager manager] hideAllTips];
    }];
    [self addSubview:self.closeButton];
    
    self.creatorAvatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(10, 10, 22, 22)];
    [self addSubview:self.creatorAvatarView];
    
    self.creatorTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.creatorAvatarView.frame.origin.x + self.creatorAvatarView.frame.size.width + 6, 10, 22, 22)];
    self.creatorTitleLabel.textColor = [UIColor bonfireSecondaryColor];
    self.creatorTitleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightMedium];
    [self addSubview:self.creatorTitleLabel];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.creatorAvatarView.frame.origin.x, self.creatorAvatarView.frame.origin.y + self.creatorAvatarView.frame.size.height + 8, self.frame.size.width - (self.creatorAvatarView.frame.origin.x * 2), 0)];
    self.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.titleLabel];
    
    self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + 4, self.titleLabel.frame.size.width, 0)];
    self.textLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
    self.textLabel.numberOfLines = 0;
    self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.textLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.textLabel];
    
    [self setStyle:BFTipViewStyleDark]; // set default style
    
    [self setupPanRecognizer];
    
    [self layoutSubviews];
}

- (void)setupPanRecognizer {
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [self addGestureRecognizer:panRecognizer];
}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.centerBegin = recognizer.view.center;
        self.centerFinal = CGPointMake(self.centerBegin.x, self.centerBegin.y + (self.frame.size.height * 2));
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self.superview];
        if (translation.y > 0 || recognizer.view.center.y >= self.centerBegin.y) {
            recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                                 recognizer.view.center.y + translation.y);
        }
        else {
            CGFloat newCenterY = recognizer.view.center.y + translation.y;
            CGFloat diff = fabs(_centerBegin.y - newCenterY);
            CGFloat max = 24;
            NSLog(@"diff: %f", diff);
            NSLog(@"percentage: %f", diff / max);
            CGFloat percentage = diff / max;
            if (percentage > 1) {
                percentage = 1;
            }
            newCenterY = recognizer.view.center.y + (translation.y / (1 + 10 * percentage));
            NSLog(@"newcentery: %f", newCenterY);
            recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                                 newCenterY);
        }
        [recognizer setTranslation:CGPointMake(0, 0) inView:self.superview];
        
        CGFloat percentage = (recognizer.view.center.y - self.centerBegin.y) / (self.centerFinal.y - self.centerBegin.y);
        
        if (percentage > 0) {
            //recognizer.view.transform = CGAffineTransformMakeScale(1.0 - (1.0 - 0.8) * percentage, 1.0 - (1.0 - 0.8) * percentage);
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:self.superview];
        
        CGFloat fromCenterY = fabs(self.centerBegin.y - recognizer.view.center.y);
        NSLog(@"from Center Y: %f", fromCenterY);
        CGFloat duration = 0.15+(0.05*(fromCenterY/60));
        NSLog(@"duration:: %f", duration);
        
        NSLog(@"velocity.y: %f", velocity.y);
        if (velocity.y > 400) {
            [[BFTipsManager manager] hideAllTips];
        }
        else {
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                recognizer.view.center = self.centerBegin;
                recognizer.view.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
    }
    
}

- (void)setObject:(BFTipObject *)object {
    if (object != _object) {
        _object = object;
        
        if (object.creatorType == BFTipCreatorTypeCamp) {
            self.creatorAvatarView.camp = object.creator;
        }
        else if (object.creatorType == BFTipCreatorTypeUser) {
            self.creatorAvatarView.user = object.creator;
        }
        else {
            self.creatorAvatarView.camp = nil;
            self.creatorAvatarView.user = nil;
            
            if (object.creatorAvatar) {
                self.creatorAvatarView.imageView.image = object.creatorAvatar;
            }
            else {
                self.creatorAvatarView.imageView.image = [UIImage imageNamed:@"Tip_Bonfire"];
            }
        }
        self.creatorTitleLabel.text = [_object.creatorText uppercaseString];
        
        self.titleLabel.hidden = (_object.title.length == 0);
        if (![self.titleLabel isHidden]) {
            self.titleLabel.text = _object.title;
        }
        
        self.textLabel.text = _object.text;
        
        [self layoutSubviews];
        
        self.frame = CGRectMake(self.frame.origin.x, [UIScreen mainScreen].bounds.size.height, self.frame.size.width, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 12);
        self.blurView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
        [self bk_removeAllBlockObservers];
        if (object.action) {
            [self bk_whenTapped:^{
                [[BFTipsManager manager] hideAllTips];
                
                object.action();
            }];
        }
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
        
    if (self.transform.a == 1) {
        self.closeButton.frame = CGRectMake(self.frame.size.width - self.closeButton.frame.size.width - 16, self.creatorAvatarView.frame.origin.y + (self.creatorAvatarView.frame.size.height / 2) - (self.closeButton.frame.size.height / 2), self.closeButton.frame.size.width, self.closeButton.frame.size.height);
        self.creatorTitleLabel.frame = CGRectMake(self.creatorTitleLabel.frame.origin.x, self.creatorAvatarView.frame.origin.y, (self.closeButton.frame.origin.x - 6) - self.creatorTitleLabel.frame.origin.x, self.creatorAvatarView.frame.size.height);
        
        if (![self.titleLabel isHidden]) {
            CGSize titleSize = [self.titleLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (self.titleLabel.frame.origin.x * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:self.titleLabel.font} context:nil].size;
            self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, self.titleLabel.frame.origin.y, self.frame.size.width - (self.titleLabel.frame.origin.x * 2), ceilf(titleSize.height));
        }
        
        CGSize textSize = [self.textLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - (self.textLabel.frame.origin.x * 2), CGFLOAT_MAX) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:self.textLabel.font} context:nil].size;
        self.textLabel.frame = CGRectMake(self.textLabel.frame.origin.x, self.titleLabel.frame.origin.y + ([self.titleLabel isHidden] ? 0 : self.titleLabel.frame.size.height + 4), self.frame.size.width - (self.textLabel.frame.origin.x * 2), ceilf(textSize.height));
    }
}

- (void)setStyle:(BFTipViewStyle)style {
    if (style == BFTipViewStyleDark) {
        self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.blurView.backgroundColor = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.3];
        self.closeButton.tintColor = [UIColor bonfireSecondaryColor];
        
        self.titleLabel.textColor = [UIColor whiteColor];
        self.textLabel.textColor = [UIColor whiteColor];
    }
    else {
        self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.blurView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
        self.closeButton.tintColor = [UIColor bonfireSecondaryColor];
        
        self.titleLabel.textColor = [UIColor blackColor];
        self.textLabel.textColor = [UIColor blackColor];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.object.action) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.transform = CGAffineTransformMakeScale(0.95, 0.95);
        } completion:nil];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
        self.alpha = 1;
    } completion:nil];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
        self.alpha = 1;
    } completion:nil];
}

@end

@implementation BFTipObject

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}
+ (BFTipObject *)tipWithCreatorType:(BFTipCreatorType)creatorType creator:(id _Nullable)creator title:(NSString * _Nullable)title text:(NSString *)text action:(void (^ __nullable)(void))actionHandler {
    BFTipObject *tipObject = [[BFTipObject alloc] init];
    
    tipObject.creatorType = creatorType;
    tipObject.creator = creator;
    
    switch (creatorType) {
        case BFTipCreatorTypeBonfireGeneric: {
            tipObject.creatorText = @"Bonfire";
            tipObject.creatorAvatar  = [UIImage imageNamed:@"Tip_Bonfire"];
            break;
        }
        case BFTipCreatorTypeBonfireTip: {
            tipObject.creatorText = @"Bonfire Tips";
            tipObject.creatorAvatar  = [UIImage imageNamed:@"Tip_Bonfire"];
            break;
        }
        case BFTipCreatorTypeBonfireFunFacts: {
            tipObject.creatorText = @"Bonfire Fun Facts";
            tipObject.creatorAvatar  = [UIImage imageNamed:@"Tip_Bonfire"];
            break;
        }
        case BFTipCreatorTypeBonfireSupport: {
            tipObject.creatorText = @"Bonfire Support";
            tipObject.creatorAvatar  = [UIImage imageNamed:@"Tip_BonfireSupport"];
            break;
        }
        case BFTipCreatorTypeCamp: {
            if ([creator isKindOfClass:[Camp class]]) {
                Camp *campCreator = (Camp *)creator;
                tipObject.creator = campCreator;
                tipObject.creatorText = [NSString stringWithFormat:@"%@", campCreator.attributes.details.title];
                
                break;
            }
        }
        case BFTipCreatorTypeUser: {
            if ([creator isKindOfClass:[User class]]) {
                User *userCreator = (User *)creator;
                tipObject.creator = userCreator;
                tipObject.creatorText = [NSString stringWithFormat:@"%@", userCreator.attributes.details.displayName];
                break;
            }
        }
            
        default:
            tipObject.creatorText = @"Bonfire";
            break;
    }
    
    tipObject.title = title;
    tipObject.text = text;
    
    tipObject.action = actionHandler;
    
    return tipObject;
}

@end
