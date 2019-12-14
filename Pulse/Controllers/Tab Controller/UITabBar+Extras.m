//
//  UITabBar+Extras.m
//  Pulse
//
//  Created by Austin Valleskey on 12/12/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "UITabBar+Extras.h"
#import "UIColor+Palette.h"
#import "Session.h"

@implementation UITabBar (Extras)

- (id)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup {
    DLog(@"setup!");
    
    self.tabIndicator = [[UIView alloc] initWithFrame:CGRectMake(20, 0, 22, 3)];
    self.tabIndicator.layer.cornerRadius = self.tabIndicator.frame.size.height / 2;
    self.tabIndicator.backgroundColor = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[Session sharedInstance].currentUser.attributes.color];
    self.tabIndicator.alpha = 0;
    [self addSubview:self.tabIndicator];
    
    [self setBackgroundImage:[UIImage new]];
    [self setShadowImage:[UIImage new]];
    [self setTranslucent:true];
    self.layer.borderWidth = 0.0f;
    [self setBarTintColor:[UIColor colorNamed:@"FullContrastColor_inverted"]];
    [self setTintColor:[UIColor bonfireBrand]];
    [[UITabBar appearance] setShadowImage:nil];
    
    self.currentUserAvatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    self.currentUserAvatar.userInteractionEnabled = false;
    self.currentUserAvatar.user = [Session sharedInstance].currentUser;
    for (id interaction in self.currentUserAvatar.interactions) {
        if (@available(iOS 13.0, *)) {
            if ([interaction isKindOfClass:[UIContextMenuInteraction class]]) {
                [self.currentUserAvatar removeInteraction:interaction];
            }
        }
    }
        
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent]];
    self.blurView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.blurView.backgroundColor = [UIColor colorNamed:@"FullContrastColor_inverted"];
    self.blurView.contentView.backgroundColor = [UIColor clearColor];
    self.blurView.layer.masksToBounds = true;
    self.blurView.tintColor = [UIColor clearColor];
    [self insertSubview:self.blurView atIndex:0];

    // tab bar hairline
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    separator.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.12f];
    [self addSubview:separator];
    
    self.clipsToBounds = true;
    self.tintColor = [UIColor bonfirePrimaryColor];
}

-(CGSize)sizeThatFits:(CGSize)size
{
    CGSize sizeThatFits;
    if (IS_IPAD) {
        sizeThatFits = [super sizeThatFits:size];
        sizeThatFits.height = 52 + ([[UIApplication sharedApplication] keyWindow].safeAreaInsets.bottom);
    }
    else {
        sizeThatFits = [super sizeThatFits:size];
            sizeThatFits.height = 52 + ([[UIApplication sharedApplication] keyWindow].safeAreaInsets.bottom);
    }

    return sizeThatFits;
}

//- (void)setItems:(NSArray<UITabBarItem *> *)items {
//    [super setItems:items];
//
//    [self alignViews];
//}
//- (void)setSelectedItem:(UITabBarItem *)selectedItem {
//    [super setSelectedItem:selectedItem];
//}

- (void)alignViews {
    UIView *tabBarItemView = [self viewForTabWithIndex:0];
    UIImageView *tabBarImageView = nil;
    for (UIImageView *subview in [tabBarItemView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            tabBarImageView = subview;
            break;
        }
    }
            
    self.tabIndicator.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarImageView.frame.origin.x + (tabBarImageView.frame.size.width * .25), 0, tabBarImageView.frame.size.width / 2, 3);
    [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.35f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.tabIndicator.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarImageView.frame.origin.x, 0, tabBarImageView.frame.size.width, 3);
        self.tabIndicator.layer.cornerRadius = self.tabIndicator.frame.size.height / 2;
        self.tabIndicator.alpha = 1;
    } completion:nil];
    
    
    // align
    UIView *meTabBarItemView = [self viewForTabWithIndex:4];
    UIImageView *meTabBarImageView;
    for (UIImageView *subview in [meTabBarItemView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            meTabBarImageView = subview;
            break;
        }
    }
    self.currentUserAvatar.frame = CGRectMake(meTabBarItemView.frame.origin.x + meTabBarItemView.frame.size.width / 2 - 11, self.frame.origin.y + meTabBarItemView.frame.origin.y + meTabBarItemView.frame.size.height / 2 - 11, 22, 22);
}

- (UIView *)viewForTabWithIndex:(NSUInteger)index
{
    NSMutableArray *tabBarItems = [NSMutableArray arrayWithCapacity:[self.items count]];
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UITabBarButton")] && [view respondsToSelector:@selector(frame)]) {
            // check for the selector -frame to prevent crashes in the very unlikely case that in the future
            // objects that don't implement -frame can be subViews of an UIView
            [tabBarItems addObject:view];
        }
    }
    if ([tabBarItems count] == 0) {
        // no tabBarItems means either no UITabBarButtons were in the subView, or none responded to -frame
        // return CGRectZero to indicate that we couldn't figure out the frame
        return nil;
    }
    
    // sort by origin.x of the frame because the items are not necessarily in the correct order
    [tabBarItems sortUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
        if (view1.frame.origin.x < view2.frame.origin.x) {
            return NSOrderedAscending;
        }
        if (view1.frame.origin.x > view2.frame.origin.x) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    UIView *retVal = nil;
    if (index < [tabBarItems count]) {
        // viewController is in a regular tab
        UIView *tabView = tabBarItems[index];
        if ([tabView respondsToSelector:@selector(frame)]) {
            retVal = tabView;
        }
    }
    else {
        // our target viewController is inside the "more" tab
        UIView *tabView = [tabBarItems lastObject];
        if ([tabView respondsToSelector:@selector(frame)]) {
            retVal = tabView;
        }
    }
    return retVal;
}

@end
