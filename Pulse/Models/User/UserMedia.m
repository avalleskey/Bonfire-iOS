#import "UserMedia.h"

@implementation UserMedia

- (instancetype)initWithDictionary:(NSDictionary *)dict error:(NSError **)err {
    UserMedia *instance = [super initWithDictionary:dict error:err];
    
//    BFHostedVersions *hostedCoverPhoto = [[BFHostedVersions alloc] initWithDictionary:@{@"full": @{@"url": @"https://images.unsplash.com/photo-1495366554757-8568e69d7f80?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=2467&q=80"}} error:nil];
//    instance.coverPhoto = hostedCoverPhoto;
    
    return instance;
}


+ (JSONKeyMapper *)keyMapper
{
    return [JSONKeyMapper mapperForSnakeCase];
}

@end

