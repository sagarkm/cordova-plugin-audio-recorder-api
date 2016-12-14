cordova.define("cordova-plugin-audio-recorder-api.AudioRecorderAPI", function(require, exports, module) {
function AudioRecorderAPI() {
}

AudioRecorderAPI.prototype.record = function (successCallback, errorCallback, duration) {
  cordova.exec(successCallback, errorCallback, "AudioRecorderAPI", "record", duration ? [duration] : []);
};

AudioRecorderAPI.prototype.stop = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "AudioRecorderAPI", "stop", []);
};

AudioRecorderAPI.prototype.playback = function (successCallback, errorCallback, fileData) {
  cordova.exec(successCallback, errorCallback, "AudioRecorderAPI", "playback", fileData ? [fileData] : []);
};

AudioRecorderAPI.prototype.playbackstop = function (successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "AudioRecorderAPI", "playbackstop", []);
};

AudioRecorderAPI.install = function () {
if (!window.plugins) {
  window.plugins = {};
}
window.plugins.audioRecorderAPI = new AudioRecorderAPI();
  return window.plugins.audioRecorderAPI;
};

cordova.addConstructor(AudioRecorderAPI.install);

});
