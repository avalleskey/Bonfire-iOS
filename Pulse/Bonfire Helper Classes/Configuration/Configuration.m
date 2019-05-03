//
//  Configuration.m
//  Pulse
//
//  Created by Austin Valleskey on 4/11/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "Configuration.h"
#import "HAWebService.h"

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
        
        NSLog(@"self.variables: %@", self.variables);
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
    
    NSLog(@"shared configuration is now: %@", sharedConfiguration);
    
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
