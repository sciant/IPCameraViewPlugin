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
        MainViewController* vc =  (MainViewController*)[[(AppDelegate*)
                                                         [[UIApplication sharedApplication]delegate] window] rootViewController];
        
        CameraViewController *cameraVC = [[CameraViewController alloc] init];
        cameraVC.host = host;
        cameraVC.port = port;
        cameraVC.user = user;
        cameraVC.pass = pass;
        [vc presentViewController:cameraVC animated:YES completion:nil];
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
        
    }
    else
    {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Exactly 4 parameters are expected"];    
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    
    /*
    CDVPluginResult* pluginResult = nil;
    NSString* echo = [command.arguments objectAtIndex:0];

    if (echo != nil && [echo length] > 0) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:echo];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    */
}

@end
