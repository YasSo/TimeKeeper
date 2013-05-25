//
//  y3EditViewController.h
//  TimeKeeper
//
//  Created by Yasuo Miyoshi on 12/06/28.
//  Copyright (c) 2012 Kochi Univ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "y3DetailViewController.h"

@interface y3EditViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate>

@property (strong, nonatomic) NSManagedObject *editItem;
@property (strong, nonatomic) UITextField *settingMemoField;
@property (strong, nonatomic) UISwitch *doubleBellSW;
@property (strong, nonatomic) UISwitch *tripleBellSW;
@property (strong, nonatomic) UIStepper *singleMinStepper;
@property (strong, nonatomic) UIStepper *doubleMinStepper;
@property (strong, nonatomic) UIStepper *tripleMinStepper;
@property (strong, nonatomic) UITextField *singleMinField;
@property (strong, nonatomic) UITextField *doubleMinField;
@property (strong, nonatomic) UITextField *tripleMinField;
@property (strong, nonatomic) y3DetailViewController *referenceViewController;

- (void)setDetailItem:(id)newItem;

@end
