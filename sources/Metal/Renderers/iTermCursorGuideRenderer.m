#import "iTermCursorGuideRenderer.h"

@interface iTermCursorGuideRendererTransientState()
@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic) int row;
@property (nonatomic) int col;
@end

@implementation iTermCursorGuideRendererTransientState {
    int _row;
    int _col;
}

- (void)setCursorCoord:(VT100GridCoord)coord within:(VT100GridSize)bounds {
    _row = (0 <= coord.y && coord.y < bounds.height) ? coord.y : -1;
    _col = (0 <= coord.x && coord.x < bounds.width)  ? coord.x : -1;
}

- (void)initializeVerticesWithPool:(iTermMetalBufferPool *)verticesPool {
    CGSize cellSize = self.cellConfiguration.cellSize;
    VT100GridSize gridSize = self.cellConfiguration.gridSize;

    const CGRect quad = CGRectMake(self.margins.left,
                                   self.margins.top + (gridSize.height - self.row - 1) * cellSize.height,
                                   cellSize.width * gridSize.width,
                                   cellSize.height);
    const CGRect textureFrame = CGRectMake(0, 0, 1, 1);
    const iTermVertex vertices[] = {
        // Pixel Positions                              Texture Coordinates
        { { CGRectGetMaxX(quad), CGRectGetMinY(quad) }, { CGRectGetMaxX(textureFrame), CGRectGetMinY(textureFrame) } },
        { { CGRectGetMinX(quad), CGRectGetMinY(quad) }, { CGRectGetMinX(textureFrame), CGRectGetMinY(textureFrame) } },
        { { CGRectGetMinX(quad), CGRectGetMaxY(quad) }, { CGRectGetMinX(textureFrame), CGRectGetMaxY(textureFrame) } },

        { { CGRectGetMaxX(quad), CGRectGetMinY(quad) }, { CGRectGetMaxX(textureFrame), CGRectGetMinY(textureFrame) } },
        { { CGRectGetMinX(quad), CGRectGetMaxY(quad) }, { CGRectGetMinX(textureFrame), CGRectGetMaxY(textureFrame) } },
        { { CGRectGetMaxX(quad), CGRectGetMaxY(quad) }, { CGRectGetMaxX(textureFrame), CGRectGetMaxY(textureFrame) } },
    };
    self.vertexBuffer = [verticesPool requestBufferFromContext:self.poolContext
                                                     withBytes:vertices
                                                checkIfChanged:YES];

    const CGRect vQuad = CGRectMake(self.margins.left + self.col * cellSize.width,
                                    self.margins.top,
                                    cellSize.width,
                                    cellSize.height * gridSize.height);
    const iTermVertex vvertices[] = {
        { { CGRectGetMaxX(vQuad), CGRectGetMinY(vQuad) }, { CGRectGetMaxX(textureFrame), CGRectGetMinY(textureFrame) } },
        { { CGRectGetMinX(vQuad), CGRectGetMinY(vQuad) }, { CGRectGetMinX(textureFrame), CGRectGetMinY(textureFrame) } },
        { { CGRectGetMinX(vQuad), CGRectGetMaxY(vQuad) }, { CGRectGetMinX(textureFrame), CGRectGetMaxY(textureFrame) } },

        { { CGRectGetMaxX(vQuad), CGRectGetMinY(vQuad) }, { CGRectGetMaxX(textureFrame), CGRectGetMinY(textureFrame) } },
        { { CGRectGetMinX(vQuad), CGRectGetMaxY(vQuad) }, { CGRectGetMinX(textureFrame), CGRectGetMaxY(textureFrame) } },
        { { CGRectGetMaxX(vQuad), CGRectGetMaxY(vQuad) }, { CGRectGetMaxX(textureFrame), CGRectGetMaxY(textureFrame) } },
    };
    self.vvertexBuffer = [verticesPool requestBufferFromContext:self.poolContext
                                                      withBytes:vvertices
                                                 checkIfChanged:YES];
}

- (void)writeDebugInfoToFolder:(NSURL *)folder {
    [super writeDebugInfoToFolder:folder];
    [[NSString stringWithFormat:@"row=%@", @(_row)] writeToURL:[folder URLByAppendingPathComponent:@"state.txt"]
                                                    atomically:NO
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];
}

@end

@implementation iTermCursorGuideRenderer {
    iTermMetalCellRenderer *_cellRenderer;
    id<MTLTexture> _texture;
    NSColor *_color;
    CGSize _lastCellSize;
}

- (instancetype)initWithDevice:(id<MTLDevice>)device {
    self = [super init];
    if (self) {
        _color = [[NSColor blueColor] colorWithAlphaComponent:0.7];
        _cellRenderer = [[iTermMetalCellRenderer alloc] initWithDevice:device
                                                    vertexFunctionName:@"iTermCursorGuideVertexShader"
                                                  fragmentFunctionName:@"iTermCursorGuideFragmentShader"
                                                              blending:[iTermMetalBlending compositeSourceOver]
                                                        piuElementSize:0
                                                   transientStateClass:[iTermCursorGuideRendererTransientState class]];
    }
    return self;
}

- (BOOL)rendererDisabled {
    return NO;
}

- (iTermMetalFrameDataStat)createTransientStateStat {
    return iTermMetalFrameDataStatPqCreateCursorGuideTS;
}

- (nullable __kindof iTermMetalRendererTransientState *)createTransientStateForCellConfiguration:(iTermCellRenderConfiguration *)configuration
                                                                                   commandBuffer:(id<MTLCommandBuffer>)commandBuffer {
    if (!_enabled) {
        return nil;
    }
    __kindof iTermMetalCellRendererTransientState * _Nonnull transientState =
        [_cellRenderer createTransientStateForCellConfiguration:configuration
                                                  commandBuffer:commandBuffer];
    [self initializeTransientState:transientState];
    return transientState;
}

- (void)initializeTransientState:(iTermCursorGuideRendererTransientState *)tState {
    if (!CGSizeEqualToSize(tState.cellConfiguration.cellSize, _lastCellSize)) {
        _texture = [self newCursorGuideTextureWithTransientState:tState];
        _lastCellSize = tState.cellConfiguration.cellSize;
    }
    tState.texture = _texture;
}

- (void)setColor:(NSColor *)color {
    _color = color;

    // Invalidate cell size so the texture gets created again
    _lastCellSize = CGSizeZero;
}

- (void)drawWithFrameData:(iTermMetalFrameData *)frameData
           transientState:(__kindof iTermMetalCellRendererTransientState *)transientState {
    iTermCursorGuideRendererTransientState *tState = transientState;
    if (tState.row < 0 || tState.col < 0) {
        return;
    }

    [tState initializeVerticesWithPool:_cellRenderer.verticesPool];
    if (tState.row >= 0 && self.enabled) {
        [_cellRenderer drawWithTransientState:tState
                                renderEncoder:frameData.renderEncoder
                             numberOfVertices:6
                                 numberOfPIUs:0
                                vertexBuffers:@{ @(iTermVertexInputIndexVertices): tState.vertexBuffer }
                              fragmentBuffers:@{}
                                     textures:@{ @(iTermTextureIndexPrimary): tState.texture } ];
    }

    if (tState.col >= 0 && self.venabled) {
        [_cellRenderer drawWithTransientState:tState
                                renderEncoder:frameData.renderEncoder
                             numberOfVertices:6
                                 numberOfPIUs:0
                                vertexBuffers:@{ @(iTermVertexInputIndexVertices): tState.vvertexBuffer }
                              fragmentBuffers:@{}
                                     textures:@{ @(iTermTextureIndexPrimary): tState.texture } ];
    }
}

#pragma mark - Private

- (id<MTLTexture>)newCursorGuideTextureWithTransientState:(iTermCursorGuideRendererTransientState *)tState {
    NSImage *image = [[NSImage alloc] initWithSize:tState.cellConfiguration.cellSize];

    [image lockFocus];
    {
        [_color set];
        NSRect rect = NSMakeRect(0,
                                 0,
                                 tState.cellConfiguration.cellSize.width,
                                 tState.cellConfiguration.cellSize.height);
        NSRectFillUsingOperation(rect, NSCompositingOperationSourceOver);

        rect.size.height = tState.cellConfiguration.scale;
        NSRectFillUsingOperation(rect, NSCompositingOperationSourceOver);

        rect.origin.y += tState.cellConfiguration.cellSize.height - tState.cellConfiguration.scale;
        NSRectFillUsingOperation(rect, NSCompositingOperationSourceOver);
    }
    [image unlockFocus];

    return [_cellRenderer textureFromImage:image context:tState.poolContext];
}

@end
