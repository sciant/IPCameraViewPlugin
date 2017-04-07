package com.sciant.ipcamplugin;

import android.app.Activity;
import android.content.res.Configuration;
import android.content.res.Resources;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Gravity;
import android.view.SurfaceView;
import android.view.View;
import android.view.Window;
import android.widget.FrameLayout;

import com.hikvision.netsdk.ExceptionCallBack;
import com.hikvision.netsdk.HCNetSDK;
import com.hikvision.netsdk.NET_DVR_DEVICEINFO_V30;
import com.hikvision.netsdk.NET_DVR_PREVIEWINFO;
import com.hikvision.netsdk.RealPlayCallBack;

import org.MediaPlayer.PlayM4.Player;

public class CameraPlayer extends Activity {
    private int m_iStartChan = 0; // start channel no
    private int m_iChanNum = 0; // channel number
    private int m_iLogID = -1; // return by NET_DVR_Login_v30
    private int m_iPlayID = -1; // return by NET_DVR_RealPlay_V30
    private int m_iPort = -1; // play port
    private boolean m_bStopPlayback = false;
    private SurfaceView m_osurfaceView = null;
    private static PlaySurfaceView[] playView = new PlaySurfaceView[4];

    private final String TAG = "SCNT_CAM_PLAY";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        this.requestWindowFeature(Window.FEATURE_NO_TITLE);
        String packageName = getApplication().getPackageName();
        Resources resources = getApplication().getResources();

        if (getResources().getConfiguration().orientation == Configuration.ORIENTATION_PORTRAIT) {
            setContentView(resources.getIdentifier("cordova_plugin_ipcamview_portrait", "layout", packageName));
        } else if (getResources().getConfiguration().orientation == Configuration.ORIENTATION_LANDSCAPE) {
            setContentView(resources.getIdentifier("cordova_plugin_ipcamview_ladscape", "layout", packageName));
        } else {
            setContentView(resources.getIdentifier("cordova_plugin_ipcamview_portrait", "layout", packageName));
        }
        Log.d(TAG, "CameraPlayer created");
        int surfaceViewId = resources.getIdentifier("surfaceView","id",packageName);
        m_osurfaceView = (SurfaceView) findViewById(surfaceViewId);

        initSdk();
    }

    @Override
    protected void onPostResume(){
        super.onPostResume();
        Log.d(TAG,"onPostResume");
        PlayerStarter ps = new PlayerStarter(this);
        AsyncTask.execute(ps);
    }

    @Override
    protected void onPause(){
        super.onPause();
        Log.d(TAG,"onPause");
        stop();
    }

    public boolean isReady() {
        if (m_osurfaceView == null || m_osurfaceView.getHolder() == null ||
                m_osurfaceView.getHolder().getSurface() == null) {
            return false;
        }
        return m_osurfaceView.getHolder().getSurface().isValid();

    }

    private boolean initSdk() {
        Log.d(TAG,"init net sdk");
        if (!HCNetSDK.getInstance().NET_DVR_Init()) {
            Log.d(TAG,"HCNetSDK init is failed!");
            return false;
        }
        return true;
    }

    public void closeButtonClick(View view) {
        Log.d(TAG,"closeButtonClick");
        finish();
    }

    protected void play(String host, int port, String user, String pass) {
        NET_DVR_DEVICEINFO_V30 m_oNetDvrDeviceInfoV30 = new NET_DVR_DEVICEINFO_V30();
        Log.d(TAG,"SCNT_CAM_PLAY Before login host=" + host + " port=" + port + " user=" + user + " pass=" + pass);
        m_iLogID = HCNetSDK.getInstance().NET_DVR_Login_V30(host,  port, user, pass, m_oNetDvrDeviceInfoV30);
        if (m_iLogID < 0) {
            Log.d(TAG,"NET_DVR_Login is failed!Err:" + HCNetSDK.getInstance().NET_DVR_GetLastError());
            PluginResult.error(PluginResult.LOGIN_FAILED);
            finish();
            return;
        }

        Log.d(TAG,"after login, login id = " + m_iLogID);
        if (m_oNetDvrDeviceInfoV30.byChanNum > 0) {
            m_iStartChan = m_oNetDvrDeviceInfoV30.byStartChan;
            m_iChanNum = m_oNetDvrDeviceInfoV30.byChanNum;
        } else if (m_oNetDvrDeviceInfoV30.byIPChanNum > 0) {
            m_iStartChan = m_oNetDvrDeviceInfoV30.byStartDChan;
            m_iChanNum = m_oNetDvrDeviceInfoV30.byIPChanNum
                    + m_oNetDvrDeviceInfoV30.byHighDChanNum * 256;
        }

        ExceptionCallBack oexceptionCbf = getExceptiongCbf();
        if (oexceptionCbf == null) {
            Log.d(TAG,"ExceptionCallBack object is failed!");
            return;
        }

        if (!HCNetSDK.getInstance().NET_DVR_SetExceptionCallBack(
                oexceptionCbf)) {
            Log.d(TAG,"NET_DVR_SetExceptionCallBack is failed!");
            return;
        }

        if (m_iChanNum > 1)// preview more than a channel
        {
            Log.d(TAG,"before startMultiPreview");
            startMultiPreview();

        } else // preivew a channel
        {
            Log.d(TAG,"before startSinglePreview");
            startSinglePreview();
        }
    }

    private void startSinglePreview() {
        RealPlayCallBack fRealDataCallBack = getRealPlayerCbf();
        if (fRealDataCallBack == null) {
            Log.d(TAG,"fRealDataCallBack object is failed!");
            return;
        }
        Log.d(TAG,"m_iStartChan:" + m_iStartChan);

        NET_DVR_PREVIEWINFO previewInfo = new NET_DVR_PREVIEWINFO();
        Log.d(TAG,"NET_DVR_PREVIEWINFO()");

        previewInfo.lChannel = m_iStartChan;
        previewInfo.dwStreamType = 0; // substream
        previewInfo.bBlocked = 1;
        // HCNetSDK start preview
        Log.d(TAG,"Before HCNetSDK start preview" + m_iLogID + ", " + previewInfo + ", " + fRealDataCallBack);

        m_iPlayID = HCNetSDK.getInstance().NET_DVR_RealPlay_V40(m_iLogID,
                previewInfo, fRealDataCallBack);

        if (m_iPlayID < 0) {
            Log.d(TAG,"NET_DVR_RealPlay is failed!Err:"
                    + HCNetSDK.getInstance().NET_DVR_GetLastError());
            return;
        }

        PluginResult.success();
        Log.d(TAG,"NetSdk Play success!!!");

    }

    private void startMultiPreview() {
        DisplayMetrics metric = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(metric);
        for (int i = 0; i < 4; i++) {
            if (playView[i] == null) {
                playView[i] = new PlaySurfaceView(this);
                playView[i].setParam(metric.widthPixels);
                FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.WRAP_CONTENT,
                        FrameLayout.LayoutParams.WRAP_CONTENT);
                params.bottomMargin = playView[i].getCurHeight() - (i / 2)
                        * playView[i].getCurHeight();
                params.leftMargin = (i % 2) * playView[i].getCurWidth();
                params.gravity = Gravity.BOTTOM | Gravity.LEFT;
                addContentView(playView[i], params);
            }
            playView[i].startPreview(m_iLogID, m_iStartChan + i);
        }
        m_iPlayID = playView[0].m_iPreviewHandle;

        PluginResult.success();
        Log.d(TAG,"NetSdk MultyPlay success!!!");
    }


    private RealPlayCallBack getRealPlayerCbf() {
        RealPlayCallBack cbf = new RealPlayCallBack() {
            public void fRealDataCallBack(int iRealHandle, int iDataType,
                                          byte[] pDataBuffer, int iDataSize) {
                CameraPlayer.this.processRealData(iDataType, pDataBuffer,
                        iDataSize, Player.STREAM_REALTIME);
            }
        };
        return cbf;
    }

    private ExceptionCallBack getExceptiongCbf() {
        ExceptionCallBack oExceptionCbf = new ExceptionCallBack() {
            public void fExceptionCallBack(int iType, int iUserID, int iHandle) {
                Log.e(TAG,"recv exception, type:" + iType);
            }
        };
        return oExceptionCbf;
    }

    public void processRealData(int iDataType, byte[] pDataBuffer, int iDataSize, int iStreamMode) {
            if (HCNetSDK.NET_DVR_SYSHEAD == iDataType) {
                if (m_iPort >= 0) {
                    return;
                }
                m_iPort = Player.getInstance().getPort();
                if (m_iPort == -1) {
                    Log.d(TAG,"getPort is failed with: "
                            + Player.getInstance().getLastError(m_iPort));
                    return;
                }
                Log.d(TAG,"getPort succ with: " + m_iPort);
                if (iDataSize > 0) {
                    if (!Player.getInstance().setStreamOpenMode(m_iPort,
                            iStreamMode)) // set stream mode
                    {
                        Log.d(TAG,"setStreamOpenMode failed");
                        return;
                    }
                    if (!Player.getInstance().openStream(m_iPort, pDataBuffer,
                            iDataSize, 2 * 1024 * 1024)) // open stream
                    {
                        Log.d(TAG,"openStream failed");
                        return;
                    }

                    if (!Player.getInstance().play(m_iPort,
                            m_osurfaceView.getHolder())) {
                        Log.d(TAG,"play failed");
                        return;
                    }
                    if (!Player.getInstance().playSound(m_iPort)) {
                        Log.d(TAG,"playSound failed with error code:"
                                + Player.getInstance().getLastError(m_iPort));
                        return;
                    }
                }
            } else {
                if (!Player.getInstance().inputData(m_iPort, pDataBuffer,
                        iDataSize)) {
                    for (int i = 0; i < 4000
                            && !m_bStopPlayback; i++) {
                        if (Player.getInstance().inputData(m_iPort,
                                pDataBuffer, iDataSize)) {
                            break;

                        }

                        if (i % 100 == 0) {
                            Log.d(TAG,"inputData failed with: "
                                    + Player.getInstance()
                                    .getLastError(m_iPort) + ", i:" + i);
                        }

                        try {
                            Thread.sleep(10);
                        } catch (InterruptedException e) {
                            Log.e(TAG,e.getMessage());
                        }
                    }
                }

            }
    }

    protected void stop() {
        if (m_iChanNum > 1)// preview more than a channel
        {
            stopMultiPreview();
        } else // preivew a channel
        {
            stopSinglePreview();
        }
        HCNetSDK.getInstance().NET_DVR_Logout_V30(m_iLogID);
    }

    private void stopMultiPreview() {
        int i = 0;
        for (i = 0; i < 4; i++) {
            playView[i].stopPreview();
        }
        m_iPlayID = -1;
    }

    private void stopSinglePreview() {
        if (m_iPlayID < 0) {
            Log.e(TAG, "m_iPlayID < 0");
            return;
        }

        // net sdk stop preview
        if (!HCNetSDK.getInstance().NET_DVR_StopRealPlay(m_iPlayID)) {
            Log.e(TAG, "StopRealPlay is failed!Err:"
                    + HCNetSDK.getInstance().NET_DVR_GetLastError());
            return;
        }

        m_iPlayID = -1;
        stopSinglePlayer();
    }

    private void stopSinglePlayer() {
        Player.getInstance().stopSound();
        // player stop play
        if (!Player.getInstance().stop(m_iPort)) {
            Log.e(TAG, "stop is failed!");
            return;
        }

        if (!Player.getInstance().closeStream(m_iPort)) {
            Log.e(TAG, "closeStream is failed!");
            return;
        }
        if (!Player.getInstance().freePort(m_iPort)) {
            Log.e(TAG, "freePort is failed!" + m_iPort);
            return;
        }
        m_iPort = -1;
    }
}
