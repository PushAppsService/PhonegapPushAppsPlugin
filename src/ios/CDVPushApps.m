//
//  CDVPushApps.m
//  PushAppsPhonegapPlugin
//
//  Created by Asaf Ron on 11/21/13.
//
//

#import "CDVPushApps.h"

@interface CDVPushApps()

@end

@implementation CDVPushApps

#define PUSHAPPS_SDK_TYPE_PHONEGAP_COMMAND_LINE @"PUSHAPPS_SDK_TYPE_PHONEGAP_COMMAND_LINE"

- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView
{
    self = [super initWithWebView:theWebView];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkForLaunchOptions:) name:@"UIApplicationDidFinishLaunchingNotification" object:nil];
        
        [[NSUserDefaults standardUserDefaults] setObject:@(1) forKey:PUSHAPPS_SDK_TYPE_PHONEGAP_COMMAND_LINE];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return self;
}

#define PushAppsPhonegapCommandLine_AppToken @"PushAppsPhonegap_AppToken"
#define LastPushMessageDictionary @"PUSHAPPSSDK_LastPushMessageDictionary"

- (void)checkForLaunchOptions:(NSNotification *)notification
{
    NSDictionary *launchOptions = [notification userInfo] ;
    
    // This code will be called immediately after application:didFinishLaunchingWithOptions:.
    NSDictionary *notifDictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (notifDictionary) {
        [[NSUserDefaults standardUserDefaults] setObject:notifDictionary forKey:LastPushMessageDictionary];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#define Callback_RegisterUser @"PUSHAPPSSDK_Callback_RegisterUser"

- (void)registerUser:(CDVInvokedUrlCommand *)command
{
    NSString *appToken = [[command.arguments objectAtIndex:0] objectForKey:@"appToken"];
    
    if ([appToken isKindOfClass:[NSString class]]) {
        
        [[NSUserDefaults standardUserDefaults] setObject:appToken forKey:PushAppsPhonegapCommandLine_AppToken];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Saving callback to user defaults
        [self saveCallbackWithName:Callback_RegisterUser andId:command.callbackId];
        
        // Starting the push apps manager
        [[PushAppsManager sharedInstance] setDelegate:self];
        [[PushAppsManager sharedInstance] startPushAppsWithAppToken:appToken withLaunchOptions:nil];
        
    } else if ([[NSUserDefaults standardUserDefaults] objectForKey:PushAppsPhonegapCommandLine_AppToken]) {
      
        // Saving callback to user defaults
        [self saveCallbackWithName:Callback_RegisterUser andId:command.callbackId];
        
        // Starting the push apps manager
        [[PushAppsManager sharedInstance] setDelegate:self];
        [[PushAppsManager sharedInstance] registerToPushNotification];
        
    } else {
        
        // Clear callback to user defaults
        [self saveCallbackWithName:Callback_RegisterUser andId:@""];
        
        // Throw error to JS
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"App Token must be supplied"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)unRegisterUser:(CDVInvokedUrlCommand*)command
{
    // Starting the push apps manager
    [[PushAppsManager sharedInstance] setDelegate:self];
    [[PushAppsManager sharedInstance] unregisterFromPushNotifications];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setCategoryForPushMessage:(CDVInvokedUrlCommand *)command
{
    NSString *categoryIdentifier = [command.arguments objectAtIndex:0];
    NSArray *actions = [command.arguments objectAtIndex:1];
    
    NSMutableArray *buttonsArray = [NSMutableArray array];
    for (NSInteger i = 0; i < [actions count]; i++) {
        
        NSDictionary *currentDic = [actions objectAtIndex:i];
        NSString *butIdentifier = [currentDic objectForKey:@"identifier"];
        NSString *butTitle = [currentDic objectForKey:@"title"];
        UIUserNotificationActivationMode activationMode = [[currentDic objectForKey:@"activation_mode"] isEqualToString:@"foreground"] ? UIUserNotificationActivationModeForeground : UIUserNotificationActivationModeBackground;
        BOOL isDestructive = [[currentDic objectForKey:@"destructive"] boolValue];
        BOOL isAuthenticationRequired = [[currentDic objectForKey:@"authentication_required"] boolValue];
        
        UIMutableUserNotificationAction *actBut = [[PushAppsManager sharedInstance] createUserNotificationActionWithIdentifier:butIdentifier title:butTitle activationMode:activationMode isDestructive:isDestructive isAuthenticationRequired:isAuthenticationRequired];
        [buttonsArray addObject:actBut];
        
    }
    
    // Saving callback to user defaults, this is the same as for register!
    [self saveCallbackWithName:Callback_RegisterUser andId:command.callbackId];

    [[PushAppsManager sharedInstance] addUserNotificationCategoryWithIdentifier:categoryIdentifier actionsForDefaultContext:buttonsArray andActionsForMinimalContext:buttonsArray];
}

- (void)setApplicationBadgeNumber:(CDVInvokedUrlCommand*)command
{
    NSInteger badgeNumber = [[command.arguments objectAtIndex:0] integerValue];
    [UIApplication sharedApplication].applicationIconBadgeNumber = badgeNumber;
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)isPushEnabled:(CDVInvokedUrlCommand*)command
{
    BOOL enabled = [[PushAppsManager sharedInstance] arePushNotificationsEnabled];
    if (enabled) {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"true"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"false"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)getPushToken:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[[PushAppsManager sharedInstance] getPushToken]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getDeviceId:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[[PushAppsManager sharedInstance] getDeviceId]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getAppVersion:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[[PushAppsManager sharedInstance] getAppVersion]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getSDKVersion:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[[[PushAppsManager sharedInstance] getSDKVersion] stringValue]];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setTags:(CDVInvokedUrlCommand*)command
{
    NSArray *tagsFromJS = [NSArray arrayWithArray:command.arguments];
    NSMutableArray *arrayToServer = [NSMutableArray array];
    
    for (NSInteger i = 0; i < [tagsFromJS count]; i++) {
        
        // Get values from JS
        NSString *identifier = [[tagsFromJS objectAtIndex:i] objectForKey:@"identifier"];
        id value = [[tagsFromJS objectAtIndex:i] objectForKey:@"value"];
        
        // Try parsing a date
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale systemLocale]];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.sssZ"];
        NSDate *date = nil;
        
        @try {
             date = [dateFormatter dateFromString:value];
        }
        @catch (NSException *exception) {
            // Do nothing
        }

        
        if (date) {
            [arrayToServer addObject:[NSDictionary dictionaryWithObjectsAndKeys:date, identifier, nil]];
        }
        else if ([value integerValue]) {
                    
            [arrayToServer addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:[value integerValue]], identifier, nil]];
                    
        } else {
            
            [arrayToServer addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithString:value], identifier, nil]];
            
        }
        
    }
    
    if ([arrayToServer count] > 0) {
        
        [[PushAppsManager sharedInstance] addTags:arrayToServer andOperationStatus:^(BOOL success, NSString *msg) {
           
            if (success) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
            else {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:msg];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
            
        }];
        
    }
    else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No valid types were found"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

}

- (void)removeTags:(CDVInvokedUrlCommand*)command
{
    if ([[NSArray arrayWithArray:command.arguments] count] > 0) {
        
        NSMutableArray *array = [NSMutableArray array];
        
        for (NSInteger i = 0; i < [command.arguments count]; i++) {
            
            if ([[command.arguments objectAtIndex:i] isKindOfClass:[NSString class]]) {
                
                [array addObject:[command.arguments objectAtIndex:i]];
                
            }
            
        }
        
        [[PushAppsManager sharedInstance] removeTagsWithIdentifiers:array andOperationStatus:^(BOOL success, NSString *msg) {
            
            if (success) {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@""];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
            else {
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:msg];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
            
        }];
    }
}

- (void)saveCallbackWithName:(NSString *)name andId:(NSString *)callbackId
{
    // Saving callback to user defaults
    [[NSUserDefaults standardUserDefaults] setObject:callbackId forKey:name];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)getCallbackIdForAction:(NSString *)action
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:action];
}

#pragma mark - push apps delegate

- (void)pushApps:(PushAppsManager *)manager didReceiveRemoteNotification:(NSDictionary *)pushNotification whileInForeground:(BOOL)inForeground
{
    [self updateWithMessageParams:pushNotification];
}

- (void)pushApps:(PushAppsManager *)manager handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    [dictionary setObject:identifier forKey:@"iOSActionIdentifier"];
    [self updateWithMessageParams:dictionary];
    
    completionHandler();
}

- (void)updateWithMessageParams:(NSDictionary *)pushNotification
{
    // Clear application badge
    [[PushAppsManager sharedInstance] clearApplicationBadge];
    
    NSMutableDictionary *parsedDictionary = [NSMutableDictionary dictionary];
    NSError *innerJSONparsingError;
    for (id key in pushNotification) {
        if ([[pushNotification objectForKey:key] isKindOfClass:[NSString class]]) {
            
            NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData: [[pushNotification objectForKey:key] dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error: &innerJSONparsingError];
            
            if (JSON) {
                [parsedDictionary setObject:JSON forKey:key];
            }
            else {
                [parsedDictionary setObject:[pushNotification objectForKey:key] forKey:key];
            }
            
        }
        else {
            [parsedDictionary setObject:[pushNotification objectForKey:key] forKey:key];
        }
    }
    
    // Creating equal object for iOS and Android
    NSMutableDictionary *orderedDictionary = [NSMutableDictionary dictionary];
    
    for (NSString *key in [parsedDictionary allKeys]) {
        
        if ([key isEqualToString:@"aps"]) {
        
            if ([[parsedDictionary objectForKey:key] objectForKey:@"alert"]) {
                [orderedDictionary setObject:[[parsedDictionary objectForKey:key] objectForKey:@"alert"] forKey:@"Message"];
            }
            if ([[parsedDictionary objectForKey:key] objectForKey:@"badge"]) {
                [orderedDictionary setObject:[[parsedDictionary objectForKey:key] objectForKey:@"badge"] forKey:@"Badge"];
            }
            if ([[parsedDictionary objectForKey:key] objectForKey:@"sound"]) {
                [orderedDictionary setObject:[[parsedDictionary objectForKey:key] objectForKey:@"sound"] forKey:@"Sound"];
            }
            if ([[parsedDictionary objectForKey:key] objectForKey:@"category"]) {
                [orderedDictionary setObject:[[parsedDictionary objectForKey:key] objectForKey:@"category"] forKey:@"iOSCategory"];
            }
            
        } else {
            
            [orderedDictionary setObject:[parsedDictionary objectForKey:key] forKey:key];
            
        }
        
    }
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:orderedDictionary options:0 error:&error];
    
    NSString *jsonString = @"{}";
    if (jsonData) {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
        
    [self performSelector:@selector(updateJSWithReceivedPushNotificationParams:) withObject:jsonString afterDelay:0.1];
}

- (void)updateJSWithReceivedPushNotificationParams:(NSString *)jsonString
{
    // Update JS
    NSString *javascripCode = [NSString stringWithFormat:@"PushNotification.messageReceive('%@')", jsonString];
    [self performSelectorOnMainThread:@selector(writeJavascript:) withObject:javascripCode waitUntilDone:YES];
}

- (void)pushApps:(PushAppsManager *)manager didUpdateUserToken:(NSString *)pushToken
{
    // Update JS
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:pushToken];
    
    NSString *callbackId = [self getCallbackIdForAction:Callback_RegisterUser];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
    
    NSDictionary *checkForLastMessage = [[NSUserDefaults standardUserDefaults] objectForKey:LastPushMessageDictionary];
    if (checkForLastMessage) {
        [self updateWithMessageParams:checkForLastMessage];
        
        // Clear last message
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:LastPushMessageDictionary];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)pushApps:(PushAppsManager *)manager registrationForRemoteNotificationFailedWithError:(NSError *)error
{
    // Update JS
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
    
    NSString *callbackId = [self getCallbackIdForAction:Callback_RegisterUser];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:callbackId];
}

@end
