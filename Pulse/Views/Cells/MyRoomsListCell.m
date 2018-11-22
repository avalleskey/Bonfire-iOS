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

#define padding 24
#define envConfig [[[NSUserDefaults standardUserDefaults] objectForKey:@"config"] objectForKey:[[NSUserDefaults standardUserDefaults] stringForKey:@"environment"]]

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
    self.rooms = [[NSMutableArray alloc] init];
    self.manager = [HAWebService manager];
    self.loading = true;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshMyRooms:) name:@"refreshMyRooms" object:nil];
    [self getRooms];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 12.f;
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.contentInset = UIEdgeInsetsMake(0, 16, 0, 16);
    [_collectionView registerClass:[ChannelCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [_collectionView registerClass:[EmptyChannelCell class] forCellWithReuseIdentifier:emptyRoomCellReuseIdentifier];
    [_collectionView registerClass:[ErrorChannelCell class] forCellWithReuseIdentifier:errorRoomCellReuseIdentifier];
    _collectionView.showsHorizontalScrollIndicator = false;
    _collectionView.layer.masksToBounds = true;
    _collectionView.backgroundColor = [UIColor clearColor];
    
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
        
        cell.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
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
        
        [self layoutSubviews];
        
        return cell;
    }
    else {
        if (self.rooms.count == 0) {
            if (self.errorLoading) {
                ErrorChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:errorRoomCellReuseIdentifier forIndexPath:indexPath];
                
                return cell;
            }
            else {
                EmptyChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:emptyRoomCellReuseIdentifier forIndexPath:indexPath];
                
                cell.titleLabel.text = [Session sharedInstance].defaults.onboarding.myRooms.title;
                cell.descriptionLabel.text = [Session sharedInstance].defaults.onboarding.myRooms.theDescription;
                
                return cell;
            }
        }
        else {
            ChannelCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
            
            NSError *error;
            cell.room = [[Room alloc] initWithDictionary:self.rooms[indexPath.item] error:&error];
            
            cell.profilePicture.image = [[UIImage imageNamed:@"anonymousGroup"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.profilePicture.tintColor = [UIColor whiteColor];
            cell.profilePicture.backgroundColor = [UIColor clearColor];
            cell.profilePicture.layer.shadowOpacity = 0;
            
            cell.shimmerContainer.shimmering = false;
            cell.shimmerContainer.hidden = true;
            
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
            // cell.membersView.text = @"650 members";
            
            cell.membersView.hidden = false;
            
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
            cell.layer.shadowOpacity = 1;
            
            [cell layoutSubviews];
            
            return cell;
        }
    }
}
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    BOOL useFullWidthCell = self.errorLoading || (!self.loading && self.rooms.count == 0);
    
    return CGSizeMake(useFullWidthCell?self.frame.size.width - 32:300, self.frame.size.height);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.loading && !self.errorLoading && self.rooms.count > 0) {
        // animate the cell user tapped on
        Room *room = [[Room alloc] initWithDictionary:self.rooms[indexPath.row] error:nil];
        
        RoomContext *context = [[RoomContext alloc] initWithDictionary:@{@"status": STATUS_MEMBER} error:nil];
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
    
}

@end
