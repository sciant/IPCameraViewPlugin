package com.sciant.ipcamplugin;

import org.apache.cordova.CallbackContext;

public class PluginResult {

    public final static String LOGIN_FAILED = "LOGIN_FAILED";
    public final static String INVALID_PORT = "INVALID_PORT";
    public final static String INVALID_ACTION = "INVALID_ACTION";
    public final static String UNEXPECTED_ERROR = "UNEXPECTED_ERROR";

    private static CallbackContext callbackContext;

    private PluginResult() {}

    public static void setCallbackContext(CallbackContext callbackContext) {
        PluginResult.callbackContext = callbackContext;
    }

    public static void success() {
        callbackContext.success();
    }

    public static void error(String errorMsg) {
        callbackContext.error(errorMsg);
    }
}
