//
//  y3DetailViewController.h
//  TimeKeeper
//
//  Created by Yasuo Miyoshi on 12/06/28.
//  Copyright (c) 2012 Kochi Univ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface y3DetailViewController : UIViewController <UISplitViewControllerDelegate, UIPopoverControllerDelegate>

@property (strong, nonatomic) id detailItem;
@property (strong, nonatomic) UIPopoverController *editPopover;

@property (weak, nonatomic) IBOutlet UINavigationItem *navItem;

@property (weak, nonatomic) IBOutlet UIProgressView *timeProgressView;
@property (weak, nonatomic) IBOutlet UILabel *counterLabel;
@property (weak, nonatomic) IBOutlet UILabel *singleTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *doubleTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *tripleTimeLabel;
@property (weak, nonatomic) IBOutlet UIView *buttonSubView;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIView *detailView;

- (void)playSound:(int)count;
- (void)displayClockInNavigationBar;
- (void)edit;
- (void)configureView;
- (void)firstStart;

@end
