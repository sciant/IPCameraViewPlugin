/********* IPCamView.m Cordova Plugin Implementation *******/

#import <Cordova/CDV.h>
#import "CameraViewController.h"
#import "MainViewController.h"
#import "AppDelegate.h"

@interface IPCamView : CDVPlugin {
  // Member variables go here.

}

- (void) play:(CDVInvokedUrlCommand*)command;
@end

@implementation IPCamView

NSString *const  LOGIN_FAILED = @"LOGIN_FAILED";
NSString *const  INVALID_PORT = @"INVALID_PORT";
NSString *const  INVALID_ACTION = @"INVALID_ACTION";
NSString *const  UNEXPECTED_ERROR = @"UNEXPECTED_ERROR";
NSString *const  INCORRECT_PARAMS = @"INCORRECT_PARAMS";


- (void) play:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;

    u_long argumentCount = [command.arguments count];

    if (argumentCount == 4)
    {
        NSString* host = [command.arguments objectAtIndex:0];
        NSString* port = [command.arguments objectAtIndex:1];
        NSString* user = [command.arguments objectAtIndex:2];
        NSString* pass = [command.arguments objectAtIndex:3];

        NSString *echo = [NSString stringWithFormat:@"Host: %@, Port: %@, User: %@, Pass: %@",
                                               host, port, user, pass];
        // Sanitize data
        if (![port intValue])
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:INVALID_PORT];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
        if (![command.methodName isEqualToString:@"play"])
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:INVALID_ACTION];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
        @try {
            MainViewController* vc =  (MainViewController*)[[(AppDelegate*)
                                                             [[UIApplication sharedApplication]delegate] window] rootViewController];
            
            CameraViewController *cameraVC = [[CameraViewController alloc] init];
            cameraVC.host = host;
            cameraVC.port = port;
            cameraVC.user = user;
            cameraVC.pass = pass;
            cameraVC.plugin = self;
            cameraVC.command = command;
            [vc presentViewController:cameraVC animated:YES completion:nil];
        }
        @catch (NSException * e) {
            NSLog(@"Exception: %@", e);
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:UNEXPECTED_ERROR];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            return;
        }
        
        //pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
        
    }
    else
    {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:INCORRECT_PARAMS];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

    //[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
}

@end
