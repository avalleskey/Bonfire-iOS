//
//  BFCampAttachmentView.h
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFAttachmentView.h"
#import "BFAvatarView.h"
#import "Camp.h"
#import "BFDetailsCollectionView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFCampAttachmentView : BFAttachmentView <UIContextMenuInteractionDelegate>

- (instancetype)initWithCamp:(Camp *)camp frame:(CGRect)frame;
@property (nonatomic, strong) Camp *camp;

@property (nonatomic, strong) UIView *headerBackdrop;

@property (nonatomic, strong) UIView *avatarContainerView;
@property (nonatomic, strong) BFAvatarView *avatarView;
@property (nonatomic, strong) BFAvatarView *member2;
@property (nonatomic, strong) BFAvatarView *member3;
@property (nonatomic, strong) BFAvatarView *member4;
@property (nonatomic, strong) BFAvatarView *member5;
@property (nonatomic, strong) BFAvatarView *member6;
@property (nonatomic, strong) BFAvatarView *member7;

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UILabel *detailTextLabel;
@property (strong, nonatomic) UILabel *descriptionLabel;
@property (strong, nonatomic) BFDetailsCollectionView *detailsCollectionView;

+ (CGFloat)heightForCamp:(Camp *)camp  width:(CGFloat)width;

@end

NS_ASSUME_NONNULL_END
