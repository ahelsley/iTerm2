//
//  TmuxGateway.h
//  iTerm
//
//  Created by George Nachman on 11/27/11.
//

#import <Cocoa/Cocoa.h>

@class TmuxController;

@protocol TmuxGatewayDelegate

- (TmuxController *)tmuxController;
- (void)tmuxUpdateLayoutForWindow:(int)windowId;
- (void)tmuxWindowsDidChange;
- (void)tmuxHostDisconnected;
- (void)tmuxWriteData:(NSData *)data;
- (void)tmuxReadTask:(NSData *)data;

@end

typedef enum {
    CONTROL_COMMAND_OUTPUT,
    CONTROL_COMMAND_LAYOUT_CHANGE,
    CONTROL_COMMAND_WINDOWS_CHANGE,
    CONTROL_COMMAND_NOOP
} ControlCommand;

typedef enum {
    CONTROL_STATE_READY,
    CONTROL_STATE_READING_DATA,
    CONTROL_STATE_DETACHED,
} ControlState;

@interface TmuxGateway : NSObject {
    NSObject<TmuxGatewayDelegate> *delegate_;  // weak
    ControlState state_;
    NSMutableData *stream_;
    
    // Data from parsing an incoming command
    ControlCommand command_;
    unsigned int window_;
    unsigned int windowPane_;
    int length_;
    NSMutableData *inputData_;
    
    NSMutableArray *commandQueue_;  // Dictionaries
    NSMutableString *currentCommandResponse_;
    NSMutableDictionary *currentCommand_;  // Set between %begin and %end
}

- (id)initWithDelegate:(NSObject<TmuxGatewayDelegate> *)delegate;

// Returns any unconsumed data if tmux mode is exited.
- (NSData *)readTask:(NSData *)data;
- (void)sendCommand:(NSString *)command responseTarget:(id)target responseSelector:(SEL)selector;
- (void)abortWithErrorMessage:(NSString *)message;

@end
