//
//  CameraViewController.m
//  HelloCordova
//
//  Created by Denislava on 125//17.
//
//

#import "CameraViewController.h"
#import "DeviceInfo.h"
#import "IOSPlayM4.h"
#import "hcnetsdk.h"
#import "HikDec.h"
#import "Preview.h"
#import "EzvizTrans.h"
#import "CameraViewController.h"
#import <Foundation/Foundation.h>
#include <stdio.h>
#include <ifaddrs.h>
#include <sys/socket.h>
#include <sys/poll.h>
#include <net/if.h>
#include <map>


@implementation CameraViewController

//MARK: Player related VARS

int g_iStartChan = 0;
int g_iPreviewChanNum = 0;
bool g_bDecode = true;
FILE					*m_fp;
id                      m_playThreadID;
unsigned char			*pBuf;
bool					m_bThreadRun;
int                     m_lRealPlayID;
int                     m_lPlaybackID;
bool                    m_bPreview;
bool                    m_bRecord;
bool                    m_bPTZL;
bool                    m_bVoiceTalk;
bool                    m_bStopPlayback;

CameraViewController *g_pController = NULL;

- (void)viewDidLoad {
   
    _m_lUserID = -1;
    _m_nPreviewPort = -1;
    _m_nPlaybackPort = -1;
    _m_bPreview = -1;
    _m_bStopPlayback = -1;
    
    g_pController = self;

     [super viewDidLoad];
    
    [self.backButton addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
   
}

- (IBAction)btnClicked:(id)sender
{
    stopPreview(0);
     m_bPreview = false;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self cameraLogin];
    
    if (self.view.bounds.size.height > self.view.bounds.size.width) {
        self.camerViewHeight.constant = (self.view.frame.size.width / 4) * 3;
        self.cameraViewWidth.constant = self.view.frame.size.width;
    } else {
        self.camerViewHeight.constant = self.view.frame.size.height;
        self.cameraViewWidth.constant = self.view.frame.size.height + (self.view.frame.size.height/4);
    }
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];

    //layout
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        if (size.height > size.width) {
            self.camerViewHeight.constant = (self.view.frame.size.width / 4) * 3;
            self.cameraViewWidth.constant = self.view.frame.size.width;
        } else {
            self.camerViewHeight.constant = self.view.frame.size.height;
            self.cameraViewWidth.constant = self.view.frame.size.height + (self.view.frame.size.height/4);
        }
       
    }];
}


//- (BOOL)shouldAutorotate
//{
//    return NO;
//}
//
//#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
//- (NSUInteger)supportedInterfaceOrientations
//#else
//- (UIInterfaceOrientationMask)supportedInterfaceOrientations
//#endif
//{
//    return UIInterfaceOrientationMaskPortrait;
//}


//MARK: Login

- (void)cameraLogin {
    
    // init
    BOOL bRet = NET_DVR_Init();
    if (!bRet)
    {
        NSLog(@"NET_DVR_Init failed");
    }
    NET_DVR_SetExceptionCallBack_V30(0, NULL, g_fExceptionCallBack, NULL);
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    const char* pDir = [documentPath UTF8String];
    NET_DVR_SetLogToFile(3, (char*)pDir, true);
    
    if([self loginNormalDevice])
    {
        [self loadPlayer];
    }
}



- (bool) loginNormalDevice
{
    //  Get value
    //WORKING
    //NSString * iP = @"10.5.0.112";
    //NSString * port = @"8000";
    //NSString * usrName = @"admin";
    //NSString * password = @"12345";
    
    //REAL
    //TODO: Uncomment
    NSString * iP = self.host;
    NSString * port = self.port;
    NSString * usrName = self.user;
    NSString * password = self.pass;

    
    DeviceInfo *deviceInfo = [[DeviceInfo alloc] init];
    deviceInfo.chDeviceAddr = iP;
    deviceInfo.nDevicePort = [port integerValue];
    deviceInfo.chLoginName = usrName;
    deviceInfo.chPassWord = password;
    
    // device login
    NET_DVR_DEVICEINFO_V30 logindeviceInfo = {0};
    
    // encode type
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    _m_lUserID = NET_DVR_Login_V30((char*)[deviceInfo.chDeviceAddr UTF8String],
                                   deviceInfo.nDevicePort,
                                   (char*)[deviceInfo.chLoginName cStringUsingEncoding:enc],
                                   (char*)[deviceInfo.chPassWord UTF8String],
                                   &logindeviceInfo);
    
    printf("iP:%s\n", (char*)[deviceInfo.chDeviceAddr UTF8String]);
    printf("Port:%d\n", deviceInfo.nDevicePort);
    printf("UsrName:%s\n", (char*)[deviceInfo.chLoginName cStringUsingEncoding:enc]);
    printf("Password:%s\n", (char*)[deviceInfo.chPassWord UTF8String]);
    
    // login on failed
    if (_m_lUserID == -1)
    {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:kWarningTitle
                              message:kLoginDeviceFailMsg
                              delegate:nil
                              cancelButtonTitle:kWarningConfirmButton
                              otherButtonTitles:nil];
        [alert show];
        return false;
    }
    
    if(logindeviceInfo.byChanNum > 0)
    {
        g_iStartChan = logindeviceInfo.byStartChan;
        g_iPreviewChanNum = logindeviceInfo.byChanNum;
    }
    else if(logindeviceInfo.byIPChanNum > 0)
    {
        g_iStartChan = logindeviceInfo.byStartDChan;
        g_iPreviewChanNum = logindeviceInfo.byIPChanNum + logindeviceInfo.byHighDChanNum * 256;
    }
    
    
    return true;
}



//MARK: Video Rendering related method
- (void)previewPlay:(int*)iPlayPort playView:(UIView*)playView
{
    _m_nPreviewPort = *iPlayPort;
    int iRet = PlayM4_Play(*iPlayPort, (__bridge PLAYM4_HWND)playView);
    PlayM4_PlaySound(*iPlayPort);
    if (iRet != 1)
    {
        NSLog(@"PlayM4_Play fail");
        stopPreview(0);
         m_bPreview = false;
        return;
    }
}

-(void) loadPlayer
{
    NSLog(@"liveStreamBtnClicked");

    if(g_iPreviewChanNum > 1)
    {
        if(!m_bPreview)
        {
            int iPreviewID[MAX_VIEW_NUM] = {0};
            for(int i = 0; i < MAX_VIEW_NUM; i++)
            {
                iPreviewID[i] = startPreview(_m_lUserID, g_iStartChan, _cameraView, i);
            }
            m_lRealPlayID = iPreviewID[0];
            m_bPreview = true;
        }
        else
        {
            for(int i = 0; i < MAX_VIEW_NUM; i++)
            {
                    stopPreview(i);
            }
            m_bPreview = false;
        }
    }
    else
    {
        if(!m_bPreview)
        {
            
            m_lRealPlayID = startPreview(_m_lUserID, g_iStartChan, _cameraView, 0);
            if(m_lRealPlayID >= 0)
            {
                m_bPreview = true;
    
            }
        }
        else
        {
            stopPreview(0);
            m_bPreview = false;
        }
    }
}



//start player
- (void) startPlayer
{
    [self performSelectorOnMainThread:@selector(playerPlay)
                           withObject:nil
                        waitUntilDone:NO];
}



//MARK: Player Callbacks


//play,the function PlayM4_Play must be called in main thread
- (void) playerPlay
{
    int nRet = 0;
    if(m_bPreview)
    {
        nRet = PlayM4_Play(_m_nPreviewPort, (__bridge PLAYM4_HWND)_cameraView);
        PlayM4_PlaySound(_m_nPreviewPort);
    }
    else
    {
        nRet = PlayM4_Play(_m_nPlaybackPort, (__bridge PLAYM4_HWND)_cameraView);
        PlayM4_PlaySound(_m_nPlaybackPort);
    }
    if (nRet != 1)
    {
        NSLog(@"PlayM4_Play fail");
         [self stopPlay];
        
        return;
    }
}

- (void)stopPreviewPlay:(int*)iPlayPort
{
    PlayM4_StopSound();
    if (!PlayM4_Stop(*iPlayPort))
    {
        NSLog(@"PlayM4_Stop failed");
    }
    if(!PlayM4_CloseStream(*iPlayPort))
    {
        NSLog(@"PlayM4_CloseStream failed");
    }
    if (!PlayM4_FreePort(*iPlayPort))
    {
        NSLog(@"PlayM4_FreePort failed");
    }
    *iPlayPort = -1;
}
//stop preview
-(void) stopPlay
{
    if (m_lRealPlayID != -1)
    {
        NET_DVR_StopRealPlay(m_lRealPlayID);
        m_lRealPlayID = -1;
    }
    
    if(_m_nPreviewPort >= 0)
    {
        if(!PlayM4_StopSound())
        {
            NSLog(@"PlayM4_StopSound failed");
        }
        if (!PlayM4_Stop(_m_nPreviewPort))
        {
            NSLog(@"PlayM4_Stop failed");
        }
        if(!PlayM4_CloseStream(_m_nPreviewPort))
        {
            NSLog(@"PlayM4_CloseStream failed");
        }
        if (!PlayM4_FreePort(_m_nPreviewPort))
        {
            NSLog(@"PlayM4_FreePort failed");
        }
        _m_nPreviewPort = -1;
    }
}



//playback exeption function
void g_fExceptionCallBack(DWORD dwType, LONG lUserID, LONG lHandle, void *pUser)
{
    NSLog(@"g_fExceptionCallBack Type[0x%x], UserID[%d], Handle[%d]", dwType, lUserID, lHandle);
}

//playback callback function
void fPlayDataCallBack_V40(LONG lPlayHandle, DWORD dwDataType, BYTE *pBuffer,DWORD dwBufSize,void *pUser)
{
    CameraViewController *pDemo = (__bridge CameraViewController*)pUser;
    int i = 0;
    switch (dwDataType)
    {
        case NET_DVR_SYSHEAD:
            if (dwBufSize > 0 && pDemo->_m_nPlaybackPort == -1)
            {
                if(PlayM4_GetPort(&pDemo->_m_nPlaybackPort) != 1)
                {
                    NSLog(@"PlayM4_GetPort failed:%d",  NET_DVR_GetLastError());
                    break;
                }
                if (!PlayM4_SetStreamOpenMode(pDemo->_m_nPlaybackPort, STREAME_FILE))
                {
                    break;
                }
                if (!PlayM4_OpenStream(pDemo->_m_nPlaybackPort, pBuffer , dwBufSize, 2*1024*1024))
                {
                    break;
                }
                pDemo->_m_bPreview = 0;
                [pDemo startPlayer];
            }
            break;
        default:
            if (dwBufSize > 0 && pDemo->_m_nPlaybackPort != -1 && !pDemo->_m_bStopPlayback)
            {
                for(i = 0; i < 4000; i++)
                {
                    if(PlayM4_InputData(pDemo->_m_nPlaybackPort, pBuffer, dwBufSize))
                    {
                        break;
                    }
                    usleep(10*1000);
                }
            }
            break;
    }
}



@end
