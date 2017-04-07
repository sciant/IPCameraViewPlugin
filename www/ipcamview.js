 var exec = require('cordova/exec'),
     cordova = require('cordova');

 function IPCamView() {

 }

 IPCamView.prototype.play = function(host, port, user, pass, successCallback, errorCallback) {
     exec(successCallback, errorCallback, "IPCamView", "play", [host, port, user, pass]);
 };

 module.exports = new IPCamView();