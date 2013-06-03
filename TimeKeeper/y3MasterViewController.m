//
//  y3MasterViewController.m
//  TimeKeeper
//
//  Created by Yasuo Miyoshi on 12/06/28.
//  Copyright (c) 2012 Kochi Univ. All rights reserved.
//

#import "y3MasterViewController.h"
#import "y3DetailViewController.h"

@interface y3MasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation y3MasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;

- (void)awakeFromNib
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
	    self.clearsSelectionOnViewWillAppear = NO;
	    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
	}
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.navigationItem.leftBarButtonItem = self.editButtonItem;

	UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
	self.navigationItem.rightBarButtonItem = addButton;
	self.detailViewController = (y3DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
	if ([self.tableView numberOfRowsInSection:0] == 0) {
		[self insertNewObject:self];
		if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
			[self.detailViewController firstStart];
	}
	[self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
	[self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewDidAppear:(BOOL)animated
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		// 横向きで DetailView から戻ったときにナビゲーションバーがずれるのを直す
		[self.navigationController setNavigationBarHidden:YES];
		[self.navigationController setNavigationBarHidden:NO];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

- (void)insertNewObject:(id)sender
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
    [newManagedObject setValue:[NSNumber numberWithInt:0] forKey:@"order"];
    [newManagedObject setValue:[NSNumber numberWithInt:10] forKey:@"singleMinutes"];
	[newManagedObject setValue:[NSNumber numberWithInt:12] forKey:@"doubleMinutes"];
	[newManagedObject setValue:[NSNumber numberWithInt:15] forKey:@"tripleMinutes"];
	[newManagedObject setValue:[NSNumber numberWithBool:YES] forKey:@"doubleBell"];
	[newManagedObject setValue:[NSNumber numberWithBool:YES] forKey:@"tripleBell"];
	[newManagedObject setValue:@"" forKey:@"note"];
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
         // Replace this implementation with code to handle the error appropriately.
         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}



#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
	[self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	
	// 全アイテムを取得し配列へ
	NSMutableArray *tmpArray = [[self.fetchedResultsController fetchedObjects] mutableCopy];
	
	// 移動させるアイテムの取得
	NSManagedObject *item = [self.fetchedResultsController objectAtIndexPath:fromIndexPath];
	
	// 配列内から移動させるアイテムを一旦削除
	[tmpArray removeObject:item];
	// 削除したアイテムを新たな位置に挿入
	[tmpArray insertObject:item atIndex:[toIndexPath row]];
	
	int i = 0;
	
	// order属性の再設定
	for (NSManagedObject *obj in tmpArray)        
		[obj setValue:[NSNumber numberWithInt:i++] forKey:@"order"];
	
	tmpArray = nil;
	
	NSError *error = nil;
	
	// 保存処理
	if (![self.managedObjectContext save:&error]) {
		
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}
	
	[self.tableView reloadData];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        self.detailViewController.detailItem = object;
		if (self.editing) {
			[self.detailViewController edit];
		}
    }
	else {
		if (self.editing) {
			[self performSegueWithIdentifier:@"gotoEdit" sender:self];
		}
		else {
			[self performSegueWithIdentifier:@"showDetail" sender:self];
		}
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
	NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	[[segue destinationViewController] setDetailItem:object];
//    if ([[segue identifier] isEqualToString:@"showDetail"]) {
//    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
	NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
	[fetchRequest setSortDescriptors:sortDescriptors];
	
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return __fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
			if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
				if ([tableView numberOfRowsInSection:0] == 1) [self insertNewObject:self];
			}
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
				NSIndexPath *index = tableView.indexPathForSelectedRow;
				if (index.section == indexPath.section && index.row == indexPath.row) {
					[tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:YES scrollPosition:UITableViewScrollPositionTop];
					[self tableView:tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
				}
			}
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
	int singleMins = [[object valueForKey:@"singleMinutes"] intValue];
	int doubleMins = [[object valueForKey:@"doubleMinutes"] intValue];
	int tripleMins = [[object valueForKey:@"tripleMinutes"] intValue];
	NSString *singleUnit = (singleMins < 2) ? NSLocalizedString(@"min", @"min") : NSLocalizedString(@"mins", @"mins");
	NSString *doubleUnit = (doubleMins < 2) ? NSLocalizedString(@"min", @"min") : NSLocalizedString(@"mins", @"mins");
	NSString *tripleUnit = (tripleMins < 2) ? NSLocalizedString(@"min", @"min") : NSLocalizedString(@"mins", @"mins");
	if ([[object valueForKey:@"doubleBell"] boolValue]) {
		if ([[object valueForKey:@"tripleBell"] boolValue]) {
			cell.textLabel.text = [[NSString alloc] initWithFormat:@"🔔%d%@, %d%@, %d%@", singleMins, singleUnit, doubleMins, doubleUnit, tripleMins, tripleUnit];
		}
		else {
			cell.textLabel.text = [[NSString alloc] initWithFormat:@"🔔%d%@, %d%@", singleMins, singleUnit, doubleMins, doubleUnit];
		}
	}
	else {
		cell.textLabel.text = [[NSString alloc] initWithFormat:@"🔔%d%@", singleMins, singleUnit];
	}
    cell.detailTextLabel.text = [[object valueForKey:@"note"] description];
}

@end
