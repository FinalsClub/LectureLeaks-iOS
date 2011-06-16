//
//  LecturePlayerViewController.m
//  LectureLeaks
//
//  Created by Christopher Ballinger on 6/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "LecturePlayerViewController.h"


@implementation LecturePlayerViewController
@synthesize titleLabel;
@synthesize classLabel;
@synthesize schoolLabel;
@synthesize durationLabel;
@synthesize currentTimeLabel;
@synthesize dateLabel;
@synthesize submitLabel;
@synthesize lecture;
@synthesize playerUpdateTimer;
@synthesize playerSlider;
@synthesize playButton;
@synthesize stopButton;
@synthesize submitButton;
@synthesize player;

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
    
    NSURL *url; 
    if(lecture.isRemoteFile)
    url = [NSURL URLWithString:@"http://thenewfreedom.net/zro/11-z-ro-cant_leave_drank_alone_ft_lil_o.mp3"];
    else
        url = lecture.url;
    
    player = [[AVPlayer alloc] initWithURL:url];
    
    
    if(lecture.isRemoteFile)
        submitButton.enabled = NO;
    else
        submitButton.enabled = YES;
    
    isPlaying = NO;
    
    
    playerUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                                        selector:@selector(updateElapsedTime:) userInfo:nil repeats:YES] retain];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[player currentItem]];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"gradient_background.png"]];
    self.title = @"Lecture";
    
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self stopPressed:nil];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [player pause];
    [playerUpdateTimer invalidate];
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


- (IBAction)submitPressed:(id)sender {
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
@end
