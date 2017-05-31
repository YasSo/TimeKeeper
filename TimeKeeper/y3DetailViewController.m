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

SystemSoundID bellID, bell2ID, bell3ID;
NSDate *startDate;
NSTimer *timer, *clockTimer, *firstStartTimer, *vibrationTimer, *blinkTimer;
float singleSec, doubleSec, tripleSec, finishSec, elapsedSec;
bool start, isStruckSingle, isStruckDouble, isStruckTriple, doubleBell, tripleBell, remainingTimeMode;
int remainingSound, remainingVibration, remainingBlink, displayTimeMode;

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

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
    _doubleTimeLabel.hidden = !doubleBell;
	if (doubleBell) _tripleTimeLabel.hidden = !tripleBell;
    else _tripleTimeLabel.hidden = YES;
	
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
    NSString *fontName = @"GillSans-Bold";
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
    float y;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		// iPhone の場合
		if (orientation == UIInterfaceOrientationPortrait) {
			// 縦向き (Portrait)
            _operationBar.hidden = NO;
			_counterLabel.font = [UIFont fontWithName:fontName size:100.0f];
            y = applicationFrame.size.height / 2.6;
			_counterLabel.center = CGPointMake(_counterLabel.center.x, y);
            _timeProgressView.center = CGPointMake(_timeProgressView.center.x, y+50.0f);
		}
		else {
			// 横向き (Landscape)
//			_operationBar.hidden = YES;
			_counterLabel.font = [UIFont fontWithName:fontName size:160.0f];
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) y = applicationFrame.size.height / 2.8;
            else y = applicationFrame.size.width / 2.8;
			_counterLabel.center = CGPointMake(_counterLabel.center.x, y);
            _timeProgressView.center = CGPointMake(_timeProgressView.center.x, y+80.0f);
			[self displayClockInNavigationBar];
		}
        _singleTimeLabel.center = CGPointMake(_singleTimeLabel.center.x, _timeProgressView.center.y+_singleTimeLabel.frame.size.height/2.0f);
        _doubleTimeLabel.center = CGPointMake(_doubleTimeLabel.center.x, _timeProgressView.center.y+_doubleTimeLabel.frame.size.height/2.0f);
        _tripleTimeLabel.center = CGPointMake(_tripleTimeLabel.center.x, _timeProgressView.center.y+_tripleTimeLabel.frame.size.height/2.0f);
	}
	else {
		// iPad の場合
		if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
			// 縦向き (Portrait)
//            _operationBar.hidden = NO;
//			_counterLabel.font = [UIFont fontWithName:fontName size:260.0f];
//			_counterLabel.center = CGPointMake(_counterLabel.center.x, 350);
		}
		else {
			// 横向き (Landscape)
//			_counterLabel.font = [UIFont fontWithName:fontName size:360.0f];
//			_counterLabel.center = CGPointMake(_counterLabel.center.x, 250);
		}
	}
    // Update the user interface for the detail item.
	if (_detailItem) {
		singleMins = [[_detailItem valueForKey:@"singleMinutes"] intValue];
		doubleMins = [[_detailItem valueForKey:@"doubleMinutes"] intValue];
		tripleMins = [[_detailItem valueForKey:@"tripleMinutes"] intValue];
		_singleTimeLabel.text = [NSString stringWithFormat:@"▲\n%02d:00", singleMins];
		_doubleTimeLabel.text = [NSString stringWithFormat:@"▲\n▲\n%02d:00", doubleMins];
		_tripleTimeLabel.text = [NSString stringWithFormat:@"▲\n▲\n▲\n%02d:00", tripleMins];
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
    displayTimeMode = 15;
    isStruckSingle = isStruckDouble = isStruckTriple = NO;
    
    //	soundURL = CFBundleCopyResourceURL(CFBundleGetBundleWithIdentifier(CFSTR("com.apple.UIKit")), CFSTR ("Tock"),CFSTR ("aiff"),NULL);
	soundURL = (__bridge CFURLRef)[[NSBundle mainBundle] URLForResource: @"bell1" withExtension: @"aiff"];
	AudioServicesCreateSystemSoundID(soundURL, &bellID);
	soundURL = (__bridge CFURLRef)[[NSBundle mainBundle] URLForResource: @"bell2" withExtension: @"aiff"];
	AudioServicesCreateSystemSoundID(soundURL, &bell2ID);
	soundURL = (__bridge CFURLRef)[[NSBundle mainBundle] URLForResource: @"bell3" withExtension: @"aiff"];
	AudioServicesCreateSystemSoundID(soundURL, &bell3ID);
    
    _counterLabel.userInteractionEnabled = YES;
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
    
    self.counterLabel = nil;
    self.singleTimeLabel = nil;
    self.doubleTimeLabel = nil;
    self.tripleTimeLabel = nil;
    self.timeProgressView = nil;
    self.navItem = nil;
    self.editButton = nil;
    self.detailView = nil;
    
	[super viewDidUnload];
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (clockTimer) {
		[clockTimer invalidate];
		clockTimer = nil;
	}
//    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
//        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
		if ([UIApplication sharedApplication].statusBarHidden) {
            [UIApplication sharedApplication].statusBarHidden = NO;
            self.navigationController.navigationBarHidden = YES;
            self.navigationController.navigationBarHidden = NO;
		}
	}
}

- (void)viewWillAppear:(BOOL)animated
{
//    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
	}
	_navItem.title = @"";
	[self resetCounter];
}

- (void)viewDidAppear:(BOOL)animated
{
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    clockTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(onClockTimer:) userInfo:nil repeats:YES];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		if (orientation == UIInterfaceOrientationPortrait) {
            [UIApplication sharedApplication].statusBarHidden = NO;
		}
		else {
            [UIApplication sharedApplication].statusBarHidden = YES;
            self.navigationController.navigationBarHidden = YES;
            self.navigationController.navigationBarHidden = NO;
		}
	}
//    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
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
//			[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
            [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
//			[[UIApplication sharedApplication] setStatusBarHidden:NO];
            [UIApplication sharedApplication].statusBarHidden = NO;
		}
		else {
//			[[UIApplication sharedApplication] setStatusBarHidden:YES];
            [UIApplication sharedApplication].statusBarHidden = YES;
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
//    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.navigationItem.leftBarButtonItem = barButtonItem;
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
//    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.navigationItem.leftBarButtonItem = nil;
    _masterPopoverController = nil;
}

- (BOOL)splitViewController: (UISplitViewController*)splitController shouldHideViewController:(UIViewController *)viewController inOrientation:(UIInterfaceOrientation)orientation __OSX_AVAILABLE_STARTING(__MAC_NA,__IPHONE_5_0);
{
	return YES;
}

#pragma mark - TimeKeeper

//- (IBAction)tapCounter:(id)sender {
//    remainingTimeMode = !remainingTimeMode;
//    displayTimeMode = 15;
//    [self updateCounterLabel];
//    [self updateTimeMode];
//}

- (IBAction)tap:(UITapGestureRecognizer *)sender {
    if (sender.view == self.view) {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
		if (orientation != UIInterfaceOrientationPortrait && orientation != UIInterfaceOrientationPortraitUpsideDown) {
			_operationBar.hidden = !_operationBar.hidden;
		}
	}
    else if (sender.view == _counterLabel) {
        remainingTimeMode = !remainingTimeMode;
        displayTimeMode = 15;
        [self updateCounterLabel];
        [self updateTimeMode];
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
	editViewController.referenceViewController = self;
	editViewController.detailItem = _detailItem;
}

- (void)startCounter
{
    if (!timer) {
        startDate = [NSDate date];
        timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            // backボタンを押せないダミーに変える
            UIButton* backButton = [UIButton buttonWithType:101];
//            [backButton addTarget:self action:nil forControlEvents:UIControlEventTouchUpInside];
            [backButton setTitle:NSLocalizedString(@"TimeKeeper", @"TimeKeeper") forState:UIControlStateNormal];
            UIBarButtonItem* backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
            _navItem.leftBarButtonItem = backItem;
            _navItem.leftBarButtonItem.enabled = NO;
        }
        else self.navigationItem.leftBarButtonItem.enabled = NO;
        _editButton.enabled = NO;
        [UIApplication sharedApplication].idleTimerDisabled = YES;	// スリープさせない
        UIBarButtonItem *button;
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pushStart:)];
        NSMutableArray *array;
        array = [_operationBar.items mutableCopy];
        [array removeObjectAtIndex:3];
        [array insertObject:button atIndex:3];
        _operationBar.items = array;
        _operationBar.alpha = 0.5f;
    }
    else {
        elapsedSec -= [startDate timeIntervalSinceNow];
        [timer invalidate];
        timer = nil;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            _navItem.leftBarButtonItem = nil;	// ダミーを消すとbackボタンが復活
        else self.navigationItem.leftBarButtonItem.enabled = YES;
        _editButton.enabled = YES;
        [UIApplication sharedApplication].idleTimerDisabled = NO;	// スリープ有効に戻す
        UIBarButtonItem *button;
        button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(pushStart:)];
        NSMutableArray *array;
        array = [_operationBar.items mutableCopy];
        [array removeObjectAtIndex:3];
        [array insertObject:button atIndex:3];
        _operationBar.items = array;
        _operationBar.alpha = 1.0f;
    }
}

- (IBAction)pushStart:(id)sender
{
    [self startCounter];
	_operationBar.hidden = NO;
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
	if (_operationBar.hidden) _operationBar.hidden = NO;
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
        _operationBar.alpha = 0.0f;
        _timeProgressView.alpha = 0.0f;
    }
    else {
        color = [UIColor colorWithRed:0.121587f green:0.129412f blue:0.141118f alpha:1.0f];
        _operationBar.alpha = 1.0f;
        _timeProgressView.alpha = 1.0f;
    }
    _detailView.backgroundColor = color;
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
    bool vibrate, flashScreen;
    if (count == 2)
        AudioServicesPlaySystemSound(bell2ID);
    else if (count == 3)
        AudioServicesPlaySystemSound(bell3ID);
    else if (count == 1)
        AudioServicesPlaySystemSound(bellID);
    else [self playSound:count];
	if (_detailItem) {
		vibrate = [[_detailItem valueForKey:@"vibrate"] boolValue];
		flashScreen = [[_detailItem valueForKey:@"flashScreen"] boolValue];
        if (vibrate) [self playVibration:count];
        if (flashScreen) [self blink:count];
    }
}

- (IBAction)pushBell:(id)sender
{
	[self ringBell:1];
	if (_operationBar.hidden) _operationBar.hidden = NO;
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
	if (!isStruckTriple && t >= tripleSec && doubleBell && tripleBell) {
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

- (void)updateTimeMode
{
    if (remainingTimeMode)
        self.navigationItem.title = NSLocalizedString(@"RemainingTime", @"Remaining Time");
    else
        self.navigationItem.title = NSLocalizedString(@"ElapsedTime", @"Elapsed Time");
}

- (void)displayClockInNavigationBar {
	NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.locale = [NSLocale systemLocale];
    formatter.timeZone = [NSTimeZone systemTimeZone];
    formatter.dateFormat = @"HH:mm:ss";
	self.navigationItem.title = [formatter stringFromDate:[NSDate date]];
}

- (void)onClockTimer:(NSTimer *)theTimer
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (displayTimeMode > 0) {
        [self updateTimeMode];
        displayTimeMode--;
    }
    else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && orientation != UIInterfaceOrientationPortrait)
        [self displayClockInNavigationBar];
    else self.navigationItem.title = @"";
}

- (IBAction)pushStartKey:(id)sender
{
    [self startCounter];
}

- (IBAction)pushResetKey:(id)sender
{
    [self resetCounter];
}

- (IBAction)pushBellKey:(id)sender
{
    [self ringBell:1];
}

- (NSArray *)keyCommands {
    return @[
             [UIKeyCommand keyCommandWithInput: UIKeyInputLeftArrow
                                 modifierFlags: 0
                                        action: @selector(pushResetKey:)],
             [UIKeyCommand keyCommandWithInput: @" "
                                 modifierFlags: 0
                                        action: @selector(pushStartKey:)],
             [UIKeyCommand keyCommandWithInput: @"b"
                                 modifierFlags: 0
                                        action: @selector(pushBellKey:)],
             ];
}

@end
