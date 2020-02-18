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
#import  <UIImageView+WebCache.h>
#import "Launcher.h"

@interface BFTipView ()

@property (nonatomic) CGPoint centerBegin;
@property (nonatomic) CGPoint centerFinal;

@end

@implementation BFTipView

- (id)init {
    self = [super init];
    if (self) {
        // [self setup];
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
    self.layer.shadowOffset = CGSizeMake(0, 1.5);
    self.layer.shadowRadius = 1.f;
    self.layer.shadowOpacity = 1;
    self.layer.masksToBounds = false;
    
    self.dragToDismiss = true;
        
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    self.blurView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.blurView.layer.cornerRadius = self.layer.cornerRadius;
    self.blurView.layer.masksToBounds = true;
    [self addSubview:self.blurView];
    
    self.closeButton = [[TappableButton alloc] initWithFrame:CGRectMake(self.frame.size.width - 14 - 16, 0, 14, 14)];
    self.closeButton.padding = UIEdgeInsetsMake(12, 12, 12, 12);
    [self.closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeButton.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:self.closeButton];
    
    self.creatorAvatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(10, 10, 24, 24)];
    [self addSubview:self.creatorAvatarView];
    
    self.creatorTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.creatorAvatarView.frame.origin.x + self.creatorAvatarView.frame.size.width + 6, 10, 22, 22)];
    self.creatorTitleLabel.textColor = [UIColor bonfireSecondaryColor];
    self.creatorTitleLabel.font = [UIFont systemFontOfSize:12.f weight:UIFontWeightMedium];
    [self addSubview:self.creatorTitleLabel];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.creatorAvatarView.frame.origin.x, self.creatorAvatarView.frame.origin.y + self.creatorAvatarView.frame.size.height + 12, self.frame.size.width - (self.creatorAvatarView.frame.origin.x * 2), 0)];
    self.titleLabel.font = [UIFont systemFontOfSize:17.f weight:UIFontWeightBold];
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
    
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 16, self.frame.size.width, 120)];
    self.imageView.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.08];
    self.imageView.hidden = true;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = true;
    self.imageView.userInteractionEnabled = true;
    [self addSubview:self.imageView];
    
    self.cta = [UIButton buttonWithType:UIButtonTypeSystem];
    self.cta.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
    [self.cta setTitle:@"CTA" forState:UIControlStateNormal];
    [self.cta setTitleColor:[UIColor bonfireBrand] forState:UIControlStateNormal];
    UIView *ctaSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.titleLabel.frame.origin.x, 0, self.frame.size.width - (self.titleLabel.frame.origin.x * 2), HALF_PIXEL)];
    ctaSeparator.backgroundColor = [UIColor colorNamed:@"FullContrastColor"];
    ctaSeparator.alpha = 0.08;
    ctaSeparator.tag = 99;
    [self.cta bk_whenTapped:^{
        if (self.object.action) {
            self.object.action();
        }
    }];
    [self.cta addSubview:ctaSeparator];
    [self addSubview:self.cta];
    
    [self setStyle:BFTipViewStyleDark]; // set default style
    
    [self setupPanRecognizer];
    
    [self layoutSubviews];
}
- (void)setDragToDismiss:(BOOL)dragToDismiss {
    if (dragToDismiss != _dragToDismiss) {
        _dragToDismiss = dragToDismiss;
    }
    
    if (dragToDismiss && self.gestureRecognizers.count == 0) {
        [self setupPanRecognizer];
    }
    else if (!dragToDismiss && self.gestureRecognizers.count > 0) {
        for (UIGestureRecognizer *recognizer in self.gestureRecognizers) {
            [self removeGestureRecognizer:recognizer];
        }
    }
}
- (void)setupPanRecognizer {
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [self addGestureRecognizer:panRecognizer];
}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (!self.dragToDismiss) return;
    
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
            CGFloat percentage = diff / max;
            if (percentage > 1) {
                percentage = 1;
            }
            newCenterY = recognizer.view.center.y + (translation.y / (1 + 10 * percentage));

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
        CGFloat duration = 0.15+(0.05*(fromCenterY/60));
        
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
        
        CGFloat bottomY = self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 16;
        if (![self.imageView isHidden]) {
            self.imageView.frame = CGRectMake(0, bottomY, self.frame.size.width, self.imageView.frame.size.height);
            bottomY = self.imageView.frame.origin.y + self.imageView.frame.size.height + 12;
        }
        
        if (![self.cta isHidden]) {
            self.cta.frame = CGRectMake(0, bottomY, self.frame.size.width, 48);
            
            UIView *separator = [self.cta viewWithTag:99];
            separator.frame = CGRectMake(self.titleLabel.frame.origin.x, separator.frame.origin.y, self.frame.size.width - (self.titleLabel.frame.origin.x * 2), separator.frame.size.height);
        }
    }
    
    // added here for dark mode compatability
    self.layer.borderColor = [UIColor tableViewSeparatorColor].CGColor;
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
                
        [self.cta setTitle:self.object.cta forState:UIControlStateNormal];
        self.cta.hidden = self.cta.currentTitle.length == 0;
        
        self.imageView.hidden = self.object.imageUrl.length == 0;
        if (![self.imageView isHidden]) {
            [self.imageView sd_setImageWithURL:[NSURL URLWithString:self.object.imageUrl]];
            [self.imageView bk_whenTapped:^{
                [Launcher expandImageView:self.imageView];
            }];
        }
        
        [self layoutSubviews];
        
        if ([self.cta isHidden]) {
            self.frame = CGRectMake(self.frame.origin.x, [UIScreen mainScreen].bounds.size.height, self.frame.size.width, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 12);
        }
        else {
            self.frame = CGRectMake(self.frame.origin.x, [UIScreen mainScreen].bounds.size.height, self.frame.size.width, self.cta.frame.origin.y + self.cta.frame.size.height);
        }
        self.blurView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        
        [self bk_removeAllBlockObservers];
        if (object.action) {
            [self bk_whenTapped:^{
                if (self.cta.currentTitle.length == 0 && object.action) {
                    [[BFTipsManager manager] hideAllTips];
                    
                    object.action();
                }
            }];
        }
    }
}

- (void)setStyle:(BFTipViewStyle)style {
    if (style == BFTipViewStyleDark) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.shadowOpacity = 1;
        self.layer.borderWidth = 0;
        
        self.blurView.alpha = 1;
        self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.blurView.backgroundColor = [[UIColor bonfirePrimaryColor] colorWithAlphaComponent:0.3];
        self.closeButton.tintColor = [UIColor bonfireSecondaryColor];
        
        self.titleLabel.textColor = [UIColor whiteColor];
        self.textLabel.textColor = [UIColor whiteColor];
        [self.cta setTitleColor:[UIColor bonfireBrand] forState:UIControlStateNormal];
    }
    else if (style == BFTipViewStyleTable) {
        self.backgroundColor = [UIColor contentBackgroundColor];
        self.layer.shadowOpacity = 1;
        self.layer.borderWidth = HALF_PIXEL;
        
        self.blurView.alpha = 0;
        
        self.titleLabel.textColor = [UIColor bonfirePrimaryColor];
        self.textLabel.textColor = [UIColor bonfireSecondaryColor];
        [self.cta setTitleColor:[UIColor bonfireBrand] forState:UIControlStateNormal];
    }
    else {
        self.backgroundColor = [UIColor clearColor];
        self.layer.shadowOpacity = 1;
        self.layer.borderWidth = 0;
        
        self.blurView.alpha = 0;
        self.blurView.effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.blurView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.5];
        self.closeButton.tintColor = [UIColor bonfireSecondaryColor];
        
        self.titleLabel.textColor = [UIColor blackColor];
        self.textLabel.textColor = [UIColor blackColor];
        [self.cta setTitleColor:[UIColor bonfireBrand] forState:UIControlStateNormal];
    }
    
    self.creatorTitleLabel.textColor = self.textLabel.textColor;
    self.closeButton.tintColor = self.textLabel.textColor;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.cta.currentTitle.length == 0) {
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
+ (BFTipObject *)tipWithCreatorType:(BFTipCreatorType)creatorType creator:(id _Nullable)creator title:(NSString * _Nullable)title text:(NSString *)text cta:(NSString * _Nullable)cta imageUrl:(NSString * _Nullable)imageUrl action:(void (^ __nullable)(void))actionHandler {
    BFTipObject *tipObject = [[BFTipObject alloc] init];
    
    tipObject.creatorType = creatorType;
    tipObject.creator = creator;
    tipObject.cta = cta;
    tipObject.imageUrl = imageUrl;
    
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
                tipObject.creatorText = [NSString stringWithFormat:@"%@", campCreator.attributes.title];
                
                break;
            }
        }
        case BFTipCreatorTypeUser: {
            if ([creator isKindOfClass:[User class]]) {
                User *userCreator = (User *)creator;
                tipObject.creator = userCreator;
                tipObject.creatorText = [NSString stringWithFormat:@"%@", userCreator.attributes.displayName];
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
