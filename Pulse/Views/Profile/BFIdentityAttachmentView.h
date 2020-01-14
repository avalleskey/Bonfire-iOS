//
//  BFUserAttachmentView.h
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFAttachmentView.h"
#import "BFAvatarView.h"
#import "Identity.h"
#import "BFDetailsCollectionView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFIdentityAttachmentView : BFAttachmentView <UIContextMenuInteractionDelegate>

- (instancetype)initWithIdentity:(Identity *)identity frame:(CGRect)frame;
@property (nonatomic, strong) Identity *identity;

@property (nonatomic, strong) UIView *headerBackdrop;

@property (nonatomic, strong) UIView *avatarContainerView;
@property (nonatomic, strong) BFAvatarView *avatarView;

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UILabel *detailTextLabel;
@property (strong, nonatomic) UILabel *bioLabel;
@property (strong, nonatomic) BFDetailsCollectionView *detailsCollectionView;

@property (nonatomic) BOOL showBio;
@property (nonatomic) BOOL showDetails;

+ (CGFloat)heightForIdentity:(Identity *)identity width:(CGFloat)width showBio:(BOOL)showBio showDetails:(BOOL)showDetails;
+ (CGFloat)heightForIdentity:(Identity *)identity width:(CGFloat)width; // assumes showBio and showDetails are TRUE

@end

NS_ASSUME_NONNULL_END
