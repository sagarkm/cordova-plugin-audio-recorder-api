#import "AudioRecorderAPI.h"
#import <Cordova/CDV.h>
#import <AudioToolbox/AudioServices.h>
#import <AudioToolbox/AudioToolbox.h>

@implementation AudioRecorderAPI

#define RECORDINGS_FOLDER [NSHomeDirectory() stringByAppendingPathComponent:@"Library/NoCloud"]

- (void)record:(CDVInvokedUrlCommand*)command {
  _command = command;
  duration = [_command.arguments objectAtIndex:0];

  [self.commandDelegate runInBackground:^{

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];

    NSError *err;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
    if (err)
    {
      NSLog(@"%@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    }
    err = nil;
    [audioSession setActive:YES error:&err];
    if (err)
    {
      NSLog(@"%@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
    }

    NSMutableDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    [recordSettings setObject:[NSNumber numberWithInteger: kAudioFormatMPEG4AAC] forKey: AVFormatIDKey];
    [recordSettings setObject:[NSNumber numberWithFloat:44100.0] forKey: AVSampleRateKey];
    [recordSettings setObject:[NSNumber numberWithInteger:1] forKey:AVNumberOfChannelsKey];
    //[recordSettings setObject:[NSNumber numberWithInt:12000] forKey:AVEncoderBitRateKey];
    //[recordSettings setObject:[NSNumber numberWithInt:8] forKey:AVLinearPCMBitDepthKey];
    //[recordSettings setObject:[NSNumber numberWithInt: AVAudioQualityLow] forKey: AVEncoderAudioQualityKey];

//    // Create a new dated file
//    NSString *uuid = [[NSUUID UUID] UUIDString];
//    recorderFilePath = [NSString stringWithFormat:@"%@/%@.m4a", RECORDINGS_FOLDER, uuid];
//    NSLog(@"recording file path: %@", recorderFilePath);
//      
//    NSURL *url = [NSURL fileURLWithPath:recorderFilePath];
    err = nil;

    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths lastObject];

    // Create a new dated file
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *myPath = [docsDir stringByAppendingPathComponent:@"emscharts"];
      
    if (![[NSFileManager defaultManager] fileExistsAtPath:myPath]) {
      [[NSFileManager defaultManager] createDirectoryAtPath:myPath withIntermediateDirectories:NO
                                                 attributes:nil error:NULL];
    }

    recorderFilePath = [myPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.m4a", uuid]];

    NSURL *soundFileURL = [NSURL fileURLWithPath:recorderFilePath];
    NSLog(@"recording filepath: %@", recorderFilePath);
      
    recorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings:recordSettings error:&err];
    if(!recorder){
      NSLog(@"recorder: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
      return;
    }

    [recorder setDelegate:self];

    if (![recorder prepareToRecord]) {
      NSLog(@"prepareToRecord failed");
      return;
    }

    if (![recorder recordForDuration:(NSTimeInterval)[duration intValue]]) {
      NSLog(@"recordForDuration failed");
      return;
    }

  }];
}

- (void)stop:(CDVInvokedUrlCommand*)command {
  _command = command;
  NSLog(@"stopRecording");
  if (recorder.recording) {
    [recorder stop];
  }
  NSLog(@"stopped");
}

- (void)playback:(CDVInvokedUrlCommand*)command {
  _command = command;
  [self.commandDelegate runInBackground:^{
    NSLog(@"recording playback");
      if([_command.arguments count] > 0) {
          
          AVAudioSession *audioSession = [AVAudioSession sharedInstance];
          
          NSError *err;
          [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord error:&err];
          if (err)
          {
              NSLog(@"%@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
          }
          err = nil;
          [audioSession setActive:YES error:&err];
          if (err)
          {
              NSLog(@"%@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
          }
          
            NSString *base64String = [_command.arguments objectAtIndex:0];
          
            NSData *nsdataFromBase64String = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
          
            NSError *error;
            player = [[AVAudioPlayer alloc] initWithData:nsdataFromBase64String error:&error];
            player.numberOfLoops = 0;
            player.delegate = self;
            [player prepareToPlay];
            [player play];
            if (error) {
              NSLog(@"%@ %ld %@", [error domain], (long)[error code], [[error userInfo] description]);
            }
          
      } else {
      
            NSURL *url = [NSURL fileURLWithPath:recorderFilePath];
            NSError *err;
            player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&err];
            player.numberOfLoops = 0;
            player.delegate = self;
            [player prepareToPlay];
            [player play];
            if (err) {
              NSLog(@"%@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
            }
      }
      NSLog(@"playing");
  }];
}

- (void)playbackstop:(CDVInvokedUrlCommand*)command {
    _command = command;
    [self.commandDelegate runInBackground:^{
        NSLog(@"pause playback");
        if (player.playing) {
            [player stop];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"playbackStop"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
        }
    }];
}

- (void)remove:(CDVInvokedUrlCommand*)command
{
    _command = command;
    NSString *removeFilePath = [_command.arguments objectAtIndex:0];
    NSLog(@"delete - > %@", removeFilePath);
}   

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
  NSLog(@"audioPlayerDidFinishPlaying");
  pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"playbackComplete"];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
  NSURL *url = [NSURL fileURLWithPath: recorderFilePath];
  NSError *err = nil;
  NSData *audioData = [NSData dataWithContentsOfFile:[url path] options: 0 error:&err];
  if(!audioData) {
    NSLog(@"audio data: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
  } else {
    NSLog(@"recording saved: %@", recorderFilePath);
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success = [fileManager removeItemAtPath:recorderFilePath error:&error];
    if (success) {
      NSLog(@"File deleted -:%@ ", recorderFilePath);
    } else {
      NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
    }
    NSString *base64Encoded = [audioData base64EncodedStringWithOptions:0];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:base64Encoded];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:_command.callbackId];
  }
}

@end
