//
//  CameraViewController.h
//  HelloCordova
//
//  Created by Denislava on 125//17.
//
//

#import <Cordova/CDV.h>
#import <UIKit/UIKit.h>

@interface CameraViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *cameraView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *camerViewHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *cameraViewWidth;

- (void)previewPlay:(int*)iPlayPort playView:(UIView*)playView;
- (void)stopPreviewPlay:(int*)iPlayPort;

@property int m_lUserID;
@property int m_nPreviewPort;
@property int m_nPlaybackPort;
@property int m_bPreview;
@property int m_bStopPlayback;

@property NSString* host;
@property NSString* port;
@property NSString* user;
@property NSString* pass;
@property CDVPlugin* plugin;
@property CDVInvokedUrlCommand* command;
@property (strong, nonatomic) IBOutlet UIButton *backButton;

@end
