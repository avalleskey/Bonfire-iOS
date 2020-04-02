//
//  BFSectionHeaderCell.m
//  Pulse
//
//  Created by Austin Valleskey on 1/20/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFSectionHeaderCell.h"
#import "Launcher.h"
#import "UIColor+Palette.h"
#import "BFStreamComponent.h"

@interface BFSectionHeaderCell () <BFComponentProtocol>

@end

@implementation BFSectionHeaderCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.layer.masksToBounds = true;
        self.tintColor = self.superview.tintColor;
        self.contentView.clipsToBounds = true;
        
        self.backgroundColor = [UIColor contentBackgroundColor];
        self.contentView.backgroundColor = [UIColor contentBackgroundColor];
        
        self.textLabel.font = [UIFont systemFontOfSize:18.f weight:UIFontWeightBold];
        self.textLabel.textColor = [UIColor bonfirePrimaryColor];
        
        self.detailTextLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightRegular];
        self.detailTextLabel.textColor = [UIColor bonfireSecondaryColor];
                
        self.avatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(self.frame.size.width - 24 - 12, 20, 24, 24)];
        self.avatarView.openOnTap = true;
        self.avatarView.allowOnlineDot = false;
        self.avatarView.hidden = true;
        [self.contentView addSubview:self.avatarView];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - HALF_PIXEL, self.frame.size.width, HALF_PIXEL)];
        self.lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self.contentView addSubview:self.lineSeparator];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIEdgeInsets contentEdgeInsets = UIEdgeInsetsMake(12, 12, 12, 12);
    
    if (![self.avatarView isHidden]) {
        self.avatarView.frame = CGRectMake(self.frame.size.width - self.avatarView.frame.size.width - contentEdgeInsets.right, self.frame.size.height / 2 - self.avatarView.frame.size.height / 2, self.avatarView.frame.size.width, self.avatarView.frame.size.height);
        
        contentEdgeInsets.right = self.frame.size.width - self.avatarView.frame.origin.x - 12;
    }
    
    self.textLabel.hidden = (self.textLabel.text.length == 0);
    self.detailTextLabel.hidden = (self.detailTextLabel.text.length == 0);
    
    if (![self.textLabel isHidden]) {
        if ([self.detailTextLabel isHidden]) {
            contentEdgeInsets.top =
            contentEdgeInsets.bottom = 16;
        }
        
        self.textLabel.frame = CGRectMake(contentEdgeInsets.left, contentEdgeInsets.top, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right, self.textLabel.font.lineHeight);
    }
    
    if (![self.detailTextLabel isHidden]) {
        if ([self.textLabel isHidden]) {
            self.detailTextLabel.frame = CGRectMake(contentEdgeInsets.left, contentEdgeInsets.top, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right, self.frame.size.height - contentEdgeInsets.top - contentEdgeInsets.bottom);
        }
        else {
            self.detailTextLabel.frame = CGRectMake(contentEdgeInsets.left, self.textLabel.frame.origin.y + self.textLabel.frame.size.height + 2, self.frame.size.width - contentEdgeInsets.left - contentEdgeInsets.right, self.detailTextLabel.font.lineHeight);
        }
    }
    
    self.lineSeparator.frame = CGRectMake(0, self.frame.size.height - HALF_PIXEL, self.frame.size.width, HALF_PIXEL);
}

- (void)setTargetObject:(id)targetObject {
    if (targetObject != _targetObject) {
        _targetObject = targetObject;
        
        self.avatarView.hidden = !targetObject;
        
        if ([targetObject isKindOfClass:[Camp class]]) {
            self.avatarView.camp = (Camp *)targetObject;
        }
        else if ([targetObject isKindOfClass:[User class]]) {
            self.avatarView.user = (User *)targetObject;
        }
        else if ([targetObject isKindOfClass:[Bot class]]) {
            self.avatarView.bot = (Bot *)targetObject;
        }
    }
}

+ (CGFloat)heightForHeaderObject:(BFSectionHeaderObject *)headerObject {
    if (headerObject.title.length > 0 &&
        headerObject.text.length > 0) {
        return 64;
    }
    
    return 52;
}

+ (CGFloat)heightForComponent:(BFStreamComponent *)component {
    BFSectionHeaderObject *headerObject = component.headerObject;
    
    return [BFSectionHeaderCell heightForHeaderObject:headerObject];
}

@end
