//
//  RoomSuggestionsListCell.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "Session.h"
#import "Launcher.h"
#import "HAWebService.h"
#import "MyRoomsListCell.h"
#import "ChannelCell.h"
#import "ErrorChannelCell.h"
#import "EmptyChannelCell.h"
#import "LauncherNavigationViewController.h"
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>

#define padding 24
#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

@interface MyRoomsListCell ()

@property (nonatomic) BOOL isMoving;
@property (strong, nonatomic) ChannelCell *movingCell;

@end

@implementation MyRoomsListCell

static NSString * const reuseIdentifier = @"RoomCell";
static NSString * const emptyRoomCellReuseIdentifier = @"EmptyRoomCell";
static NSString * const errorRoomCellReuseIdentifier = @"ErrorRoomCell";

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        [self setup];
    }
    
    return self;
}

- (void)setup {
    self.clipsToBounds = false;
    self.contentView.clipsToBounds = false;
    
    self.rooms = [[NSMutableArray alloc] init];
    self.manager = [HAWebService manager];
    self.loading = true;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMyRooms:) name:@"refreshMyRooms" object:nil];
    [self getRooms];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 12.f;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    self.separator = [[UIView alloc] initWithFrame:CGRectMake(16, self.frame.size.height - (1 / [UIScreen mainScreen].scale), screenWidth - 32, 1 / [UIScreen mainScreen].scale)];
    self.separator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
    [self.contentView addSubview:self.separator];
    
    self.header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 108)];
    
    self.bigTitle = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, self.header.frame.size.width - 32, 40)];
    
    FBTweakBind(self.bigTitle, text, @"Rooms", @"My Rooms", @"Big Title", @"Rooms");

    self.bigTitle.textAlignment = NSTextAlignmentLeft;
    self.bigTitle.font = [UIFont systemFontOfSize:34.f weight:UIFontWeightHeavy];
    self.bigTitle.textColor = [UIColor colorWithWhite:0.07f alpha:1];
    [self.header addSubview:self.bigTitle];
    
    UIView *headerSeparator = [[UIView alloc] initWithFrame:CGRectMake(16, 48, screenWidth - 32, 1 / [UIScreen mainScreen].scale)];
    headerSeparator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
    [self.header addSubview:headerSeparator];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, self.header.frame.size.height - 24 - 16, self.header.frame.size.width - 32, 24)];
    
    FBTweakBind(title, text, @"Rooms", @"My Rooms", @"Title", @"My Rooms");
    
    title.textAlignment = NSTextAlignmentLeft;
    title.font = [UIFont systemFontOfSize:22.f weight:UIFontWeightBold];
    title.textColor = [UIColor bonfireGrayWithLevel:700];
    
    [self.header addSubview:title];
    [self.contentView addSubview:self.header];
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 108, screenWidth, self.frame.size.height - 40 + 108) collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
    [_collectionView registerClass:[ChannelCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [_collectionView registerClass:[EmptyChannelCell class] forCellWithReuseIdentifier:emptyRoomCellReuseIdentifier];
    [_collectionView registerClass:[ErrorChannelCell class] forCellWithReuseIdentifier:errorRoomCellReuseIdentifier];
    _collectionView.showsHorizontalScrollIndicator = false;
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.clipsToBounds = false;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(cellLongPress:)];
    [_collectionView addGestureRecognizer:longPress];
    
    [self.contentView addSubview:_collectionView];
}

- (void)refreshMyRooms:(id)sender {
    [self getRooms];
}

- (void)getRooms {
    NSString *url;// = [NSString stringWithFormat:@"%@/%@/schools/%@/channels", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"], @"2"];
    //url = @"https://rawgit.com/avalleskey/avalleskey.github.io/master/sample_rooms2.json"; // sample data
    url = [NSString stringWithFormat:@"%@/%@/users/me/rooms", envConfig[@"API_BASE_URI"], envConfig[@"API_CURRENT_VERSION"]];
    
    [[Session sharedInstance] authenticate:^(BOOL success, NSString *token) {
        if (success) {
            [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
            
            NSLog(@"token::: %@", token);
            [self.manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                // NSLog(@"MyRoomsViewController / getRooms() success! ✅");
                
                NSArray *responseData = responseObject[@"data"];
                
                // NSLog(@"responseData: %@", responseData);
                
                if (responseData.count > 0) {
                    self.rooms = [[NSMutableArray alloc] initWithArray:responseData];
                }
                else {
                    self.rooms = [[NSMutableArray alloc] init];
                }
                
                self.loading = false;
                self.collectionView.scrollEnabled = true;
                self.errorLoading = false;
                [self.collectionView reloadData];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"MyRoomsViewController / getRooms() - error: %@", error);
                //        NSString *ErrorResponse = [[NSString alloc] initWithData:(NSData *)error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding];
                
                self.loading = false;
                self.collectionView.scrollEnabled = true;
                self.errorLoading = true;
                [self.collectionView reloadData];
            }];
        }
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.loading) {
        return 2;
    }
    else {
        if (self.errorLoading) {
            return 1;
        }
        else {
            return self.rooms.count > 0 ? self.rooms.count : 1;
        }
    }
}
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.loading) {
        ChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
        
        cell.profilePicture.backgroundColor = [UIColor whiteColor];
        cell.profilePicture.image = nil;
        cell.profilePicture.layer.shadowOpacity = 0;
        
        cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
        cell.title.layer.cornerRadius = 6.f;
        cell.title.layer.masksToBounds = true;
        cell.title.backgroundColor = [UIColor whiteColor];
        cell.title.text = @"Loading";
        cell.title.textColor = [UIColor clearColor];
        cell.bio.text = @"Quintessential information";
        cell.bio.textColor = [UIColor clearColor];
        cell.bio.backgroundColor = [UIColor whiteColor];
        
        cell.shimmerContainer.hidden = false;
        
        cell.ticker.hidden = true;
        cell.membersView.hidden = true;
        cell.inviteButton.hidden = true;
        
        cell.layer.shadowOpacity = 0;
        cell.clipsToBounds = true;
        
        [self layoutSubviews];
        
        return cell;
    }
    else {
        if (self.rooms.count == 0) {
            if (self.errorLoading) {
                ErrorChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:errorRoomCellReuseIdentifier forIndexPath:indexPath];
                
                if ([self.manager hasInternet]) {
                    [cell.errorView updateType:ErrorViewTypeGeneral];
                    [cell.errorView updateTitle:@"Error Loading"];
                    [cell.errorView updateDescription:@"Check your network settings and tap to try again."];
                }
                else {
                    [cell.errorView updateType:ErrorViewTypeNoInternet];
                    [cell.errorView updateTitle:@"No Internet"];
                    [cell.errorView updateDescription:@"Check your network settings and tap to try again."];
                }
                
                CGFloat shadowOpacity = FBTweakValue(@"Rooms", @"My Rooms", @"Shadow Opacity", 0.15);
                cell.layer.shadowOpacity = shadowOpacity / 2;
                CGFloat shadowRadius = FBTweakValue(@"Rooms", @"My Rooms", @"Shadow Radius", 22.f);
                cell.layer.shadowRadius = shadowRadius;
                
                return cell;
            }
            else {
                EmptyChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:emptyRoomCellReuseIdentifier forIndexPath:indexPath];
                
                cell.titleLabel.text = [Session sharedInstance].defaults.onboarding.myRooms.title;
                cell.descriptionLabel.text = [Session sharedInstance].defaults.onboarding.myRooms.theDescription;
                
                CGFloat shadowOpacity = FBTweakValue(@"Rooms", @"My Rooms", @"Shadow Opacity", 0.15);
                cell.layer.shadowOpacity = shadowOpacity / 2;
                CGFloat shadowRadius = FBTweakValue(@"Rooms", @"My Rooms", @"Shadow Radius", 22.f);
                cell.layer.shadowRadius = shadowRadius;
                
                return cell;
            }
        }
        else {
            if (self.movingCell != nil && !self.isMoving) {
                return self.movingCell;
            }
            else {
                ChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
                
                NSError *error;
                cell.room = [[Room alloc] initWithDictionary:self.rooms[indexPath.item] error:&error];
                
                cell.membersView.hidden = false;
                
                cell.profilePicture.image = [[UIImage imageNamed:@"anonymousGroup"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.profilePicture.tintColor = [UIColor whiteColor];
                cell.profilePicture.backgroundColor = [UIColor clearColor];
                cell.profilePicture.layer.shadowOpacity = 0;
                
                cell.title.text = cell.room.attributes.details.title;
                cell.title.textColor = [UIColor whiteColor];
                cell.title.backgroundColor = [UIColor clearColor];
                
                cell.bio.text = cell.room.attributes.details.theDescription != nil ? cell.room.attributes.details.theDescription : @"";
                cell.bio.textColor = [UIColor colorWithWhite:1 alpha:0.75f];
                cell.bio.backgroundColor = [UIColor clearColor];
                
                if (cell.room.attributes.summaries.counts.live < [Session sharedInstance].defaults.room.liveThreshold) {
                    cell.ticker.hidden = true;
                    cell.inviteButton.hidden = false;
                }
                else {
                    cell.ticker.hidden = false;
                    [cell.ticker setTitle:[NSString stringWithFormat:@"%ld live", (long)cell.room.attributes.summaries.counts.live] forState:UIControlStateNormal];
                    cell.inviteButton.hidden = true;
                }
                
                for (int i = 0; i < cell.membersView.subviews.count; i++) {
                    if ([cell.membersView.subviews[i] isKindOfClass:[UIImageView class]]) {
                        UIImageView *imageView = cell.membersView.subviews[i];
                        
                        if (cell.room.attributes.summaries.members.count > imageView.tag) {
                            imageView.hidden = false;
                            
                            User *member = [[User alloc] initWithDictionary:cell.room.attributes.summaries.members[imageView.tag] error:nil];
                            NSString *picURL = member.attributes.details.media.profilePicture;
                            if (picURL.length > 0) {
                                [imageView sd_setImageWithURL:[NSURL URLWithString:picURL]];
                            }
                            else {
                                [imageView setImage:[[UIImage imageNamed:@"anonymous"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                                imageView.tintColor = [UIColor fromHex:member.attributes.details.color];
                            }
                        }
                        else {
                            imageView.hidden = true;
                        }
                    }
                }
                
                cell.backgroundColor = [UIColor fromHex:cell.room.attributes.details.color];
                
                CGFloat shadowOpacity = FBTweakValue(@"Rooms", @"My Rooms", @"Shadow Opacity", 0.15);
                cell.layer.shadowOpacity = shadowOpacity;
                CGFloat shadowRadius = FBTweakValue(@"Rooms", @"My Rooms", @"Shadow Radius", 22.f);
                cell.layer.shadowRadius = shadowRadius;
                
                cell.layer.shadowColor = [UIColor fromHex:cell.room.attributes.details.color].CGColor;
                
                cell.clipsToBounds = false;
                [cell layoutSubviews];
                
                return cell;
            }
        }
    }
}
/*
 guard let selectedIndexPath = reorderCollectionView.indexPathForItem(at: gesture.location(in: reorderCollectionView)) else {
 break
 }
 reorderCollectionView.beginInteractiveMovementForItem(at: selectedIndexPath)*/

- (void)cellLongPress:(UILongPressGestureRecognizer *)longPress {
    switch(longPress.state) {
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateBegan: {
            if (!self.isMoving) {
                self.isMoving = true;
                NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[longPress locationInView:self.collectionView]];
                self.movingCell = (ChannelCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                self.layer.zPosition = 100;
                
                [self.collectionView beginInteractiveMovementForItemAtIndexPath:indexPath];
            }
            break;
        }
        case UIGestureRecognizerStateChanged:
            [self.collectionView updateInteractiveMovementTargetPosition:[longPress locationInView:longPress.view]];
            break;
        case UIGestureRecognizerStateEnded: {
            self.isMoving = false;
            [self.collectionView performBatchUpdates:^{
                [self.collectionView endInteractiveMovement];
            } completion:^(BOOL finished) {
                self.movingCell = nil;
            }];
            break;
        }
        default:
            self.isMoving = false;
            [self.collectionView cancelInteractiveMovement];
            break;
    }
}
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL useFullWidthCell = self.errorLoading || (!self.loading && self.rooms.count == 0);
    
    return CGSizeMake(useFullWidthCell?self.frame.size.width - 32:300, self.frame.size.height - 108 - 40);
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return TRUE;
}
- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    printf("Starting Index: \(sourceIndexPath.item)");
    printf("Ending Index: \(destinationIndexPath.item)");
    NSDictionary *object = self.rooms[sourceIndexPath.item];
    
    [self.rooms removeObjectAtIndex:sourceIndexPath.item];
    [self.rooms insertObject:object atIndex:destinationIndexPath.item];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loading && !self.errorLoading && self.rooms.count > 0) {
        // animate the cell user tapped on
        Room *room = [[Room alloc] initWithDictionary:self.rooms[indexPath.row] error:nil];
        
        RoomContext *context = [[RoomContext alloc] initWithDictionary:@{@"status": ROOM_STATUS_MEMBER} error:nil];
        room.attributes.context = context;
        
        [[Launcher sharedInstance] openRoom:room];
    }
    else if (self.errorLoading) {
        // tap to try loading again
        self.rooms = [[NSMutableArray alloc] init];
        
        self.loading = true;
        [self.collectionView setContentOffset:CGPointMake(-12, 0)];
        self.collectionView.scrollEnabled = false;
        self.errorLoading = false;
        
        [self getRooms];
        [self.collectionView reloadData];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.separator.frame = CGRectMake(self.separator.frame.origin.x, self.frame.size.height - self.separator.frame.size.height, self.frame.size.width - 32, self.separator.frame.size.height);
    
    self.collectionView.frame = CGRectMake(0, 108, self.frame.size.width, self.frame.size.height - 108 - 40);
}

@end
