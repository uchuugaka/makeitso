//
//  Document.m
//  MISGenerator
//
//  Created by Todd Ditchendorf on 12/26/14.
//  Copyright (c) 2014 Todd Ditchendorf. All rights reserved.
//

#import "Document.h"

#import "FilePreviewItem.h"
#import "ObjCAssembler.h"
#import "ObjCParser.h"

//#import "MISClass.h"
//#import "MISField.h"

#import <TDAppKit/TDUtils.h>
#import <TDAppKit/TDColorView.h>
#import <TDAppKit/TDDropTargetView.h>
#import <TDAppKit/TDHintButton.h>

#import <TDTemplateEngine/TDTemplateEngine.h>

#define ICON_KEY @"iconImage"
#define PATH_KEY @"filePath"

@interface Document ()
@property (nonatomic, retain) PKParser *parser;
@property (nonatomic, retain) Assembler *assembler;
@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {

    }
    return self;
}


- (void)dealloc {
    self.dropTargetView = nil;
    self.tableContainerView = nil;
    self.tableView = nil;
    self.topHorizontalLine = nil;
    self.botHorizontalLine = nil;

    
    self.headerFilesArrayController = nil;
    self.headerFiles = nil;
    
    self.browseForDatabaseURL = nil;
    self.browseForOutputSourceURL = nil;
    self.browseForHeadersURL = nil;
    
    self.databaseFilename = nil;
    self.databaseDirPath = nil;
    self.outputSourceDirPath = nil;
    
    self.parser = nil;
    self.assembler = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark NSDocument

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];

    TDAssert(_tableView);
    TDAssert(_tableView.delegate == self);
    TDAssert(_tableView.dataSource == self);
    
    TDAssert(_tableView);
    [_tableView setTarget:self];
    [_tableView setDoubleAction:@selector(revealSelectedFilePathsInFinder:)];
    
    TDAssert(_dropTargetView);
    TDAssert(_dropTargetView.hintButton);
    _dropTargetView.borderMarginSize = CGSizeMake(20.0, 20.0);
    _dropTargetView.buttonMarginSize = CGSizeMake(40.0, 40.0);
    [_dropTargetView.hintButton setTarget:self];
    [_dropTargetView.hintButton setAction:@selector(browseForHeaders:)];
    [_dropTargetView.hintButton setHintText:NSLocalizedString(@"Add Objective-C Headers", @"")];
    [_dropTargetView registerForDraggedTypes:@[NSFilenamesPboardType]];
    [_dropTargetView setColor:[NSColor windowBackgroundColor]];

    NSColor *borderColor = [NSColor colorWithDeviceWhite:0.67 alpha:1.0];
    
    TDAssert(_topHorizontalLine);
    TDAssert(_botHorizontalLine);
    _topHorizontalLine.color = borderColor;
    _botHorizontalLine.color = borderColor;
}


+ (BOOL)autosavesInPlace {
    return YES;
}


- (NSString *)windowNibName {
    return @"Document";
}


- (NSWindow *)window {
    return [self.windowControllers[0] window];
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    
    NSMutableDictionary *plist = [NSMutableDictionary dictionary];
    
    if (_databaseFilename) plist[@"databaseFilename"] = _databaseFilename;
    if (_databaseDirPath) plist[@"databaseDirPath"] = _databaseDirPath;
    if (_outputSourceDirPath) plist[@"outputSourceDirPath"] = _outputSourceDirPath;

    NSMutableArray *headerFilePaths = [NSMutableArray arrayWithCapacity:[_headerFiles count]];
    for (NSDictionary *d in _headerFiles) {
        NSString *headerFilePath = d[PATH_KEY];
        [headerFilePaths addObject:headerFilePath];
    }
    plist[@"headerFilePaths"] = headerFilePaths;
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:plist];
    return data;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    
    NSDictionary *plist = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    self.databaseFilename = plist[@"databaseFilename"];
    self.databaseDirPath = plist[@"databaseDirPath"];
    self.outputSourceDirPath = plist[@"outputSourceDirPath"];
    
    NSArray *headerFilePaths = plist[@"headerFilePaths"];
    self.headerFiles = [self headerFilesFromHeaderFilePaths:headerFilePaths];
    
    return YES;
}


#pragma mark -
#pragma mark Actions

- (IBAction)browseForDatabase:(id)sender {
    TDAssertMainThread();
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setDirectoryURL:_browseForDatabaseURL];
    
    [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (NSOKButton == result) {
            
            NSURL *furl = [panel URL];
            self.databaseDirPath = [furl relativePath];
        }
    }];
}


- (IBAction)browseForOutputSource:(id)sender {
    TDAssertMainThread();
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setDirectoryURL:_browseForOutputSourceURL];
    
    [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (NSOKButton == result) {
            
            NSURL *furl = [panel URL];
            self.outputSourceDirPath = [furl relativePath];
        }
    }];
}


- (IBAction)browseForHeaders:(id)sender {
    TDAssertMainThread();
    
    NSArray *exts = self.allowedHeaderFileExtensions;
    TDAssert([exts count]);
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    
    [panel setAllowedFileTypes:exts];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:YES];
    [panel setDirectoryURL:_browseForHeadersURL];
    
    [panel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
        if (NSOKButton == result) {
            
            NSArray *furls = [panel URLs];
            NSMutableArray *paths = [NSMutableArray arrayWithCapacity:[furls count]];
            
            for (NSURL *furl in furls) {
                NSString *path = [furl relativePath];
                if (path) [paths addObject:path];
            }
            
            [self handleAddedFilePaths:paths];
        }
    }];
}


- (IBAction)parse:(id)sender {
    TDAssertMainThread();
    
    if (![_headerFiles count]) {
        NSBeep();
        return;
    }
    
    TDAssert(_headerFiles);
    NSArray *files = [[_headerFiles copy] autorelease];
    
    TDPerformOnBackgroundThread(^{
        TDAssertNotMainThread();
        NSMutableArray *classes = [NSMutableArray array];
        
        for (NSDictionary *d in files) {
            NSString *filePath = d[PATH_KEY];
            if (![filePath length]) {
                TDAssert(0);
                continue;
            }
            
            NSError *err = nil;
            NSString *source = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&err];
            if (!source) {
                if (err) NSLog(@"%@", err);
                continue;
            }
            
            NSArray *newClasses = [self parseSourceCode:source];
            [classes addObjectsFromArray:newClasses];
        }
        
        TDPerformOnMainThread(^{
            if ([classes count]) {
                
                if ([classes count]) {
                    TDAssert(0); // DO SOMETHING
                } else {
                    NSBeep();
                }
                
                
            } else {
                NSBeep();
            }
        });
    });
}


- (IBAction)copyFilePaths:(id)sender {
    TDAssertMainThread();
    NSArray *items = [_headerFilesArrayController selectedObjects];
    
    NSUInteger c = [items count];
    TDAssert(NSNotFound != c);
    if (c == 0) return;
    
    NSUInteger i = 0;
    
    NSMutableString *buf = [NSMutableString string];
    for (NSDictionary *item in items) {
        NSString *path = item[PATH_KEY];
        TDAssert([path length]);
        BOOL isLast = i == c - 1;
        [buf appendFormat:@"%@%@", path, isLast ? @"" : @"\n"];
        ++i;
    }
    
    TDAssert([buf length]);
    
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:@[NSStringPboardType] owner:self];
    [pboard addTypes:@[NSStringPboardType] owner:self];
    [pboard setString:buf forType:NSStringPboardType];
}


- (IBAction)revealSelectedFilePathsInFinder:(id)sender {
    TDAssertMainThread();
    NSArray *items = [_headerFilesArrayController selectedObjects];
    [self revealFilePathsInFinder:items];
}


- (IBAction)filePathTableViewDoubleClick:(id)sender {
    TDAssertMainThread();
    TDAssert(_headerFilesArrayController);
    
    NSInteger row = [_headerFilesArrayController selectionIndex];
    TDAssert(row > -1);
    TDAssert(row < [[_headerFilesArrayController arrangedObjects] count]);
    
    NSString *path = [_headerFilesArrayController arrangedObjects][row];
    TDAssert([path length]);
    
    [self revealFilePathsInFinder:@[path]];
}


- (IBAction)togglePreviewPanel:(id)sender {
    TDAssertMainThread();
    
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
    } else {
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
    }
}


#pragma mark -
#pragma mark NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    BOOL enabled = YES;
    
    SEL action = [item action];
    
    if (action == @selector(togglePreviewPanel:)) {
        if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
            [item setTitle:NSLocalizedString(@"Close Quick Look panel", @"")];
            enabled = YES;
        } else {
            TDAssert(_headerFilesArrayController);
            NSUInteger c = [[_headerFilesArrayController arrangedObjects] count];
            NSString *title = nil;
            
            switch (c) {
                case 0:
                    enabled = NO;
                    title = NSLocalizedString(@"Open Quick Look panel", @"");
                    break;
                case 1:
                    enabled = YES;
                    NSString *filename = [_headerFilesArrayController.selectedObjects[0][PATH_KEY] lastPathComponent];
                    title = [NSString stringWithFormat:NSLocalizedString(@"Quick Look %@", @""), filename];
                    break;
                default:
                    enabled = YES;
                    title = [NSString stringWithFormat:NSLocalizedString(@"Quick Look %lu items", @""), c];
                    break;
            }
            [item setTitle:title];
        }
    }
    
    return enabled;
}


#pragma mark -
#pragma mark QLPreviewPanelDataSource

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
    return YES;
}


- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    TDAssertMainThread();
    
    panel.dataSource = self;
    panel.delegate = self;
    
    TDAssert(_tableView);
    NSInteger row = [[_tableView selectedRowIndexes] firstIndex];
    [panel setCurrentPreviewItemIndex:row];
}


- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
    
}


- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    NSUInteger c = [[_headerFilesArrayController arrangedObjects] count];
    return c;
}


- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)i {
    TDAssertMainThread();
    TDAssert(_headerFilesArrayController);
    
    FilePreviewItem *result = nil;
    
    NSArray *objs = [_headerFilesArrayController arrangedObjects];
    NSUInteger c = [objs count];
    
    if (i > -1 && i < c) {
        NSDictionary *d = objs[i];
        
        result = [FilePreviewItem previewItemWithDictionary:d row:i];
        
        NSTableView *tv = _tableView;
        NSInteger row = panel.currentPreviewItemIndex;
        
        [tv selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        NSRect vizRect = [tv visibleRect];
        NSRect rowRect = [tv rectOfRow:i];
        rowRect.size.width = 1.0;
        if (!NSContainsRect(vizRect, rowRect)) {
            [tv scrollRowToVisible:row];
        }
    } else {
        TDAssert(0);
    }
    
    return result;
}


#pragma mark -
#pragma mark QLPreviewPanelDelegate

- (NSRect)previewPanel:(QLPreviewPanel *)panel sourceFrameOnScreenForPreviewItem:(id <QLPreviewItem>)item {
    TDAssertMainThread();
    TDAssert(_headerFilesArrayController);
    
    FilePreviewItem *previewItem = (FilePreviewItem *)item;
    NSInteger row = previewItem.row;
    NSRect frameInWin = [_tableView convertRect:[_tableView rectOfRow:row] toView:nil];
    frameInWin.size.width = [[_tableView enclosingScrollView] frame].size.width;
    NSRect frameInScreen = [[self window] convertRectToScreen:frameInWin];
    return frameInScreen;
}


// must manually handle up/down arrow keys. just make behavior same as left/right keys
- (BOOL)previewPanel:(QLPreviewPanel *)panel handleEvent:(NSEvent *)evt {
#define UP_ARROW 126
#define DOWN_ARROW 125
    BOOL handled = NO;
    BOOL isKeyDown = (NSKeyDown == [evt type]);
    
    if (isKeyDown) {
        NSInteger keyCode = [evt keyCode];
        
        if (UP_ARROW == keyCode || DOWN_ARROW == keyCode) {
            handled = YES;
            NSUInteger c = [self numberOfPreviewItemsInPreviewPanel:panel];
            NSInteger row = panel.currentPreviewItemIndex;
            
            if (UP_ARROW == keyCode) {
                row = (0 == row) ? c - 1 : row - 1;
            } else if (DOWN_ARROW == keyCode) {
                row = (row + 1) % c;
            }
            panel.currentPreviewItemIndex = row;
        }
    }
    
    return handled;
}


#pragma mark -
#pragma mark Private

- (NSArray *)allowedHeaderFileExtensions {
    TDAssertMainThread();
    return @[@"h"];
}


- (void)handleAddedFilePaths:(NSArray *)filePaths {
    TDAssertMainThread();
    
    NSArray *exts = self.allowedHeaderFileExtensions;
    TDAssert([exts count]);
    
    if ([filePaths count]) {
        NSMutableArray *filteredFilePaths = [NSMutableArray arrayWithCapacity:[filePaths count]];
        
        for (NSString *filePath in filePaths) {
            if ([exts containsObject:[filePath pathExtension]]) {
                [filteredFilePaths addObject:filePath];
            }
        }
        
        if (![filteredFilePaths count]) {
            NSBeep();
            return;
        }
        
        NSMutableArray *newFiles = [NSMutableArray arrayWithArray:_headerFiles];
        [newFiles addObjectsFromArray:[self headerFilesFromHeaderFilePaths:filteredFilePaths]];
        self.headerFiles = newFiles;
        
        // hide drop target, show table
        [_dropTargetView setHidden:YES];
        [_tableContainerView setHidden:NO];
    }
}


- (NSMutableArray *)headerFilesFromHeaderFilePaths:(NSArray *)inFilePaths {
    NSMutableArray *items = [NSMutableArray array];
    
    for (NSString *path in inFilePaths) {
        NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
        if (!icon) {
            icon = [[NSWorkspace sharedWorkspace] iconForFileType:@"txt"];
        }
        
        TDAssert(icon);
        TDAssert([path length]);
        NSMutableDictionary *item = [[@{ICON_KEY: icon, PATH_KEY: path} mutableCopy] autorelease];
        [items addObject:item];
    }
    
    return items;
}


- (NSArray *)parseSourceCode:(NSString *)source {
    
    self.assembler = [[[ObjCAssembler alloc] init] autorelease];
    self.parser = [[[ObjCParser alloc] initWithDelegate:_assembler] autorelease];
    
    NSError *err = nil;
    id res = [[[_parser parseString:source error:&err] retain] autorelease];
    
    NSArray *classes = [[_assembler.classes copy] autorelease];
    
    self.parser = nil;
    self.assembler = nil;
    
    if (!res) {
        if (err) {
            NSLog(@"%@", err);
            TDPerformOnMainThread(^{
                NSBeep();
                [self presentParsingError:err];
            });
        }
    }
    
    return classes;
}


- (void)presentParsingError:(NSError *)err {
    TDAssertMainThread();
    TDAssert([PEGKitErrorDomain isEqualToString:[err domain]]);
    
    NSString *title = NSLocalizedString(@"A parsing error occured.", @"");
    NSString *reason = [err localizedDescription];
    NSString *desc = [err localizedFailureReason];
    
    NSString *defaultBtn = NSLocalizedString(@"OK", @"");
    NSString *altBtn = nil;
    NSString *otherBtn = nil;
    
    NSRunAlertPanel(title, @"%@\n\n%@", defaultBtn, altBtn, otherBtn, reason, desc);
}


- (void)revealFilePathsInFinder:(NSArray *)items {
    TDAssertMainThread();
    
    NSUInteger c = [items count];
    TDAssert(NSNotFound != c);
    if (c == 0) return;
    
    [self doRevealFilePathsInFinder:items];
}


- (void)doRevealFilePathsInFinder:(NSArray *)items {
    NSUInteger c = [items count];
    TDAssert(c > 0);
    
    NSMutableArray *furls = [NSMutableArray arrayWithCapacity:c];
    for (NSDictionary *item in items) {
        NSString *path = item[PATH_KEY];
        if ([path length]) {
            NSURL *furl = [NSURL fileURLWithPath:path];
            if (furl) [furls addObject:furl];
        }
    }
    
    if ([furls count]) {
        [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:furls];
    } else {
        NSBeep();
    }
}

#pragma mark -
#pragma mark SourceFilesTableViewDelegate

- (void)resultsTableView:(NSTableView *)tv didReceiveClickOnRow:(NSInteger)row {
    
}


- (void)resultsTableView:(NSTableView *)tv didReceiveRightClickOnRow:(NSInteger)row {
    TDAssertMainThread();
    TDAssert(row > -1);
    
    NSUInteger c = [[_headerFilesArrayController selectionIndexes] count];
    if (0 == c) {
        [_headerFilesArrayController addSelectionIndexes:[NSIndexSet indexSetWithIndex:row]];
    }
    
    if (row > -1 /*&& [[_headerFilesArrayController selectionIndexes] containsIndex:row]*/) {
        TDPerformOnMainThreadAfterDelay(0.0, ^{
            NSMenu *menu = [self resultTableContextMenu];
            [NSMenu popUpContextMenu:menu withEvent:[[self window] currentEvent] forView:tv];
        });
    }
}


- (NSMenu *)resultTableContextMenu {
    TDAssert(_headerFilesArrayController);
    
    NSMenu *menu = [[[NSMenu alloc] init] autorelease];
    
    NSUInteger c = [[_headerFilesArrayController selectionIndexes] count];
    BOOL hasMulti = c > 1;
    
    NSString *revealTitle = nil;
    if (hasMulti) {
        revealTitle = [NSString stringWithFormat:NSLocalizedString(@"Reveal %lu items in the Finder", @""), c];
    } else {
        revealTitle = NSLocalizedString(@"Reveal in Finder", @"");
    }
    
    [menu addItemWithTitle:revealTitle action:@selector(revealSelectedFilePathsInFinder:) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedString(@"Copy Full Path%@", @""), hasMulti ? @"s" : @""] action:@selector(copyFilePaths:) keyEquivalent:@""];
    
    return menu;
}


- (void)resultsTableViewDidEscape:(NSTableView *)tv {
    
}


- (void)resultsTableViewDidSpacebar:(NSTableView *)tv {
    [self togglePreviewPanel:tv];
}

@end
