//
//  Configuration.m
//  Pulse
//
//  Created by Austin Valleskey on 4/11/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "Configuration.h"
#import "HAWebService.h"

#import "User.h"
#import "Camp.h"
#import "Post.h"
#import "NSURL+WebsiteTypeValidation.h"
#import "NSString+Validation.h"

#define ConfigurationDEVELOPMENT @"development"
#define ConfigurationPRODUCTION @"production"

#define ConfigurationAPI_BASE_URI @"API_BASE_URI"
#define ConfigurationAPI_CURRENT_VERSION @"API_CURRENT_VERSION"
#define ConfigurationAPI_KEY @"API_KEY"

#define ConfigurationPLIST @"Configurations"
#define ConfigurationPLIST_DEBUG ConfigurationPLIST@"-debug"

@interface Configuration ()

@property (copy, nonatomic) NSString *configuration;
@property (nonatomic) BOOL development;
@property (nonatomic, strong) NSDictionary *variables;

@end

@implementation Configuration

#ifdef DEBUG
NSString * const LOCAL_APP_URI = @"bonfireapp.debug";
#else
NSString * const LOCAL_APP_URI = @"bonfireapp";
#endif

#pragma mark -
#pragma mark Shared Configuration
+ (Configuration *)sharedConfiguration {
    static Configuration *_sharedConfiguration = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedConfiguration = [[self alloc] init];
    });
    
    return _sharedConfiguration;
}

#pragma mark -
#pragma mark Private Initialization
- (id)init {
    self = [super init];
    
    if (self) {
        // Fetch Current Configuration
        NSBundle *mainBundle = [NSBundle mainBundle];
        self.configuration = [[mainBundle infoDictionary] objectForKey:@"Configuration"];
        
        // Load Configurations
        NSString *path = [mainBundle pathForResource:ConfigurationPLIST ofType:@"plist"];
        NSDictionary *configurations = [NSDictionary dictionaryWithContentsOfFile:path];
        
        #ifdef DEBUG
        NSString *localPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:ConfigurationPLIST_DEBUG@".plist"];
        if (![NSDictionary dictionaryWithContentsOfFile:localPath]) {
            // create local config file
            [configurations writeToFile:localPath atomically:YES];
        }
        // update config variable with the debug config
        configurations = [NSDictionary dictionaryWithContentsOfFile:localPath];
        
        self.development = [[configurations objectForKey:self.configuration] isEqualToString:ConfigurationDEVELOPMENT];
        #else
        // only allow development if in debug mode
        self.development = false;
        #endif
        
        self.variables = configurations[@"environments"][self.development?ConfigurationDEVELOPMENT:ConfigurationPRODUCTION];
        
        // NSLog(@"self.variables: %@", self.variables);
    }
    
    return self;
}
- (void)saveDebugConfigFile {
    
}

#pragma mark -
+ (NSString *)configuration {
    return [[Configuration sharedConfiguration] configuration];
}
+ (BOOL)isDevelopment {
    return [[Configuration sharedConfiguration] development];
}

#pragma mark -
+ (NSString *)API_BASE_URI {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    if (sharedConfiguration.variables) {
        return [sharedConfiguration.variables objectForKey:ConfigurationAPI_BASE_URI];
    }
    
    return nil;
}

+ (NSString *)API_CURRENT_VERSION {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    if (sharedConfiguration.variables) {
        return [sharedConfiguration.variables objectForKey:ConfigurationAPI_CURRENT_VERSION];
    }
    
    return nil;
}

+ (NSString *)API_KEY {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    if (sharedConfiguration.variables) {
        return [sharedConfiguration.variables objectForKey:ConfigurationAPI_KEY];
    }
    
    return nil;
}

#pragma mark - Internal URL Helpers
+ (BOOL)isInternalURL:(NSURL *)url {
    if ([url.scheme isEqualToString:LOCAL_APP_URI]) {
        return true;
    }
    
    return false;
}
+ (id)objectFromInternalURL:(NSURL *)url {
    if (![self isInternalURL:url]) {
        return false;
    }
    
    // Get parameters
    NSURLComponents *components = [NSURLComponents componentsWithString:url.absoluteString];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for(NSURLQueryItem *item in components.queryItems)
    {
        [params setObject:item.value forKey:item.name];
    }
    
    // Check if the URL is a supported type
    if ([url.host isEqualToString:@"user"]) {
        User *user = [[User alloc] init];
        IdentityAttributes *attributes = [[IdentityAttributes alloc] init];
        
        if ([params objectForKey:@"id"]) {
            user.identifier = params[@"id"];
        }
        if ([params objectForKey:@"username"]) {
            attributes.identifier = params[@"username"];
        }
        
        user.attributes = attributes;
        
        return user;
    }
    if ([url.host isEqualToString:@"camp"]) {
        Camp *camp = [[Camp alloc] init];
        CampAttributes *attributes = [[CampAttributes alloc] init];
        
        if ([params objectForKey:@"id"]) {
            camp.identifier = params[@"id"];
        }
        if ([params objectForKey:@"display_id"]) {
            attributes.identifier = [params[@"display_id"] stringByReplacingOccurrencesOfString:@"#" withString:@""];
        }
        
        camp.attributes = attributes;
        
        return camp;
    }
    if ([url.host isEqualToString:@"post"]) {
        Post *post = [[Post alloc] init];
        if ([params objectForKey:@"id"]) {
            post.identifier = [NSString stringWithFormat:@"%@", params[@"id"]];
        }
        
        return post;
    }
    
    // unkown internal link type
    return nil;
}
+ (BOOL)isExternalBonfireURL:(NSURL *)url {
    if ([url matches:@"^(?:https?:\\/\\/)?(?:www\\.)?bonfire\\.camp\\b\\/((?:u\\/(?:[a-zA-Z0-9\\_]{1,30}|-[a-zA-Z0-9]{12,}))|(?:c\\/(?:[a-zA-Z0-9\\_]{1,30}|-[a-zA-Z0-9]{12,}))|(?:p\\/(?:[0-9]{1,})))$"]) {
        return true;
    }
    
    return false;
}
+ (id)objectFromExternalBonfireURL:(NSURL *)url {
    
    if (![self isExternalBonfireURL:url]) {
        return false;
    }
    
    // Get parameters
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:true];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for(NSURLQueryItem *item in components.queryItems)
    {
        [params setObject:item.value forKey:item.name];
    }
    
    if (components.path.length == 0) {
        return nil;
    }
    
    NSArray *pathComponents = [components.path componentsSeparatedByString:@"/"];
    BOOL camp = [pathComponents[1] isEqualToString:@"c"];
    BOOL user = [pathComponents[1] isEqualToString:@"u"];
    BOOL post = [pathComponents[1] isEqualToString:@"p"];
    NSString *parent = pathComponents[2];
    
    /*                     01   2      3 
     - https://bonfire.camp/c/{camptag}
     - https://bonfire.camp/u/{username}
     - https://bonfire.camp/p/{post_id}
     */
    
    // Check if the URL is a supported type
    if (parent && parent.length > 0) {
        if (user) {
            User *user = [[User alloc] init];
            if ([parent validateBonfireUsername] == BFValidationErrorNone) {
                // https://bonfire.camp/u/{username}
                
                // load using the username
                IdentityAttributes *attributes = [[IdentityAttributes alloc] init];
                attributes.identifier = [parent stringByReplacingOccurrencesOfString:@"@" withString:@""];
                
                user.attributes = attributes;
            }
            else {
                // https://bonfire.camp/u/{id}
                
                // load using the id
                user.identifier = parent;
            }
                    
            return user;
        }
        else if (camp) {
            Camp *camp = [[Camp alloc] init];
            if ([parent validateBonfireCampTag] == BFValidationErrorNone) {
                // https://bonfire.camp/c/{camptag}
                
                CampAttributes *attributes = [[CampAttributes alloc] init];
                attributes.identifier = parent;
                
                camp.attributes = attributes;
            }
            else {
                // https://bonfire.camp/c/{id}
                
                // load using the id
                camp.identifier = parent;
            }
                    
            return camp;
        }
        else if (post) {
            // https://bonfire.camp/p/{post_id}
                    
            // open post
            Post *post =  [[Post alloc] init];
            post.identifier = parent;
                    
            return post;
        }
    }

    // unkown internal link type
    return nil;
}
+ (BOOL)isBonfireURL:(NSURL *)url {
    return [self isInternalURL:url] || [self isExternalBonfireURL:url];
}

#pragma mark -
+ (void)switchToDevelopment {
    #ifdef DEBUG
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    NSString *localPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:ConfigurationPLIST_DEBUG@".plist"];
    NSMutableDictionary *configurations = [[NSMutableDictionary alloc] initWithDictionary:[NSDictionary dictionaryWithContentsOfFile:localPath]];
    [configurations setObject:ConfigurationDEVELOPMENT forKey:sharedConfiguration.configuration];
    
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:configurations format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    if (plistData) {
        [plistData writeToFile:localPath atomically:YES];
        sharedConfiguration.development = YES;
        sharedConfiguration.variables = configurations[@"environments"][ConfigurationDEVELOPMENT];
    }
    
    [HAWebService reset];
    #endif
}
+ (void)switchToProduction {
    #ifdef DEBUG
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    NSString *localPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:ConfigurationPLIST_DEBUG@".plist"];
    NSMutableDictionary *configurations = [[NSMutableDictionary alloc] initWithDictionary:[NSDictionary dictionaryWithContentsOfFile:localPath]];
    [configurations setObject:ConfigurationPRODUCTION forKey:sharedConfiguration.configuration];
    
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:configurations format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    if (plistData) {
        [plistData writeToFile:localPath atomically:YES];
        sharedConfiguration.development = NO;
        sharedConfiguration.variables = configurations[@"environments"][ConfigurationPRODUCTION];
    }
    
    [HAWebService reset];
    #endif
}
+ (void)replaceDevelopmentURIWith:(NSString *)newURI {
    #ifdef DEBUG
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    NSString *localPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:ConfigurationPLIST_DEBUG@".plist"];
    NSMutableDictionary *configurations = [[NSMutableDictionary alloc] initWithDictionary:[NSDictionary dictionaryWithContentsOfFile:localPath]];
    NSMutableDictionary *environments = [[NSMutableDictionary alloc] initWithDictionary:configurations[@"environments"]];
    NSMutableDictionary *development = [[NSMutableDictionary alloc] initWithDictionary:environments[ConfigurationDEVELOPMENT]];
    [development setObject:newURI forKey:ConfigurationAPI_BASE_URI];
    
    [environments setObject:development forKey:ConfigurationDEVELOPMENT];
    [configurations setObject:environments forKey:@"environments"];
    
    NSError *error = nil;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:configurations format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
    
    if (plistData) {
        [plistData writeToFile:localPath atomically:YES];
        if (sharedConfiguration.development) {
            sharedConfiguration.variables = configurations[@"environments"][ConfigurationDEVELOPMENT];
        }
    }
        
    [HAWebService reset];
    #endif
}

#pragma mark - Misc. Getters
+ (NSString *)DEVELOPMENT_BASE_URI {
    #ifdef DEBUG
    
    // Load Configurations
    NSString *localPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:ConfigurationPLIST_DEBUG@".plist"];
    NSDictionary *configurations = [NSDictionary dictionaryWithContentsOfFile:localPath];
    
    // Load Variables for Current Configuration
    return configurations[@"environments"][ConfigurationDEVELOPMENT][ConfigurationAPI_BASE_URI];
    
    #else
    
    return nil;
    
    #endif
}

+ (BOOL)isDebug {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    if (sharedConfiguration.configuration) {
        return [sharedConfiguration.configuration isEqualToString:@"Debug"];
    }
    
    return false;
}
+ (BOOL)isBeta {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    if (sharedConfiguration.configuration) {
        return [sharedConfiguration.configuration isEqualToString:@"Beta"];
    }
    
    return false;
}
+ (BOOL)isRelease {
    Configuration *sharedConfiguration = [Configuration sharedConfiguration];
    
    if (sharedConfiguration.configuration) {
        return [sharedConfiguration.configuration isEqualToString:@"Release"];
    }
    
    return false;
}

@end
