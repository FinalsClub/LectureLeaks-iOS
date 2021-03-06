//
//  LecturePlayerViewController.m
//  LectureLeaks
//
//  Created by Christopher Ballinger on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LecturePlayerViewController.h"
#import "ASIFormDataRequest.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation LecturePlayerViewController
@synthesize titleLabel;
@synthesize classLabel;
@synthesize schoolLabel;
@synthesize durationLabel;
@synthesize currentTimeLabel;
@synthesize dateLabel;
@synthesize submitLabel;
@synthesize submitProgressLabel;
@synthesize progressView;
@synthesize lecture;
@synthesize playerUpdateTimer;
@synthesize playerSlider;
@synthesize playButton;
@synthesize stopButton;
@synthesize submitButton;
@synthesize player;
@synthesize permissionSwitch;
@synthesize permissionLabel;
@synthesize emailLabel;
@synthesize emailTextField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [titleLabel release];
    [classLabel release];
    [schoolLabel release];
    [dateLabel release];
    [player release];
    [lecture release];
    [durationLabel release];
    [currentTimeLabel release];
    [playerUpdateTimer release];
    [playerSlider release];
    [submitLabel release];
    [playButton release];
    [stopButton release];
    [submitButton release];
    [progressView release];
    [submitProgressLabel release];
    [permissionSwitch release];
    [permissionLabel release];
    [emailLabel release];
    [emailTextField release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    titleLabel.text = lecture.name;
    classLabel.text = lecture.course;
    schoolLabel.text = lecture.school;
    dateLabel.text = [lecture.date description];
    if(lecture.submitDate)
        submitLabel.text = [lecture.submitDate description];
    
    NSURL *url = lecture.url;
    
    AVAudioSession *session = [AVAudioSession sharedInstance]; [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    player = [[AVPlayer alloc] initWithURL:url];
    
    
    if(lecture.isRemoteFile)
        submitButton.enabled = NO;
    else
    {
        submitButton.enabled = YES;
        permissionLabel.hidden = NO;
        permissionSwitch.hidden = NO;
        emailLabel.hidden = NO;
        emailTextField.hidden = NO;
        
        if(lecture.professor)
            emailTextField.text = lecture.professor;
    }
    
    isPlaying = NO;
    
    
    playerUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                                        selector:@selector(updateElapsedTime:) userInfo:nil repeats:YES] retain];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[player currentItem]];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradient_background.png"]];
    self.title = @"Lecture";
    
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self stopPressed:nil];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [player pause];
    [playerUpdateTimer invalidate];
    
    if(!lecture.isRemoteFile)
    {
        [lecture saveMetadata];
    }
}

- (void)viewDidUnload
{
    [self setTitleLabel:nil];
    [self setClassLabel:nil];
    [self setSchoolLabel:nil];
    [self setDateLabel:nil];
    [self setDurationLabel:nil];
    [self setCurrentTimeLabel:nil];
    [self setPlayerSlider:nil];
    [self setSubmitLabel:nil];
    [self setPlayButton:nil];
    [self setStopButton:nil];
    [self setSubmitButton:nil];
    [self setProgressView:nil];
    [self setSubmitProgressLabel:nil];
    [self setPermissionSwitch:nil];
    [self setPermissionLabel:nil];
    [self setEmailLabel:nil];
    [self setEmailTextField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// Update the call timer once a second.
- (void) updateElapsedTime:(NSTimer *) timer
{
    if(player.currentItem.status == AVPlayerItemStatusReadyToPlay)
    {
        
        int currentTime;
        
        
        currentTime = player.currentTime.value / player.currentTime.timescale;
        CMTime itemDuration = player.currentItem.asset.duration;
        duration = itemDuration.value / itemDuration.timescale;
        
        
        [self updateLabel:currentTimeLabel withTime:currentTime];
        [self updateLabel:durationLabel withTime:duration];
        
        if(duration != 0)
        {
            self.playerSlider.value = currentTime / ((float)duration);
        }
        if(!isPlaying)
        {
            stopButton.enabled = NO;
            playButton.title = @"Play";
            playButton.enabled = YES;
        }
    }
}

-(void) updateLabel:(UILabel*)label withTime:(NSTimeInterval)time
{
    int hour, minute, second;
	hour = time / 3600;
	minute = (time - hour * 3600) / 60;
	second = (time - hour * 3600 - minute * 60);
	label.text = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];
}

- (IBAction)seek:(id)sender 
{
    
    float currentTime = self.playerSlider.value * duration;
    [player seekToTime:CMTimeMakeWithSeconds(currentTime, 1)];
    
    [self updateElapsedTime:nil];
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1)
    {
        submitProgressLabel.text = @"Submitting...";
        submitProgressLabel.textColor = [UIColor whiteColor];
        
        lecture.professor = emailTextField.text;
        [lecture saveMetadata];
        
        [lecture submitRecordingWithDelegate:self];
    }
}

- (IBAction)submitPressed:(id)sender 
{
    if(permissionSwitch.on)
    {
        // stolen from http://cocoawithlove.com/2009/06/verifying-that-string-is-email-address.html
        NSString *emailRegEx =
        @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
        @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
        @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
        @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
        @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
        @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
        @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
        
        NSPredicate *regExPredicate =
        [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
        BOOL myStringMatchesRegEx = [regExPredicate evaluateWithObject:emailTextField.text];
        
        if(myStringMatchesRegEx || [emailTextField.text isEqualToString:@""])
        {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Submit to LectureLeaks" message:@"Would you like to submit your recording to www.lectureleaks.com?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:nil] autorelease];
            [alert addButtonWithTitle:@"Yes"];
            [alert show];
        }
        else
        {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Invalid Email" message:@"Please enter a valid email address and try again." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
            [alert show];
        }
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Request Permission" message:@"Please request permission from your instructor before submitting this recording." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK",nil];
        [alert show];
        [alert release];
    }
}

- (IBAction)playPressed:(id)sender 
{
    if(!isPlaying)
    {
        [player play];
        playButton.title = @"Pause";
        stopButton.enabled = YES;
        isPlaying = YES;
    }
    else
    {
        [player pause];
        playButton.title = @"Play";
        isPlaying = NO;
    }
}

- (IBAction)stopPressed:(id)sender 
{
    
    [player pause];
    [player seekToTime:CMTimeMakeWithSeconds(0, 1)];
    
    [self updateElapsedTime:nil];
    stopButton.enabled = NO;
    playButton.title = @"Play";
    isPlaying = NO;
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Complete" message:@"The recording was uploaded successfully to www.lectureleaks.com" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
    [alert release];
    
    // Set TRUE if file was sent properly
    lecture.submitDate = [NSDate date];
    [lecture saveMetadata];
    
    submitProgressLabel.text = @"Submission successful!";
    submitProgressLabel.textColor = [UIColor greenColor];
    submitLabel.text = [lecture.submitDate description];
    progressView.hidden = TRUE;
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Upload Error" message:@"Upload failed, please check your internet connection and try again." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
    [alert release];
    
    submitProgressLabel.text = @"Submission failed!";
    submitProgressLabel.textColor = [UIColor redColor];
    progressView.hidden = TRUE;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
