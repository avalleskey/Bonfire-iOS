#import "Camp.h"
#import "HAWebService.h"
#import <JGProgressHUD.h>
#import "Launcher.h"
#import "UIColor+Palette.h"
@import Firebase;

@implementation Camp

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err {
    Camp *instance = [super initWithDictionary:dict error:err];
    
    // generate score color
    if (instance.attributes.summaries.counts.scoreIndex > 0) {
        CGFloat R = 0.96 - 0.05 * instance.attributes.summaries.counts.scoreIndex; // 0.96 (yellow) -> 0.91 (red)
        CGFloat G = 0.80 - 0.77 * instance.attributes.summaries.counts.scoreIndex; // 0.80 (yellow) -> 0.03 (red)
        CGFloat B = 0.14 - 0.14 * instance.attributes.summaries.counts.scoreIndex; // 0.14 (yellow) -> 0.00 (red)
        self.scoreColor = [UIColor toHex:[UIColor colorWithRed:R green:G blue:B alpha:1]];
    }
    else {
        self.scoreColor = @"999999";
    }
        
    return instance;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return TRUE;
}
+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                                                                  @"identifier": @"id"
                                                                  }];
}

- (NSString *)campIdentifier {
    if (self.identifier != nil) return self.identifier;
    if (self.attributes.identifier != nil) return self.attributes.identifier;
    
    return nil;
}

#pragma mark - Helper methods
- (BOOL)isVerified {
    return self.attributes.isVerified;
}
- (BOOL)isDefaultCamp {
    return !self.attributes.display.format || self.attributes.display.format.length == 0;
}
- (BOOL)isChannel {
    return [self.attributes.display.format isEqualToString:CAMP_DISPLAY_FORMAT_CHANNEL];
}
- (BOOL)isFeed {    
    return [self.attributes.display.format isEqualToString:CAMP_DISPLAY_FORMAT_FEED];
}
- (BOOL)isPrivate {
    return [self.attributes isPrivate];
}
- (BOOL)isSupported {
    NSArray *wallsSupported = @[CAMP_WALL_REQUEST];
    
    BOOL supported = true;
    for (NSString *wall in self.attributes.context.camp.walls) {
        if (![wallsSupported containsObject:wall]) {
            supported = false;
        }
    }
    
    return supported;
}

#pragma mark - API Methods
- (void)subscribeToCamp  {
    [FIRAnalytics logEventWithName:@"subscribe_to_camp" parameters:@{}];
    
    // Update the object
    BFContextCampMembershipSubscription *subscription = [[BFContextCampMembershipSubscription alloc] init];
    NSDate *date = [NSDate new];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    subscription.createdAt = [dateFormatter stringFromDate:date];
    self.attributes.context.camp.membership.subscription = subscription;
    
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"];
    NSString *url = [NSString stringWithFormat:@"camps/%@/members/subscriptions", [self campIdentifier]];
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] POST:url parameters:deviceToken?@{@"vendor": @"APNS", @"token": deviceToken}:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:self];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
}
- (void)unsubscribeFromCamp {
    [FIRAnalytics logEventWithName:@"unsubscribe_from_camp" parameters:@{}];
    
    // Update the object
    self.attributes.context.camp.membership.subscription = nil;
    
    NSString *url = [NSString stringWithFormat:@"camps/%@/members/subscriptions", [self campIdentifier]];
    [[[HAWebService managerWithContentType:kCONTENT_TYPE_JSON] authenticate] DELETE:url parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CampUpdated" object:self];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
}

+ (UIImage *)scoreDotImageForScoreIndex:(float)scoreIndex size:(CGSize)size {
    CGFloat R = 0.96 - 0.05 * scoreIndex; // 0.96 (yellow) -> 0.91 (red)
    CGFloat G = 0.80 - 0.77 * scoreIndex; // 0.80 (yellow) -> 0.03 (red)
    CGFloat B = 0.14 - 0.14 * scoreIndex; // 0.14 (yellow) -> 0.00 (red)
    
    if (scoreIndex > 0) {
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        containerView.layer.cornerRadius = containerView.frame.size.height / 2;
        containerView.backgroundColor = [UIColor whiteColor];
        containerView.layer.masksToBounds = true;
        
        NSArray *gradientColors = [NSArray arrayWithObjects:(id)[UIColor lighterColorForColor:[UIColor colorWithDisplayP3Red:R green:G blue:B alpha:1] amount:0.2].CGColor, (id)[UIColor darkerColorForColor:[UIColor colorWithDisplayP3Red:R green:G blue:B alpha:1] amount:0.1].CGColor, nil];

        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors = gradientColors;
        gradientLayer.startPoint = CGPointMake(0, 0);
        gradientLayer.endPoint = CGPointMake(1, 1);
        gradientLayer.frame = containerView.bounds;
        [containerView.layer addSublayer:gradientLayer];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:containerView.bounds];
        imageView.image = [[UIImage imageNamed:@"hotIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        imageView.tintColor = [UIColor whiteColor];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        [containerView addSubview:imageView];
//        NSString *imageName;
//        if (scoreIndex >= .66) {
//            // red
//            imageName = @"hotIcon_red";
//        }
//        else if (scoreIndex >= .33) {
//            // red
//            imageName = @"hotIcon_orange";
//        }
//        else {
//            imageName = @"hotIcon_yellow";
//        }
//        
//        return [UIImage imageNamed:imageName];
//        
        // capture screenshot
        UIGraphicsBeginImageContextWithOptions(containerView.bounds.size, NO, 3.f);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextClearRect(context, containerView.bounds);
        [containerView.layer renderInContext:context];
        UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return snapshotImage;
    }
    
    return nil;
}

@end

@implementation NSArray (CampArray)

- (NSArray <Camp *> *)toCampArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:self];
    [mutableArray enumerateObjectsUsingBlock:^(NSDictionary *object, NSUInteger idx, BOOL *stop) {
        if ([object isKindOfClass:[NSDictionary class]]) {
            [mutableArray replaceObjectAtIndex:idx withObject:[[Camp alloc] initWithDictionary:object error:nil]];
        }
    }];
    
    return [mutableArray copy];
}
- (NSArray <NSDictionary *> *)toCampDictionaryArray {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:self];
    [mutableArray enumerateObjectsUsingBlock:^(Camp *object, NSUInteger idx, BOOL *stop) {
        if ([object isKindOfClass:[Camp class]]) {
            [mutableArray replaceObjectAtIndex:idx withObject:[object toDictionary]];
        }
    }];
    
    return [mutableArray copy];
}

@end
