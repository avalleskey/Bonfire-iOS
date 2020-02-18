//
//  BFSectionHeaderCell.h
//  Pulse
//
//  Created by Austin Valleskey on 1/20/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"
#import "Section.h"
#import "BFSectionHeaderObject.h"

NS_ASSUME_NONNULL_BEGIN

@class BFSectionHeaderObject;

@interface BFSectionHeaderCell : UITableViewCell

// Objects
@property (nonatomic, strong) id targetObject;

// Views
@property (nonatomic, strong) BFAvatarView *avatarView;
@property (nonatomic, strong) UIView *lineSeparator;

// Methods
+ (CGFloat)heightForHeaderObject:(BFSectionHeaderObject *)headerObject;

@end

NS_ASSUME_NONNULL_END
