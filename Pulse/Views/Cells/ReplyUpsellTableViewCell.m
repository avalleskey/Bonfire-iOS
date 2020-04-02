//
//  ReplyUpsellTableViewCell.m
//  Pulse
//
//  Created by Austin Valleskey on 4/1/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "ReplyUpsellTableViewCell.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIView+Styles.h"

@implementation ReplyUpsellTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        self.backgroundColor = [UIColor contentBackgroundColor];
        
        self.textLabel.textColor = [UIColor bonfirePrimaryColor];
        self.textLabel.text = @"Join the Conversation";
        self.textLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
        self.textLabel.textAlignment = NSTextAlignmentCenter;
        
        self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
        self.detailTextLabel.text = @"Have something to say? Add a reply!";
        self.detailTextLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
        self.detailTextLabel.textAlignment = NSTextAlignmentCenter;

        self.topSeparator = [[UIView alloc] init];
        self.topSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        self.topSeparator.hidden = true;
        [self.contentView addSubview:self.topSeparator];
        
        self.bottomSeparator = [[UIView alloc] init];
        self.bottomSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self.contentView addSubview:self.bottomSeparator];
        
        self.suggestionsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 38)];
        self.suggestionsScrollView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
        self.suggestionsScrollView.showsHorizontalScrollIndicator = false;
        self.suggestionsScrollView.showsVerticalScrollIndicator = false;
        self.suggestionsScrollView.layer.masksToBounds = false;
        [self.contentView addSubview:self.suggestionsScrollView];
        
        self.suggestionsStackView = [[UIStackView alloc] initWithFrame:CGRectMake(0, 0, self.suggestionsScrollView.frame.size.width, self.suggestionsScrollView.frame.size.height)];
        self.suggestionsStackView.backgroundColor = [UIColor contentBackgroundColor];
        self.suggestionsStackView.axis = UILayoutConstraintAxisHorizontal;
        self.suggestionsStackView.distribution = UIStackViewDistributionFill;
        self.suggestionsStackView.alignment = UIStackViewAlignmentFill;
        self.suggestionsStackView.spacing = 10;
        self.suggestionsStackView.layer.masksToBounds = false;
        
        self.suggestionsStackView.translatesAutoresizingMaskIntoConstraints = false;
        [self.suggestionsScrollView addSubview:self.suggestionsStackView];
        
        [self.suggestionsStackView.leadingAnchor constraintEqualToAnchor:self.suggestionsScrollView.leadingAnchor].active = true;
        [self.suggestionsStackView.trailingAnchor constraintEqualToAnchor:self.suggestionsScrollView.trailingAnchor].active = true;
        [self.suggestionsStackView.bottomAnchor constraintEqualToAnchor:self.suggestionsScrollView.bottomAnchor].active = true;
        [self.suggestionsStackView.topAnchor constraintEqualToAnchor:self.suggestionsScrollView.topAnchor].active = true;
        [self.suggestionsStackView.heightAnchor constraintEqualToAnchor:self.suggestionsScrollView.heightAnchor].active = true;
        
        
        UIButton *addReplyButton = [UIButton buttonWithType:UIButtonTypeSystem];
        addReplyButton.titleLabel.font = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize-2.f];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Add a reply...        "] attributes:@{NSFontAttributeName: addReplyButton.titleLabel.font, NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor]}];
        [addReplyButton setAttributedTitle:attributedString forState:UIControlStateNormal];
        addReplyButton.layer.cornerRadius = self.suggestionsStackView.frame.size.height / 2;
        addReplyButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        addReplyButton.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 16);
        addReplyButton.layer.borderWidth = 1;
        addReplyButton.backgroundColor = [UIColor cardBackgroundColor];
        [addReplyButton bk_whenTapped:^{
            if (self.suggestionTappedAction) {
                self.suggestionTappedAction(@"");
            }
        }];
        [self.suggestionsStackView addArrangedSubview:addReplyButton];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.topSeparator.frame = CGRectMake(0, 0, self.frame.size.width, HALF_PIXEL);
    self.bottomSeparator.frame = CGRectMake(0, self.frame.size.height - HALF_PIXEL, self.frame.size.width, HALF_PIXEL);
    
    if (self.collapsed) {
        self.textLabel.hidden = true;
        self.detailTextLabel.hidden = true;
        
        self.suggestionsScrollView.frame = CGRectMake(0, 16, self.frame.size.width, self.suggestionsStackView.frame.size.height);
    }
    else {
        self.textLabel.hidden = false;
        self.detailTextLabel.hidden = false;
        
        self.textLabel.frame = CGRectMake(16, 24, self.frame.size.width - (16 * 2), ceilf(self.textLabel.font.lineHeight));
        self.detailTextLabel.frame = CGRectMake(16, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 4, self.frame.size.width - (16 * 2), ceilf(self.detailTextLabel.font.lineHeight));
        
        self.suggestionsScrollView.frame = CGRectMake(0, self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height + 16, self.frame.size.width, self.suggestionsStackView.frame.size.height);
    }
    
    self.suggestionsStackView.frame = self.suggestionsScrollView.bounds;
    
    for (UIView *arrangedSubview in self.suggestionsStackView.arrangedSubviews) {
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
    return 144;
}
+ (CGFloat)collapsedHeight {
    return 70; //16 + 38 + 16
}

- (void)setSuggestions:(NSArray *)suggestions {
    if (suggestions != _suggestions) {
        _suggestions = suggestions;
        
        // remove existing suggestions
        if (self.suggestionsStackView.arrangedSubviews.count > 1) {
            NSArray *removeButtons = [self.suggestionsStackView.arrangedSubviews subarrayWithRange:NSMakeRange(1, self.suggestionsStackView.arrangedSubviews.count-1)];
            for (UIButton *button in removeButtons) {
                [button bk_removeEventHandlersForControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit|UIControlEventTouchDown)];
                [button removeFromSuperview];
            }
        }
        
        // add new suggestions
        for (NSString *suggestionString in suggestions) {
            UIButton *suggestion = [UIButton buttonWithType:UIButtonTypeCustom];
            suggestion.titleLabel.font = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize-2.f weight:UIFontWeightSemibold];
            suggestion.userInteractionEnabled = true;
            suggestion.layer.cornerRadius = self.suggestionsStackView.frame.size.height / 2;
            suggestion.backgroundColor = [UIColor cardBackgroundColor];
            [suggestion setTitleColor:[UIColor fromHex:[UIColor toHex:self.tintColor] adjustForOptimalContrast:true] forState:UIControlStateNormal];
            [suggestion setContentEdgeInsets:UIEdgeInsetsMake(0, 16, 0, 16)];
            [suggestion setElevation:1];
            suggestion.layer.borderWidth = 1;
            [suggestion setTitle:suggestionString forState:UIControlStateNormal];
            [suggestion bk_whenTapped:^{
                if (self.suggestionTappedAction) {
                    self.suggestionTappedAction(suggestion.currentTitle);
                }
            }];
            [self addTouchDownEffects:suggestion];
            [self.suggestionsStackView addArrangedSubview:suggestion];
        }
    }
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
