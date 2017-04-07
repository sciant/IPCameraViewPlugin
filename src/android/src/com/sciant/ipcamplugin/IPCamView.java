package com.sciant.ipcamplugin;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

public class IPCamView extends CordovaPlugin {

    private final String TAG = "SCNT_CAM_PLAY";

    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        try {
            if (action.equals("play")) {
                String host = args.getString(0);
                String port = args.getString(1);
                String user = args.getString(2);
                String pass = args.getString(3);
                try {
                    Integer.valueOf(port);
                } catch (NumberFormatException nfe) {
                    callbackContext.error(PluginResult.INVALID_PORT);
                    return true;
                }
                Context context = cordova.getActivity().getApplicationContext();
                String className = "com.sciant.ipcamplugin.CameraPlayer";
                Intent intent = new Intent(context,Class.forName(className));
                intent.putExtra("host", host);
                intent.putExtra("port", port);
                intent.putExtra("user", user);
                intent.putExtra("pass", pass);
                PluginResult.setCallbackContext(callbackContext);
                cordova.startActivityForResult(this,intent,1);
                return true;
            }
            callbackContext.error(PluginResult.INVALID_ACTION);
            return false;
        } catch(Exception e) {
            Log.e(TAG, e.getMessage());
            callbackContext.error(PluginResult.UNEXPECTED_ERROR);
            return false;
        }
    }
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        Log.e(TAG, "Activity Result: " + resultCode); //-1 is RESULT_OK
        if (resultCode== Activity.RESULT_OK) {
            Log.e(TAG, "All good!");
        }
    }
}