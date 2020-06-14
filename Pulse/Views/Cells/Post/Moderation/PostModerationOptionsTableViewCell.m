//
//  PostModerationOptionsTableViewCell.m
//  Pulse
//
//  Created by Austin Valleskey on 4/1/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "PostModerationOptionsTableViewCell.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIView+Styles.h"

@implementation PostModerationOptionsTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.backgroundColor = [UIColor contentBackgroundColor];
        
        self.textLabel.hidden = true;
        self.detailTextLabel.hidden = true;
        
        self.topSeparator = [[UIView alloc] init];
        self.topSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        self.topSeparator.hidden = true;
        [self.contentView addSubview:self.topSeparator];
        
        self.bottomSeparator = [[UIView alloc] init];
        self.bottomSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self.contentView addSubview:self.bottomSeparator];
        
        self.optionsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 38)];
        self.optionsScrollView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
        self.optionsScrollView.showsHorizontalScrollIndicator = false;
        self.optionsScrollView.showsVerticalScrollIndicator = false;
        self.optionsScrollView.layer.masksToBounds = false;
        [self.contentView addSubview:self.optionsScrollView];
        
        self.optionsStackView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, self.optionsScrollView.frame.size.width, self.optionsScrollView.frame.size.height)];
        self.optionsStackView.backgroundColor = [UIColor contentBackgroundColor];
        self.optionsStackView.axis = UILayoutConstraintAxisHorizontal;
        self.optionsStackView.distribution = UIStackViewDistributionFill;
        self.optionsStackView.alignment = UIStackViewAlignmentFill;
        self.optionsStackView.spacing = 10;
        self.optionsStackView.layer.masksToBounds = false;
        
        self.optionsStackView.translatesAutoresizingMaskIntoConstraints = false;
        [self.optionsScrollView addSubview:self.optionsStackView];
        
        [self.optionsStackView.leadingAnchor constraintEqualToAnchor:self.optionsScrollView.leadingAnchor].active = true;
        [self.optionsStackView.trailingAnchor constraintEqualToAnchor:self.optionsScrollView.trailingAnchor].active = true;
        [self.optionsStackView.bottomAnchor constraintEqualToAnchor:self.optionsScrollView.bottomAnchor].active = true;
        [self.optionsStackView.topAnchor constraintEqualToAnchor:self.optionsScrollView.topAnchor].active = true;
        [self.optionsStackView.heightAnchor constraintEqualToAnchor:self.optionsScrollView.heightAnchor].active = true;
        
        typedef enum {
            PostModerationOptionStyleMild,
            PostModerationOptionStyleSevere,
            PostModerationOptionStyleIgnore
        } PostModerationOptionStyle;
        NSArray *options = @[
            @{
                @"title": @"Ignore",
                @"tag": @(PostModerationOptionIgnore),
                @"style": @(PostModerationOptionStyleIgnore)
            },
            @{
                @"title": @"Delete",
                @"tag": @(PostModerationOptionDelete),
                @"style": @(PostModerationOptionStyleSevere)
            },
            @{
                @"title": @"Spam",
                @"tag": @(PostModerationOptionSpam),
                @"style": @(PostModerationOptionStyleSevere)
            },
            @{
                @"title": @"Silence User",
                @"tag": @(PostModerationOptionSilenceUser),
                @"style": @(PostModerationOptionStyleMild)
            },
            @{
                @"title": @"Block User",
                @"tag": @(PostModerationOptionBlockUser),
                @"style": @(PostModerationOptionStyleSevere)
            }
        ];
        for (NSDictionary *option in options) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.tag = (NSInteger)option[@"tag"];
            button.userInteractionEnabled = true;
            button.layer.cornerRadius = self.optionsStackView.frame.size.height / 2;
            button.backgroundColor = [UIColor cardBackgroundColor];
            [button setContentEdgeInsets:UIEdgeInsetsMake(0, 16, 0, 16)];
            [button setElevation:1];
            button.layer.borderWidth = 1;
            
            // text
            button.titleLabel.font = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize-2.f weight:UIFontWeightSemibold];
            if ([option[@"style"] intValue] == PostModerationOptionStyleIgnore) {
                [button setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
            }
            else {
                if ([option[@"style"] intValue] == PostModerationOptionStyleMild) {
                    [button setTitleColor:[UIColor fromHex:@"F6B420" adjustForOptimalContrast:false] forState:UIControlStateNormal];
                }
                else if ([option[@"style"] intValue] == PostModerationOptionStyleSevere) {
                    [button setTitleColor:[UIColor fromHex:@"ff0900" adjustForOptimalContrast:true] forState:UIControlStateNormal];
                }
            }
            [button setTitle:option[@"title"] forState:UIControlStateNormal];
            [button bk_whenTapped:^{
                if (self.optionTappedAction) {
                    self.optionTappedAction((NSInteger)button.tag);
                }
            }];
            [self addTouchDownEffects:button];
            [self.optionsStackView addArrangedSubview:button];
        }
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.topSeparator.frame = CGRectMake(0, 0, self.frame.size.width, HALF_PIXEL);
    self.bottomSeparator.frame = CGRectMake(0, self.frame.size.height - HALF_PIXEL, self.frame.size.width, HALF_PIXEL);
    
    self.optionsScrollView.frame = CGRectMake(0, 16, self.frame.size.width, self.optionsStackView.frame.size.height);
    self.optionsStackView.frame = self.optionsScrollView.bounds;
    
    for (UIView *arrangedSubview in self.optionsStackView.arrangedSubviews) {
        if (arrangedSubview.layer.borderWidth > 0 && arrangedSubview.layer.borderColor != [UIColor clearColor].CGColor) {
            arrangedSubview.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.08].CGColor;
        }
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    // support dark mode
    [self themeChanged];
}

+ (CGFloat)height {
    return 70;
}

- (void)addTouchDownEffects:(UIButton *)button {
    [button bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            button.transform = CGAffineTransformMakeScale(0.96, 0.96);
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [button bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            button.transform = CGAffineTransformIdentity;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
}

@end
