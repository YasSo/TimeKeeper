//
//  y3EditViewController.m
//  TimeKeeper
//
//  Created by Yasuo Miyoshi on 12/06/28.
//  Copyright (c) 2012 Kochi Univ. All rights reserved.
//

#import "y3EditViewController.h"

@interface y3EditViewController ()
@end

@implementation y3EditViewController

@synthesize editItem = _editItem;
@synthesize settingMemoField = _settingMemoField;
@synthesize doubleBellSW = _doubleBellSW;
@synthesize tripleBellSW = _tripleBellSW;
@synthesize singleMinStepper = _singleMinStepper;
@synthesize doubleMinStepper = _doubleMinStepper;
@synthesize tripleMinStepper = _tripleMinStepper;
@synthesize singleMinField = _singleMinField;
@synthesize doubleMinField = _doubleMinField;
@synthesize tripleMinField = _tripleMinField;
@synthesize referenceViewController = _referenceViewController;

- (void)setDetailItem:(id)newItem
{
	_editItem = newItem;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	self.navigationItem.title = NSLocalizedString(@"Edit", @"Edit");
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		self.contentSizeForViewInPopover = CGSizeMake(320, 400);
	}
}

- (void)viewDidUnload
{
	[self setDoubleBellSW:nil];
	[self setTripleBellSW:nil];
	[self setSingleMinStepper:nil];
	[self setDoubleMinStepper:nil];
	[self setTripleMinStepper:nil];
	[self setSingleMinField:nil];
	[self setDoubleMinField:nil];
	[self setTripleMinField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewDidDisappear:(BOOL)animated
{
	[_referenceViewController configureView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (![[_editItem valueForKey:@"doubleBell"] boolValue]) return 3;
	return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	if (section == 0) return 2;
	if (section == 1) {
		if ([[_editItem valueForKey:@"doubleBell"] boolValue]) return 2;
		return 1;
	}
	if (section == 2) {
		if (![[_editItem valueForKey:@"doubleBell"] boolValue]) return 1;
		if ([[_editItem valueForKey:@"tripleBell"] boolValue]) return 2;
		return 1;
	}
	if (section == 3) return 1;
	return 0;
}

- (void)memoChanged:(id)sender
{
	NSError *error = nil;
	[_editItem setValue:_settingMemoField.text forKey:@"note"];
	NSManagedObjectContext *context = _editItem.managedObjectContext;
	if (![context save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
}

- (void)switchChanged:(id)sender
{
    NSError *error = nil;
	[_editItem setValue:[NSNumber numberWithBool:_doubleBellSW.on] forKey:@"doubleBell"];
	if (_tripleBellSW)
		[_editItem setValue:[NSNumber numberWithBool:_tripleBellSW.on] forKey:@"tripleBell"];
	NSManagedObjectContext *context = _editItem.managedObjectContext;
	if (![context save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
	[self changeTimer:0 minutes:[[_editItem valueForKey:@"singleMinutes"] intValue]];
	[self setDoubleBellSW:nil];
	[self setTripleBellSW:nil];
	[self setSingleMinStepper:nil];
	[self setSingleMinField:nil];
	[self setDoubleMinStepper:nil];
	[self setDoubleMinField:nil];
	[self setTripleMinStepper:nil];
	[self setTripleMinField:nil];
	[self.tableView reloadData];
}

- (NSString *)minuteString:(int)min
{
	NSString *unit = (min < 2) ? NSLocalizedString(@"min", @"min") : NSLocalizedString(@"mins", @"mins");
	return [[NSString alloc] initWithFormat:@"%d%@", min, unit];
}

- (void)changeTimer:(int)index minutes:(int)m
{
    NSError *error = nil;
	int singleMinutes, doubleMinutes, tripleMinutes;
	BOOL doubleBell, tripleBell;
	singleMinutes = [[_editItem valueForKey:@"singleMinutes"] intValue];
	doubleMinutes = [[_editItem valueForKey:@"doubleMinutes"] intValue];
	tripleMinutes = [[_editItem valueForKey:@"tripleMinutes"] intValue];
	doubleBell = [[_editItem valueForKey:@"doubleBell"] boolValue];
	tripleBell = [[_editItem valueForKey:@"tripleBell"] boolValue];
	if (index == 0) {
		if (m < 1) m = 1;
		if (tripleBell && doubleBell) {
			if (m > 997) m = 997;
		}
		else if (doubleBell) {
			if (m > 998) m = 998;
		}
		else {
			if (m > 999) m = 999;
		}
		singleMinutes = m;
		if (doubleBell) {
			if (doubleMinutes <= singleMinutes) doubleMinutes = singleMinutes + 1;
			if (tripleBell) {
				if (tripleMinutes <= doubleMinutes) tripleMinutes = doubleMinutes + 1;
			}
		}
	}
	if (index == 1) {
		if (m < 2) m = 2;
		if (tripleBell) {
			if (m > 998) m = 998;
		}
		else if (m > 999) m = 999;
		doubleMinutes = m;
		if (doubleMinutes <= singleMinutes) singleMinutes = doubleMinutes - 1;
		if (tripleBell) {
			if (tripleMinutes <= doubleMinutes) tripleMinutes = doubleMinutes + 1;
		}
	}
	if (index == 2) {
		if (m < 3) m = 3;
		if (m > 999) m = 999;
		tripleMinutes = m;
		if (tripleMinutes <= doubleMinutes) doubleMinutes = tripleMinutes - 1;
		if (doubleMinutes <= singleMinutes) singleMinutes = doubleMinutes - 1;
	}
	[_singleMinStepper setValue:(double)singleMinutes];
	if (doubleBell) {
		[_doubleMinStepper setValue:(double)doubleMinutes];
		if (tripleBell) [_tripleMinStepper setValue:(double)tripleMinutes];
	}
	[_tripleMinStepper setMaximumValue:999.0];
	if (tripleMinutes > 999) tripleMinutes = 999;
	if (tripleBell && doubleBell) {
		[_singleMinStepper setMaximumValue:997.0];
		if (singleMinutes > 997) singleMinutes = 997;
		[_doubleMinStepper setMaximumValue:998.0];
		if (doubleMinutes > 998) doubleMinutes = 998;
	}
	else {
		[_doubleMinStepper setMaximumValue:999.0];
		if (doubleMinutes > 999) doubleMinutes = 999;
		if (doubleBell) {
			[_singleMinStepper setMaximumValue:998.0];
			if (singleMinutes > 998) singleMinutes = 998;
		}
		else {
			[_singleMinStepper setMaximumValue:999.0];
			if (singleMinutes > 999) singleMinutes = 999;
		}
	}
	[_singleMinField setText:[self minuteString:singleMinutes]];
	if (doubleBell) {
		[_doubleMinField setText:[self minuteString:doubleMinutes]];
		if (tripleBell) {
			[_tripleMinField setText:[self minuteString:tripleMinutes]];
		}
	}
	[_editItem setValue:[NSNumber numberWithInt:singleMinutes] forKey:@"singleMinutes"];
	if (doubleBell) [_editItem setValue:[NSNumber numberWithInt:doubleMinutes] forKey:@"doubleMinutes"];
	if (tripleBell) [_editItem setValue:[NSNumber numberWithInt:tripleMinutes] forKey:@"tripleMinutes"];
	NSManagedObjectContext *context = _editItem.managedObjectContext;
	if (![context save:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
	[_referenceViewController configureView];
}

- (void)timeFieldChanged:(UITextField *)sender
{
	if (sender == _singleMinField) [self changeTimer:0 minutes:[_singleMinField.text intValue]];
	if (sender == _doubleMinField) [self changeTimer:1 minutes:[_doubleMinField.text intValue]];
	if (sender == _tripleMinField) [self changeTimer:2 minutes:[_tripleMinField.text intValue]];
}

- (void)timeFieldEditingDidBegin:(UITextField *)sender
{
	if (sender == _singleMinField) _singleMinField.text = [[NSString alloc] initWithFormat:@"%d", [[_editItem valueForKey:@"singleMinutes"] integerValue]];
	if (sender == _doubleMinField) _doubleMinField.text = [[NSString alloc] initWithFormat:@"%d", [[_editItem valueForKey:@"doubleMinutes"] integerValue]];
	if (sender == _tripleMinField) _tripleMinField.text = [[NSString alloc] initWithFormat:@"%d", [[_editItem valueForKey:@"tripleMinutes"] integerValue]];
}

- (void)closeKeyboard:(id)sender
{
	[self.view endEditing:YES];
}

- (void)stepperChanged:(UIStepper *)sender
{
	if (sender == _singleMinStepper) [self changeTimer:0 minutes:(int)_singleMinStepper.value];
	if (sender == _doubleMinStepper) [self changeTimer:1 minutes:(int)_doubleMinStepper.value];
	if (sender == _tripleMinStepper) [self changeTimer:2 minutes:(int)_tripleMinStepper.value];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
	int noteSection;
	if ([[_editItem valueForKey:@"doubleBell"] boolValue]) noteSection = 3;
	else noteSection = 2;
    if (indexPath.section == noteSection) {
		[cell.textLabel setText:NSLocalizedString(@"SettingMemo", @"SettingMemo")];
		UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 190, cell.frame.size.height)];
		[field setTextColor:[UIColor colorWithRed:59.0/255.0 green:85.0/255.0 blue:133.0/255.0 alpha:1.0]];
		[field setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
		[field setTextAlignment:UITextAlignmentLeft];
		[field setText:[[_editItem valueForKey:@"note"] description]];
		[field setPlaceholder:NSLocalizedString(@"SettingMemoPlaceholder", @"Option")];
		[field setKeyboardType:UIKeyboardTypeDefault];
		[field setReturnKeyType:UIReturnKeyDone];
		[field setAutocorrectionType:UITextAutocorrectionTypeNo];
		[field setAutocapitalizationType:UITextAutocapitalizationTypeNone];
		[field setClearButtonMode:UITextFieldViewModeWhileEditing];
		[field addTarget:self action:@selector(memoChanged:) forControlEvents:UIControlEventEditingDidEnd];
		[field addTarget:self action:@selector(memoChanged:) forControlEvents:UIControlEventEditingDidEndOnExit];
		[cell setAccessoryView:field];
		[self setSettingMemoField:field];
    }
	else {
        if (indexPath.row == 0) {
            UISwitch *sw = [[UISwitch alloc] init];
			[sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
			[cell setAccessoryView:sw];
			switch (indexPath.section) {
				case 0:
					[cell.textLabel setText:@"🔔"];
					[sw setOn:YES];
					[sw setEnabled:NO];
					break;
				case 1:
					[cell.textLabel setText:@"🔔🔔"];
					[sw setOn:[[_editItem valueForKey:@"doubleBell"] boolValue]];
					[self setDoubleBellSW:sw];
					break;
				case 2:
					[cell.textLabel setText:@"🔔🔔🔔"];
					[sw setOn:[[_editItem valueForKey:@"tripleBell"] boolValue]];
					[self setTripleBellSW:sw];
					break;
			}
		}
		else {
			[cell.textLabel setText:NSLocalizedString(@"SetTime", @"SetTime")];
			UITextField *timeField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 65, cell.frame.size.height)];
			UIStepper *stepper = [[UIStepper alloc] initWithFrame:CGRectMake(70, 9, 100, cell.frame.size.height)];
			UIView *subview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 170, cell.frame.size.height)];
			[subview addSubview:timeField];
			[subview addSubview:stepper];
			[timeField setTextColor:[UIColor colorWithRed:59.0/255.0 green:85.0/255.0 blue:133.0/255.0 alpha:1.0]];
			[timeField setTextAlignment:UITextAlignmentRight];
			[timeField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
			[timeField setKeyboardType:UIKeyboardTypeNumberPad];
			[timeField setReturnKeyType:UIReturnKeyDone];
			[timeField setAutocorrectionType:UITextAutocorrectionTypeNo];
			[timeField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
			[timeField addTarget:self action:@selector(timeFieldEditingDidBegin:) forControlEvents:UIControlEventEditingDidBegin];
			[timeField addTarget:self action:@selector(timeFieldChanged:) forControlEvents:UIControlEventEditingDidEnd];
			[timeField addTarget:self action:@selector(timeFieldChanged:) forControlEvents:UIControlEventEditingDidEndOnExit];
			if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
				UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
				[toolBar sizeToFit];
				UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
				UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeKeyboard:)];
				NSArray *items = [NSArray arrayWithObjects:spacer, done, nil];
				[toolBar setItems:items animated:YES];
				timeField.inputAccessoryView = toolBar;
			}
			[stepper setStepValue:1.0];
			[stepper addTarget:self action:@selector(stepperChanged:) forControlEvents:UIControlEventValueChanged];
			cell.accessoryView = subview;
			int singleMinutes = [[_editItem valueForKey:@"singleMinutes"] integerValue];
			int doubleMinutes = [[_editItem valueForKey:@"doubleMinutes"] integerValue];
			if (doubleMinutes <= singleMinutes) doubleMinutes = singleMinutes + 1;
			int tripleMinutes = [[_editItem valueForKey:@"tripleMinutes"] integerValue];
			if (tripleMinutes <= doubleMinutes) tripleMinutes = doubleMinutes + 1;
			switch (indexPath.section) {
				case 0:
					[stepper setMinimumValue:1.0];
					if ([[_editItem valueForKey:@"tripleBell"] boolValue] && [[_editItem valueForKey:@"doubleBell"] boolValue]) [stepper setMaximumValue:997.0];
					else if ([[_editItem valueForKey:@"doubleBell"] boolValue]) [stepper setMaximumValue:998.0];
					else [stepper setMaximumValue:999.0];
					[stepper setValue:(double)singleMinutes];
					[timeField setText:[self minuteString:singleMinutes]];
					[self setSingleMinStepper:stepper];
					[self setSingleMinField:timeField];
					break;
				case 1:
					[stepper setMinimumValue:2.0];
					if ([[_editItem valueForKey:@"tripleBell"] boolValue]) [stepper setMaximumValue:998.0];
					else [stepper setMaximumValue:999.0];
					[stepper setValue:(double)doubleMinutes];
					[timeField setText:[self minuteString:doubleMinutes]];
					[self setDoubleMinStepper:stepper];
					[self setDoubleMinField:timeField];
					break;
				case 2:
					[stepper setMinimumValue:3.0];
					[stepper setMaximumValue:999.0];
					[stepper setValue:(double)tripleMinutes];
					[timeField setText:[self minuteString:tripleMinutes]];
					[self setTripleMinStepper:stepper];
					[self setTripleMinField:timeField];
					break;
			}
		}
	}
    return cell;
}

@end
