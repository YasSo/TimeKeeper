//
//  y3DetailViewController.m
//  TimeKeeper
//
//  Created by Yasuo Miyoshi on 12/06/28.
//  Copyright (c) 2012 Kochi Univ. All rights reserved.
//

#import "y3DetailViewController.h"
#import "y3EditViewController.h"

@interface y3DetailViewController ()
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end

@implementation y3DetailViewController

@synthesize detailItem = _detailItem;
@synthesize editPopover = _editPopover;
@synthesize navItem = _navItem;
@synthesize timeProgressView = _timeProgressView;
@synthesize counterLabel = _counterLabel;
@synthesize singleTimeLabel = _singleTimeLabel;
@synthesize doubleTimeLabel = _doubleTimeLabel;
@synthesize tripleTimeLabel = _tripleTimeLabel;
@synthesize buttonSubView = _buttonSubView;
@synthesize editButton = _editButton;
@synthesize detailView = _detailView;
@synthesize masterPopoverController = _masterPopoverController;

SystemSoundID bellID, bell2ID, bell3ID;
NSDate *startDate;
NSTimer *timer, *clockTimer, *firstStartTimer, *vibrationTimer, *blinkTimer;
float singleSec, doubleSec, tripleSec, finishSec;
float elapsedSec;
bool start;
bool isStruckSingle, isStruckDouble, isStruckTriple;
bool doubleBell, tripleBell;
bool remainingTimeMode;
int remainingSound, remainingVibration, remainingBlink;

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        // Update the view.
        [self configureView];
    }
    if (_masterPopoverController != nil) {
        [_masterPopoverController dismissPopoverAnimated:YES];
    }
	if (timer) {
		[timer invalidate];
		timer = nil;
	}
	[self resetCounter];
}

- (void)locateTimeLabel
{
	float singleX, doubleX, tripleX;
	[_doubleTimeLabel setHidden:!doubleBell];
	if (doubleBell) [_tripleTimeLabel setHidden:!tripleBell];
	else [_tripleTimeLabel setHidden:YES];
	
	singleX = (singleSec / finishSec) * (_timeProgressView.frame.size.width - 10.0f) + _timeProgressView.frame.origin.x + 5.0f;
	doubleX = (doubleSec / finishSec) * (_timeProgressView.frame.size.width - 10.0f) + _timeProgressView.frame.origin.x + 5.0f;
	tripleX = (tripleSec / finishSec) * (_timeProgressView.frame.size.width - 10.0f) + _timeProgressView.frame.origin.x + 5.0f;
	_singleTimeLabel.center = CGPointMake(singleX, _singleTimeLabel.center.y);
	_doubleTimeLabel.center = CGPointMake(doubleX, _doubleTimeLabel.center.y);
	_tripleTimeLabel.center = CGPointMake(tripleX, _tripleTimeLabel.center.y);
}

- (void)configureView
{
	int maxMins, singleMins, doubleMins, tripleMins;
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		// iPhone の場合
		if (orientation == UIInterfaceOrientationPortrait) {
			// 縦向き (Portrait)
			[_buttonSubView setHidden:NO];
			_counterLabel.font = [UIFont fontWithName:@"GillSans-Bold" size:100.0f];
			_counterLabel.center = CGPointMake(_counterLabel.center.x, 140);
		}
		else {
			// 横向き (Landscape)
			[_buttonSubView setHidden:YES];
			_counterLabel.font = [UIFont fontWithName:@"GillSans-Bold" size:160.0f];
			_counterLabel.center = CGPointMake(_counterLabel.center.x, 130);
			[self displayClockInNavigationBar];
		}
	}
	else {
		// iPad の場合
		if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
			// 縦向き (Portrait)
			_counterLabel.font = [UIFont fontWithName:@"GillSans-Bold" size:260.0f];
			_counterLabel.center = CGPointMake(_counterLabel.center.x, 350);
		}
		else {
			// 横向き (Landscape)
			_counterLabel.font = [UIFont fontWithName:@"GillSans-Bold" size:360.0f];
			_counterLabel.center = CGPointMake(_counterLabel.center.x, 250);
		}
	}
    // Update the user interface for the detail item.
	if (_detailItem) {
		singleMins = [[_detailItem valueForKey:@"singleMinutes"] intValue];
		doubleMins = [[_detailItem valueForKey:@"doubleMinutes"] intValue];
		tripleMins = [[_detailItem valueForKey:@"tripleMinutes"] intValue];
		_singleTimeLabel.text = [NSString stringWithFormat:@"▲\n%02d:00\n\n\n", singleMins];
		_doubleTimeLabel.text = [NSString stringWithFormat:@"▲\n▲\n%02d:00\n\n", doubleMins];
		_tripleTimeLabel.text = [NSString stringWithFormat:@"▲\n▲\n▲\n%02d:00\n", tripleMins];
		doubleBell = [[_detailItem valueForKey:@"doubleBell"] boolValue];
		tripleBell = [[_detailItem valueForKey:@"tripleBell"] boolValue];
		maxMins = singleMins;
		if (doubleBell) {
			if (doubleMins > maxMins) maxMins = doubleMins;
			if (tripleBell) {
				if (tripleMins > maxMins) maxMins = tripleMins;
			}
		}
		finishSec = 60.0f * maxMins;
		singleSec = 60.0f * singleMins;
		doubleSec = 60.0f * doubleMins;
		tripleSec = 60.0f * tripleMins;
		[self locateTimeLabel];
	}
}

- (void)viewDidLoad
{
    CFURLRef soundURL;
    [super viewDidLoad];
	timer = nil;
	elapsedSec = 0.0f;
	remainingSound = 0;
    remainingTimeMode = NO;
	isStruckSingle = isStruckDouble = isStruckTriple = NO;
//	soundURL = CFBundleCopyResourceURL(CFBundleGetBundleWithIdentifier(CFSTR("com.apple.UIKit")), CFSTR ("Tock"),CFSTR ("aiff"),NULL);
	soundURL = (__bridge CFURLRef)[[NSBundle mainBundle] URLForResource: @"bell1" withExtension: @"aiff"];
	AudioServicesCreateSystemSoundID(soundURL, &bellID);
	soundURL = (__bridge CFURLRef)[[NSBundle mainBundle] URLForResource: @"bell2" withExtension: @"aiff"];
	AudioServicesCreateSystemSoundID(soundURL, &bell2ID);
	soundURL = (__bridge CFURLRef)[[NSBundle mainBundle] URLForResource: @"bell3" withExtension: @"aiff"];
	AudioServicesCreateSystemSoundID(soundURL, &bell3ID);
    
    _counterLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCounter:)];
    [_counterLabel addGestureRecognizer:tapGesture];
}

- (void)viewDidUnload
{
	if (timer) {
		[timer invalidate];
		timer = nil;
	}
	firstStartTimer = nil;
	AudioServicesDisposeSystemSoundID(bellID);
	AudioServicesDisposeSystemSoundID(bell2ID);
	AudioServicesDisposeSystemSoundID(bell3ID);
    [self setCounterLabel:nil];
	[self setSingleTimeLabel:nil];
	[self setDoubleTimeLabel:nil];
	[self setTripleTimeLabel:nil];
	[self setTimeProgressView:nil];
	[self setNavItem:nil];
	[self setButtonSubView:nil];
	[self setEditButton:nil];
    [self setDetailView:nil];
	[super viewDidUnload];
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (clockTimer) {
		[clockTimer invalidate];
		clockTimer = nil;
	}
	[self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
		if ([UIApplication sharedApplication].statusBarHidden) {
			[[UIApplication sharedApplication] setStatusBarHidden:NO];
			[self.navigationController setNavigationBarHidden:YES];
			[self.navigationController setNavigationBarHidden:NO];
		}
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
	}
	_navItem.title = @"";
	[self resetCounter];
}

- (void)viewDidAppear:(BOOL)animated
{
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		clockTimer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(onClockTimer:) userInfo:nil repeats:YES];
		if (orientation == UIInterfaceOrientationPortrait) {
			[[UIApplication sharedApplication] setStatusBarHidden:NO];
		}
		else {
			[[UIApplication sharedApplication] setStatusBarHidden:YES];
			[self.navigationController setNavigationBarHidden:YES];
			[self.navigationController setNavigationBarHidden:NO];
		}
	}
	[self configureView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
			[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
			[[UIApplication sharedApplication] setStatusBarHidden:NO];
		}
		else {
			[[UIApplication sharedApplication] setStatusBarHidden:YES];
		}
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self configureView];
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"TimeKeeper", @"TimeKeeper");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    _masterPopoverController = nil;
}

- (BOOL)splitViewController: (UISplitViewController*)splitController shouldHideViewController:(UIViewController *)viewController inOrientation:(UIInterfaceOrientation)orientation __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0);
{
	return YES;
}

#pragma mark - TimeKeeper

- (IBAction)tapCounter:(id)sender {
    remainingTimeMode = !remainingTimeMode;
    [self updateCounterLabel];
}

- (IBAction)tap:(id)sender {
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
		if (orientation != UIInterfaceOrientationPortrait) {
			_buttonSubView.hidden = !_buttonSubView.hidden;
		}
	}
}

- (void)onTimerFirstStart:(NSTimer *)theTimer
{
	[self edit];
}

- (void)firstStart
{
	NSLog(@"firstStart");
	firstStartTimer = [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(onTimerFirstStart:) userInfo:nil repeats:NO];
}

- (void)edit
{
	[self performSegueWithIdentifier:@"edit" sender:self];
}

- (IBAction)pushEdit:(id)sender
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		_navItem.title = NSLocalizedString(@"Done", @"Done");
		[self performSegueWithIdentifier:@"edit" sender:self];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	y3EditViewController *editViewController = (y3EditViewController *)[segue destinationViewController];
	[editViewController setReferenceViewController:self];
	[editViewController setDetailItem:_detailItem];
}

- (IBAction)pushStart:(id)sender
{
	if (!timer) {
		startDate = [NSDate date];
		timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
			// backボタンを押せないダミーに変える
			UIButton* backButton = [UIButton buttonWithType:101];
			[backButton addTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
			[backButton setTitle:NSLocalizedString(@"TimeKeeper", @"TimeKeeper") forState:UIControlStateNormal];
			UIBarButtonItem* backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
			[_navItem setLeftBarButtonItem:backItem];
			[_navItem.leftBarButtonItem setEnabled:NO];
		}
		else [self.navigationItem.leftBarButtonItem setEnabled:NO];
		[_editButton setEnabled:NO];
		[[UIApplication sharedApplication] setIdleTimerDisabled:YES];	// スリープさせない
	}
	else {
		elapsedSec -= [startDate timeIntervalSinceNow];
		[timer invalidate];
		timer = nil;
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
			[_navItem setLeftBarButtonItem:nil];	// ダミーを消すとbackボタンが復活
		else [self.navigationItem.leftBarButtonItem setEnabled:YES];
		[_editButton setEnabled:YES];
		[[UIApplication sharedApplication] setIdleTimerDisabled:NO];	// スリープ有効に戻す
	}
	if (_buttonSubView.hidden) [_buttonSubView setHidden:NO];
}

- (void)resetCounter
{
	isStruckSingle = isStruckDouble = isStruckTriple = NO;
	elapsedSec = 0.0f;
	startDate = [NSDate date];
	_timeProgressView.progress = 0.0f;
	_counterLabel.textColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
	_timeProgressView.progressTintColor = [UIColor colorWithRed:1.0f green:191.0f/255.0f blue:83.0f/255.0f alpha:1.0f];
    [self updateCounterLabel];
}

- (IBAction)pushReset:(id)sender
{
	[self resetCounter];
	if (_buttonSubView.hidden) [_buttonSubView setHidden:NO];
}

static void endSound(SystemSoundID ssID, void *myself)
{
	y3DetailViewController *theClass = (__bridge y3DetailViewController *)myself;
	CFRelease(myself);
	[theClass playSound:0];
}

- (void)playSound:(int)count
{
	remainingSound += count;
	if (remainingSound <= 0) return;
	remainingSound--;
	AudioServicesAddSystemSoundCompletion(bellID, NULL, NULL, endSound, (__bridge_retained void *)self);
	AudioServicesPlaySystemSound(bellID);
//	NSLog(@"RING!!");
}

- (void)playVibration:(int)count
{
    remainingVibration += count;
    [self onVibrationTimer:nil];
    if (!vibrationTimer)
        vibrationTimer = [NSTimer scheduledTimerWithTimeInterval:0.6f target:self selector:@selector(onVibrationTimer:) userInfo:nil repeats:YES];
}

- (void)onVibrationTimer:(NSTimer *)theTimer
{
    if (remainingVibration <= 0) {
        if (vibrationTimer) [vibrationTimer invalidate];
        vibrationTimer = nil;
        return;
    }
	AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
//    NSLog(@"Vibrate!!");
    remainingVibration--;
}

- (void)blink:(int)count
{
    remainingBlink += count * 6;
    [self onBlinkTimer:nil];
    if (!blinkTimer)
        blinkTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(onBlinkTimer:) userInfo:nil repeats:YES];
}

- (void)onBlinkTimer:(NSTimer *)theTimer
{
    UIColor *color;
    if (remainingBlink % 2 == 1) {
        color = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
        [_buttonSubView setAlpha:0.0f];
        [_timeProgressView setAlpha:0.0f];
    }
    else {
        color = [UIColor colorWithRed:0.29194f green:0.263998f blue:0.239367f alpha:1.0f];
        [_buttonSubView setAlpha:1.0f];
        [_timeProgressView setAlpha:1.0f];
    }
    [_detailView setBackgroundColor:color];
    if (remainingBlink <= 0) {
        if (blinkTimer) [blinkTimer invalidate];
        blinkTimer = nil;
        return;
    }
//    NSLog(@"Blink!!");
    remainingBlink--;
}

- (void)ringBell:(int)count
{
    bool vibration, flashlight;
    if (count == 2)
        AudioServicesPlaySystemSound(bell2ID);
    else if (count == 3)
        AudioServicesPlaySystemSound(bell3ID);
    else if (count == 1)
        AudioServicesPlaySystemSound(bellID);
    else [self playSound:count];
	if (_detailItem) {
		vibration = [[_detailItem valueForKey:@"vibration"] boolValue];
		flashlight = [[_detailItem valueForKey:@"flashlight"] boolValue];
        if (vibration) [self playVibration:count+2];
        if (flashlight) [self blink:count];
    }
}

- (IBAction)pushBell:(id)sender
{
	[self ringBell:1];
	if (_buttonSubView.hidden) [_buttonSubView setHidden:NO];
}

- (void)onTimer:(NSTimer *)theTimer
{
    NSTimeInterval t = -[startDate timeIntervalSinceNow] + elapsedSec;
	_timeProgressView.progress = t / finishSec;
	if (t > finishSec) {
		_timeProgressView.progressTintColor = [UIColor colorWithRed:1.0f green:0.3f blue:0.0f alpha:1.0f];
		_counterLabel.textColor = [UIColor colorWithRed:1.0f green:0.8f blue:0.75f alpha:1.0f];
	}
	if (!isStruckSingle && t >= singleSec) {
		isStruckSingle = YES;
		[self ringBell:1];
	}
	if (!isStruckDouble && t >= doubleSec && doubleBell) {
		isStruckDouble = YES;
		[self ringBell:2];
	}
	if (!isStruckTriple && t >= tripleSec && tripleBell) {
		isStruckTriple = YES;
		[self ringBell:3];
	}
    [self updateCounterLabel];
}

- (void)updateCounterLabel
{
    NSTimeInterval tc = elapsedSec;
    if (timer) tc -= [startDate timeIntervalSinceNow];
    int t = (int)tc;
    if (remainingTimeMode) t = finishSec - tc;
    int minute = abs((int) t / 60);
    int second = abs((int) t % 60);
    if (tc > finishSec && remainingTimeMode)
        _counterLabel.text = [NSString stringWithFormat:@"-%02d:%02d", minute, second];
    else
        _counterLabel.text = [NSString stringWithFormat:@"%02d:%02d", minute, second];
}

- (void)displayClockInNavigationBar {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setLocale:[NSLocale systemLocale]];
	[formatter setTimeZone:[NSTimeZone systemTimeZone]];
	[formatter setDateFormat:@"HH:mm:ss"];
	self.navigationItem.title = [formatter stringFromDate:[NSDate date]];
}

- (void)onClockTimer:(NSTimer *)theTimer
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	if (orientation == UIInterfaceOrientationPortrait) {
        self.navigationItem.title = @"";
    }
    else {
        [self displayClockInNavigationBar];
    }
}

@end
