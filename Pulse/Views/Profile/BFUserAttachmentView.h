//
//  BFUserAttachmentView.h
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFAttachmentView.h"
#import "BFAvatarView.h"
#import "User.h"
#import "BFDetailsCollectionView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFUserAttachmentView : BFAttachmentView

- (instancetype)initWithUser:(User *)user frame:(CGRect)frame;
@property (nonatomic, strong) User *user;

@property (nonatomic, strong) UIView *headerBackdrop;

@property (nonatomic, strong) UIView *avatarContainerView;
@property (nonatomic, strong) BFAvatarView *avatarView;

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UILabel *detailTextLabel;
@property (strong, nonatomic) UILabel *bioLabel;
@property (strong, nonatomic) BFDetailsCollectionView *detailsCollectionView;

+ (CGFloat)heightForUser:(User *)user width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
