unit diagram;

{$mode objfpc}{$H+}

interface

uses
  windows, Classes, SysUtils, controls,Types, graphics, diagramblock, diagramlink, diagramtypes,
  LMessages, GL, glu, GLext, dialogs, StdCtrls, ExtCtrls;

type
  TDiagram=class(TCustomControl)
  private
    blocks: TList;
    links: TList;
    draggedblock: record
      block: TDiagramBlock;
      point: TPoint;
    end;

    draggedPoint: record
      link: TDiagramLink;
      pointindex: integer;
    end;

    draggedSideAttachPoint: record
      block: TDiagramBlock;
      link: TDiagramLink;
    end;

    resizing: record
      block: TDiagramBlock;
      side: TDiagramBlockSide;
    end;

    fAllowUserToCreatePlotPoints: boolean;
    fAllowUserToMovePlotPoints: boolean;
    fAllowUserToResizeBlocks: boolean;
    fAllowUserToMoveBlocks: boolean;
    fAllowUserToChangeAttachPoints: boolean;

    osb: TBitmap;

    //ogl
    fUseOpenGL: boolean;
    hglrc: HGLRC;
    fzoom: single;

    diagramConfig: TDiagramConfig;

    scrollbarbottompanel: TPanel;
    hscrollbar: TScrollBar;
    vscrollbar: TScrollbar;

    procedure scrollbarchange(sender: TObject);
    procedure NotifyBlockDestroy(sender: TObject);
    procedure updateBlockDragPosition(xpos,ypos: integer);
    procedure updateResizePosition(xpos,ypos: integer);
    procedure updatePointDragPosition(xpos,ypos: integer);
    procedure updateAttachPointDragPosition(xpos,ypos: integer);
    function getLineThickness: integer;
    procedure setLineThickness(t: integer);
    function getLineColor: TColor;
    procedure setLineColor(c: tcolor);
    function getDrawPlotPoints: boolean;
    procedure setDrawPlotPoints(state: boolean);
    function getPlotPointColor: TColor;
    procedure setPlotPointColor(c: tcolor);

    function getArrowStyles: TArrowStyles;
    procedure setArrowStyles(s: TArrowStyles);

    function getBlockBackground: TColor;
    procedure setBlockBackground(c: TColor);

    function getBackgroundColor: TColor;
    procedure setBackGroundColor(c: TColor);

    function getBlockCount: integer;
    function getBlock(index: integer): TDiagramBlock;
    function getLinkCount: integer;
    function getLink(index: integer): TDiagramLink;

    function getScrollX: integer;
    procedure setScrollX(x: integer);
    function getScrollY: integer;
    procedure setScrollY(y: integer);


    procedure setUseOpenGl(state: boolean);

    procedure DoAutoSideUpdate;
    procedure RepaintOrRender;
  protected
   // procedure WMPaint(var Message: TLMPaint); message LM_PAINT;
    procedure paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure WMLButtonDBLCLK(var Message: TLMLButtonDblClk); message LM_LBUTTONDBLCLK;


    procedure updateScrollbars(maxx,maxy: integer); virtual;

    procedure SetParent(NewParent: TWinControl); override;
    //procedure DblClick; override;
  public
    function createBlock: TDiagramBlock;
    function addConnection(origin, destination: TDiagramBlockSideDescriptor): TDiagramLink; overload;
    function addConnection(originBlock, destinationBlock: TDiagramBlock): TDiagramLink; overload;
    procedure getConnectionsToBlock(b: TDiagramBlock; list: TList);
    procedure getConnectionsFromBlock(b: TDiagramBlock; list: TList);
    procedure render;

    property Block[index: integer]: TDiagramBlock read getBlock;
    property Link[index: integer]:TDiagramLink read getLink;

    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  published
    property ScrollX: integer read getScrollX write setScrollX;
    property ScrollY: integer read getScrollY write setScrollY;
    property LineThickness: integer read getLineThickness write setLineThickness;
    property LineColor: Tcolor read getLineColor write setLineColor;
    property DrawPlotPoints: boolean read getDrawPlotPoints write setDrawPlotPoints;
    property PlotPointColor: TColor read getPlotPointColor write setPlotPointColor;
    property AllowUserToCreatePlotPoints: boolean read fAllowUserToCreatePlotPoints write fAllowUserToCreatePlotPoints;
    property AllowUserToMovePlotPoints: boolean read fAllowUserToMovePlotPoints write fAllowUserToMovePlotPoints;
    property AllowUserToResizeBlocks: boolean read fAllowUserToResizeBlocks write fAllowUserToResizeBlocks;
    property AllowUserToMoveBlocks: boolean read fAllowUserToMoveBlocks write fAllowUserToMoveBlocks;
    property AllowUserToChangeAttachPoints: boolean read fallowUserToChangeAttachPoints write fallowUserToChangeAttachPoints;

    property ArrowStyles: TArrowStyles read getArrowStyles write setArrowStyles;
    property BlockBackground: TColor read getBlockBackground write setBlockBackground;
    property BackGroundColor: TColor read getBackGroundColor write setBackGroundColor;

    property BlockCount: integer read getBlockCount;

    property LinkCount: integer read getLinkCount;
    property UseOpenGL: boolean read fUseOpenGL write setUseOpenGL;


    property Canvas;
    property OnPaint;
    property Align;
    property Anchors;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnEnter;
    property OnExit;
    property OnClick;
    property OnDblClick;
    property OnContextPopup;
    property PopupMenu;
    property ShowHint;
    property OnShowHint;
    property Parent;
  end;

implementation

uses math, GraphType, Forms;

function TDiagram.getPlotPointColor: TColor;
begin
  result:=diagramConfig.PlotPointColor;
end;

procedure TDiagram.setPlotPointColor(c: tcolor);
begin
  diagramConfig.PlotPointColor:=c;
  if parent<>nil then
    repaintOrRender;
end;

function TDiagram.getArrowStyles: TArrowStyles;
begin
  result:=diagramConfig.ArrowStyles;
end;

procedure TDiagram.setArrowStyles(s: TArrowStyles);
begin
  diagramConfig.ArrowStyles:=s;
  if parent<>nil then
    repaintOrRender;
end;

function TDiagram.getDrawPlotPoints: boolean;
begin
  result:=diagramConfig.drawPlotPoints;
end;

procedure TDiagram.setDrawPlotPoints(state: boolean);
begin
  diagramConfig.drawPlotPoints:=state;
  if parent<>nil then
    repaintOrRender;
end;

function TDiagram.getLineColor: tcolor;
begin
  result:=diagramConfig.LineColor;
end;

procedure TDiagram.setLineColor(c: tcolor);
begin
  diagramConfig.linecolor:=c;
  if parent<>nil then
    repaintOrRender;
end;

function TDiagram.getLineThickness: integer;
begin
  result:=diagramConfig.LineThickness;
end;

procedure TDiagram.setLineThickness(t: integer);
begin
  diagramConfig.LineThickness:=t;
  if parent<>nil then
    repaintOrRender;
end;

function TDiagram.getBlockBackground: TColor;
begin
  result:=diagramConfig.BlockBackground;
end;

procedure TDiagram.setBlockBackground(c: TColor);
begin
  diagramConfig.BlockBackground:=c;
  if parent<>nil then
    repaintOrRender;
end;

function TDiagram.getBackgroundColor: TColor;
begin
  result:=diagramConfig.backgroundColor;
end;

procedure TDiagram.setBackGroundColor(c: TColor);
begin
  diagramConfig.backgroundColor:=c;
  if parent<>nil then
    repaintOrRender;
end;

function TDiagram.getBlockCount: integer;
begin
  result:=blocks.Count;
end;

function TDiagram.getBlock(index: integer): TDiagramBlock;
begin
  if (index>=0) and (index<blocks.count) then
    result:=TDiagramBlock(blocks[index])
  else
    result:=nil;
end;

function TDiagram.getLinkCount: integer;
begin
  result:=links.Count;
end;

function TDiagram.getLink(index: integer): TDiagramLink;
begin
  if (index>=0) and (index<links.count) then
    result:=TDiagramLink(links[index])
  else
    result:=nil;
end;

function TDiagram.getScrollX: integer;
begin
  if UseOpenGL then
    result:=0
  else
    result:=hscrollbar.Position;
end;

procedure TDiagram.setScrollX(x: integer);
begin
  hscrollbar.Position:=x;
  RepaintOrRender;
end;

function TDiagram.getScrollY: integer;
begin
  if useOpenGL then
    result:=0
  else
    result:=vscrollbar.Position;
end;

procedure TDiagram.setScrollY(y: integer);
begin
  vscrollbar.position:=y;
  RepaintOrRender;
end;



procedure TDiagram.DoAutoSideUpdate;
var
  i,j,k: integer;
  b: TDiagramBlock;
  l: TDiagramLink;

  sides: array [0..3] of array of record
    link: TDiagramLink;
    destp: TPoint;
    slope: double;
    bsd: TDiagramBlockSideDescriptor;
  end;

  s1,s2: TDiagramBlockSideDescriptor;
  destination: TDiagramBlockSideDescriptor;

  dp: tpoint;
  op: tpoint;

  bsd: TDiagramBlockSideDescriptor;

  closestSide: TDiagramBlockSide;
  closestSideDistance: double;
  closestPoint: TPoint;

  distance: double;

  dx,dy: integer;
  inserted: boolean;

  slope: double;

  procedure insertAt(arrayindex: integer; index: integer);
  var ind: integer;
  begin
    setlength(sides[arrayindex],length(sides[arrayindex])+1);
    for ind:=length(sides[arrayindex])-1 downto index+1 do
      sides[arrayindex][ind]:=sides[arrayindex][ind-1];

    sides[arrayindex][index].destp:=closestpoint;
    sides[arrayindex][index].slope:=slope;
    sides[arrayindex][index].bsd:=bsd;
    sides[arrayindex][index].link:=l;

    inserted:=true;
  end;
begin
  for i:=0 to blocks.count-1 do
  begin
    b:=TDiagramBlock(blocks[i]);


    if b.AutoSide then
    begin
      for j:=0 to 3 do
        setlength(sides[j],0);

      for j:=0 to links.count-1 do
      begin
        l:=TDiagramLink(links[j]);

        if l.hasLinkToBlock(b) then
        begin
          destination.block:=nil;

          s1:=l.getOriginDescriptor;
          s2:=l.getDestinationDescriptor;
          if b=s1.Block then
          begin
            //origin->destination
            if l.getPointCount>0 then
              dp:=l.getPoint(0)
            else
              destination:=s2
          end
          else
          begin
            //destination->origin
            if l.getPointCount>0 then
              dp:=l.getpoint(l.getpointcount-1)
            else
              destination:=s1;
          end;

          if destination.block<>nil then
          begin
            if destination.block.autoside then
              destination:=destination.block.getClosestSideDescriptor(b.x+b.Width div 2,b.y+b.height div 2);

            dp:=destination.block.getConnectPosition(destination.side,destination.sideposition);
          end;

          if b.AutoSideDistance<0 then //just directly
          begin
            bsd:=b.getClosestSideDescriptor(dp.x,dp.y);
            l.updateSide(bsd)
          end
          else
          begin
            //center of sides only , pick the closest one
            closestside:=dbsTop;
            closestPoint:=b.getConnectPosition(dbstop);
            closestSideDistance:=closestPoint.Distance(dp);

            op:=b.getConnectPosition(dbsRight);
            distance:=op.Distance(dp);
            if distance<closestSideDistance then
            begin
              closestSide:=dbsRight;
              closestSideDistance:=distance;
              closestPoint:=op;
            end;

            op:=b.getConnectPosition(dbsBottom);
            distance:=op.Distance(dp);
            if distance<closestSideDistance then
            begin
              closestSide:=dbsBottom;
              closestSideDistance:=distance;
              closestPoint:=op;
            end;

            op:=b.getConnectPosition(dbsLeft);
            distance:=op.Distance(dp);
            if distance<closestSideDistance then
            begin
              closestSide:=dbsLeft;
              closestSideDistance:=distance;
              closestpoint:=op;
            end;

            bsd.block:=b;
            bsd.side:=closestSide;
            bsd.sideposition:=0; //set the position after checking number of lines

            l.updateSide(bsd);

            //find the best location in this array
            //based on the slope of the line
            dx:=dp.x-closestPoint.x;
            dy:=dp.y-closestpoint.y;

            inserted:=false;

            case closestSide of  //pick an array index
              dbsTop:
              begin
                //top:
                if dy=0 then
                  slope:=99999999
                else
                  slope:=(-dx)/dy;

                for k:=0 to length(sides[0])-1 do
                begin
                  if slope<sides[0][k].slope then
                  begin
                    insertAt(0,k);
                    break;
                  end;
                end;
                if not inserted then
                  insertAt(0,length(sides[0]));
              end;

              dbsRight:
              begin
                if dx=0 then
                  slope:=99999999
                else
                  slope:=dy/dx;

                for k:=0 to length(sides[1])-1 do
                begin
                  if slope<sides[1][k].slope then
                  begin
                    insertAt(1,k);
                    break;
                  end;
                end;
                if not inserted then
                  insertAt(1,length(sides[1]));
              end;

              dbsBottom:
              begin
                if dy=0 then
                  slope:=99999999
                else
                  slope:=dx/dy;

                for k:=0 to length(sides[2])-1 do
                begin
                  if slope<sides[2][k].slope then
                  begin
                    insertAt(2,k);
                    break;
                  end;
                end;
                if not inserted then
                  insertAt(2,length(sides[2]));
              end;

              dbsLeft:
              begin
                if dx=0 then
                  slope:=99999999
                else
                  slope:=(-dy)/dx;

                for k:=0 to length(sides[3])-1 do
                begin
                  if slope<sides[3][k].slope then
                  begin
                    insertAt(3,k);
                    break;
                  end;
                end;
                if not inserted then
                  insertAt(3,length(sides[3]));
              end;
            end;
          end; //autodistance<>0
        end; //haslinktoblock
      end; //link enum

      //all links have been enumerated and sorted

      if b.AutoSideDistance>=0 then
      begin
        //calculate which line comes in front of which one
        for j:=0 to 3 do
        begin
          for k:=0 to length(sides[j])-1 do
          begin
            sides[j][k].bsd.sideposition:=trunc((b.AutoSideDistance*k) - ((b.AutoSideDistance*(length(sides[j])-1)) / 2));
            sides[j][k].link.updateSide(sides[j][k].bsd);
          end;

        end;
      end;
    end;
  end;

end;

var ScrollbarchangeLock: boolean;
procedure TDiagram.scrollbarchange(sender: TObject);
begin
  if ScrollbarchangeLock then exit;

  ScrollbarchangeLock:=true;
  RepaintOrRender;
  ScrollbarchangeLock:=false;
end;

procedure TDiagram.NotifyBlockDestroy(sender: TObject);
var
  l: TDiagramLink;
  b: TDiagramBlock;
  i: integer;
begin
  if sender is TDiagramBlock then
  begin
    //delete links that pointed to this block
    b:=TDiagramBlock(sender);

    i:=0;
    if links<>nil then
    begin
      while i<links.count do
      begin
        l:=TDiagramLink(links[i]);
        if l.hasLinkToBlock(b) then
        begin
          l.free;
          links.Delete(i);
        end
        else
          inc(i);
      end;
    end;
  end;
end;

procedure TDiagram.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  i: integer;
  b:TDiagramBlock;
  side: TDiagramBlockSide;
  l: TDiagramLink;

  bsd: TDiagramBlockSideDescriptor;

  pointindex: integer;

  startedresizing: boolean;
begin
  inherited mousedown(Button, Shift, X,Y);

  inc(x,scrollx);
  inc(y,scrolly);


  startedresizing:=false;
  for i:=blocks.count-1 downto 0 do
  begin
    b:=TDiagramBlock(blocks[i]);
    if fAllowUserToMoveBlocks and b.IsInsideHeader(x,y) then
    begin
      draggedBlock.Block:=b;
      draggedBlock.Point:=point(x-b.x,y-b.y);
      exit;
    end
    else
    if allowUserToResizeBlocks and b.IsAtBorder(x,y,side) then
    begin
      resizing.block:=b;
      resizing.side:=side;
      startedresizing:=true; //just gotta check the lines first

      if allowUserToChangeAttachPoints then
        break
      else
        exit;
    end;
  end;

  for i:=links.count-1 downto 0 do
  begin
    l:=TDiagramLink(links[i]);

    if AllowUserToMovePlotPoints then
    begin
      PointIndex:=l.getPointIndexAt(x,y);
      if pointindex<>-1 then
      begin
        draggedPoint.Link:=l;
        draggedPoint.PointIndex:=PointIndex;
        exit;
      end;
    end;

    if allowUserToChangeAttachPoints and l.isAtAttachPoint(x,y, bsd) then
    begin
      if startedresizing then resizing.block:=nil; //nope, attachpoint changing takes priority
      draggedSideAttachPoint.block:=bsd.block;
      draggedSideAttachPoint.link:=l;
      exit;
    end;

    if allowUserToCreatePlotPoints and l.isOverLine(x,y) then
    begin
      l.createPoint(point(x,y));

      pointindex:=l.getPointIndexAt(x,y);
      if pointindex<>-1 then
      begin
        draggedPoint.Link:=l;
        draggedPoint.PointIndex:=pointindex;
      end;

      repaintOrRender;

      exit;
    end;
  end;


end;

procedure TDiagram.updateAttachPointDragPosition(xpos,ypos: integer);
var b: TDiagramBlockSideDescriptor;
begin
  //get the nearest attachpoint
  b:=draggedSideAttachPoint.block.getClosestSideDescriptor(xpos,ypos);
  if b.block=nil then exit; //don't update

  draggedSideAttachPoint.link.updateSide(b);

  repaintOrRender;
end;

procedure TDiagram.updateBlockDragPosition(xpos,ypos: integer);
begin
  draggedBlock.Block.x:=xpos-draggedBlock.point.x;
  draggedBlock.Block.y:=ypos-draggedBlock.point.y;
  DoAutoSideUpdate;
  repaintOrRender;
end;

procedure TDiagram.updatePointDragPosition(xpos,ypos: integer);
begin
  if draggedPoint.link<>nil then
  begin
    draggedPoint.link.updatePointPosition(draggedPoint.pointindex, point(xpos,ypos));
    DoAutoSideUpdate;
    repaintOrRender;


  end;
end;

procedure TDiagram.updateResizePosition(xpos,ypos: integer);
begin
  if resizing.block=nil then exit;

  resizing.block.Resize(xpos,ypos,resizing.side);
  DoAutoSideUpdate;
  repaintOrRender;
end;

procedure TDiagram.updateScrollbars(maxx,maxy: integer);
var
  vwasvisible: boolean;
  hwasvisible: boolean;
begin
  vwasvisible:=vscrollbar.visible;
  hwasvisible:=scrollbarbottompanel.visible;

  vscrollbar.visible:=maxy>height-hscrollbar.Height;
  scrollbarbottompanel.visible:=maxx>width-vscrollbar.width;

  vscrollbar.PageSize:=height-hscrollbar.height;
  hscrollbar.pagesize:=width-vscrollbar.width;

  vscrollbar.LargeChange:=vscrollbar.PageSize div 2;
  hscrollbar.LargeChange:=hscrollbar.PageSize div 2;

  vscrollbar.SmallChange:=diagramconfig.canvas.GetTextWidth('XXX');
  hscrollbar.SmallChange:=vscrollbar.SmallChange;

  vscrollbar.Max:=maxy;
  hscrollbar.max:=maxx;


  if vscrollbar.visible and scrollbarbottompanel.visible then
  begin
    //both visible
    vscrollbar.AnchorSideBottom.control:=scrollbarbottompanel;
    vscrollbar.AnchorSideBottom.side:=asrTop;

    hscrollbar.BorderSpacing.Right:=vscrollbar.width;


  end
  else
  begin
    //only one or none visible
    if scrollbarbottompanel.visible then
    begin
      hscrollbar.BorderSpacing.right:=0;
    end
    else
    if vscrollbar.visible then
    begin
      vscrollbar.AnchorSideBottom.control:=self;
      vscrollbar.AnchorSideBottom.side:=asrBottom;
    end;
  end;

  if vwasvisible and (vscrollbar.visible=false) then
    vscrollbar.Position:=0;

  if hwasvisible and (scrollbarbottompanel.visible=false) then
    hscrollbar.Position:=0;
end;

procedure TDiagram.WMLButtonDBLCLK(var Message: TLMLButtonDblClk);
var
  i: integer;
  pt: tpoint;
begin
  inherited WMLButtonDBLCLK(message);

  pt := GetMousePosFromMessage(Message.Pos);
  inc(pt.x,scrollx);
  inc(pt.y,scrolly);

  for i:=blocks.count-1 downto 0 do
  begin
    if TDiagramBlock(blocks[i]).isInside(pt.x,pt.y) then
    begin
      TDiagramBlock(blocks[i]).DblClick(pt.x,pt.y);
      exit;
    end;
  end;


end;

procedure TDiagram.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited mouseup(Button, Shift, X,Y);

  inc(x,scrollx);
  inc(y,scrolly);

  if draggedblock.block<>nil then
  begin
    updateBlockDragPosition(x,y);
    draggedBlock.block:=nil;
  end;

  if resizing.block<>nil then
  begin
    updateResizePosition(x,y);
    resizing.block:=nil;
  end;

  if draggedpoint.link<>nil then
  begin
    updatePointDragPosition(x,y);
    draggedpoint.link:=nil;
  end;

  if draggedSideAttachPoint.link<>nil then
  begin
    updateAttachPointDragPosition(x,y);
    draggedSideAttachPoint.link:=nil;
    draggedSideAttachPoint.block:=nil;
  end;


end;

procedure TDiagram.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  i: integer;
  b: TDiagramBlock;
  borderside: TDiagramBlockSide;
  bsd: TDiagramBlockSideDescriptor;
  l: TDiagramLink;

  newcursor: TCursor;
begin
  inherited mousemove(Shift, X,Y);

  //adjust for scroll
  inc(x,scrollx);
  inc(y,scrolly);

  newcursor:=crdefault;

  if draggedblock.block<>nil then
    updateBlockDragPosition(x,y);

  if resizing.block<>nil then
    updateResizePosition(x,y);

  if draggedPoint.link<>nil then
    updatePointDragPosition(x,y);

  if draggedSideAttachPoint.link<>nil then
    updateAttachPointDragPosition(x,y);


  //check if the mouse is over a block
  for i:=blocks.count-1 downto 0 do
  begin
    b:=TDiagramBlock(blocks[i]);
    if AllowUserToMoveBlocks and b.IsInsideHeader(x,y) then
    begin
      newcursor:=crHandPoint;
      break;
    end
    else
    if AllowUserToResizeBlocks and b.IsAtBorder(x,y,borderside) then
    begin
      case borderside of
        dbsTopLeft:     newcursor:=crSizeNW;
        dbsTop:         newcursor:=crSizeN;
        dbsTopRight:    newcursor:=crSizeNE;
        dbsRight:       newcursor:=crSizeE;
        dbsBottomRight: newcursor:=crSizeSE;
        dbsBottom:      newcursor:=crSizeS;
        dbsBottomLeft:  newcursor:=crSizeSW;
        dbsLeft:        newcursor:=crSizeW;
      end;
      break;
    end;
  end;

  //check if over a line
  for i:=links.count-1 downto 0 do
  begin
    l:=TDiagramLink(links[i]);
    if AllowUserToMovePlotPoints and (l.getPointIndexAt(x,y)<>-1) then
    begin
      newcursor:=crSize;
      break;
    end;


    if AllowUserToCreatePlotPoints and l.isOverLine(x,y) then
    begin
      newcursor:=crCross;

      if allowUserToChangeAttachPoints and l.isAtAttachPoint(x,y,bsd) then
        newcursor:=crSize;

      break;
    end;
  end;

  if newcursor<>cursor then
    cursor:=newcursor;
end;

procedure TDiagram.setUseOpenGl(state: boolean);
var
  pfd: TPixelFormatDescriptor;
  i: integer;
begin
  fUseOpenGL:=state;

  if state and (parent<>nil) then //already has a parent so canvas is usable
  begin
    hglrc:=wglCreateContext(canvas.handle);

    if hglrc=0 then
    begin
      pfd.nSize:=sizeof(pfd);
      pfd.nVersion:=1;
      pfd.dwFlags:=PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
      pfd.iPixelType:=PFD_TYPE_RGBA;
      pfd.cColorBits:=24;
      pfd.cRedBits:=0;
      pfd.cRedShift:=0;
      pfd.cGreenBits:=0;
      pfd.cGreenShift:=0;
      pfd.cBlueBits:=0;
      pfd.cBlueShift:=0;
      pfd.cAlphaBits:=0;
      pfd.cAlphaShift:=0;
      pfd.cAccumBits:=0;
      pfd.cAccumRedBits:=0;
      pfd.cAccumGreenBits:=0;
      pfd.cAccumBlueBits:=0;
      pfd.cAccumAlphaBits:=0;
      pfd.cDepthBits:=16;
      pfd.cStencilBits:=0;
      pfd.cAuxBuffers:=0;
      pfd.iLayerType:=PFD_MAIN_PLANE;
      pfd.bReserved:=0;
      pfd.dwLayerMask:=0;
      pfd.dwVisibleMask:=0;
      pfd.dwDamageMask:=0;

      i:=ChoosePixelFormat(canvas.handle, @pfd);
      SetPixelFormat(canvas.handle, i, @pfd);

      hglrc:=wglCreateContext(canvas.handle);
    end;

    if hglrc=0 then
      fUseOpenGL:=false;
  end;
end;

procedure TDiagram.SetParent(NewParent: TWinControl);
var
  oldparent: TWinControl;
  pfd: TPixelFormatDescriptor;
  i: integer;
begin
  oldparent:=parent;
  inherited SetParent(NewParent);

  diagramConfig.canvas:=canvas;


  if UseOpenGL and assigned(ChoosePixelFormat) and (NewParent<>nil) and (oldparent=nil) then
  begin
    hglrc:=wglCreateContext(canvas.handle);

    if hglrc=0 then
    begin
      pfd.nSize:=sizeof(pfd);
      pfd.nVersion:=1;
      pfd.dwFlags:=PFD_DRAW_TO_WINDOW or PFD_SUPPORT_OPENGL or PFD_DOUBLEBUFFER;
      pfd.iPixelType:=PFD_TYPE_RGBA;
      pfd.cColorBits:=24;
      pfd.cRedBits:=0;
      pfd.cRedShift:=0;
      pfd.cGreenBits:=0;
      pfd.cGreenShift:=0;
      pfd.cBlueBits:=0;
      pfd.cBlueShift:=0;
      pfd.cAlphaBits:=0;
      pfd.cAlphaShift:=0;
      pfd.cAccumBits:=0;
      pfd.cAccumRedBits:=0;
      pfd.cAccumGreenBits:=0;
      pfd.cAccumBlueBits:=0;
      pfd.cAccumAlphaBits:=0;
      pfd.cDepthBits:=16;
      pfd.cStencilBits:=0;
      pfd.cAuxBuffers:=0;
      pfd.iLayerType:=PFD_MAIN_PLANE;
      pfd.bReserved:=0;
      pfd.dwLayerMask:=0;
      pfd.dwVisibleMask:=0;
      pfd.dwDamageMask:=0;

      i:=ChoosePixelFormat(canvas.handle, @pfd);
      SetPixelFormat(canvas.handle, i, @pfd);

      hglrc:=wglCreateContext(canvas.handle);
    end;
  end;
end;

procedure TDiagram.RepaintOrRender;
begin
  if UseOpenGL then render else repaint;
end;

procedure TDiagram.render;
var
  i: integer;
  b: TDiagramBlock;
  maxw,maxh: integer;
  p: pbyte;

  rid: TRawImageDescription;
  iw: integer;
  maxx,maxy: integer;
begin
  color:=diagramConfig.backgroundColor;

  if useopengl and (hglrc<>0) then
  begin
    wglMakeCurrent(canvas.handle, hglrc);
    maxw:=10;
    maxh:=10;
    for i:=0 to blocks.count-1 do
    begin
      b:=TDiagramBlock(blocks[i]);
      maxw:=max(maxw,b.x+b.Width);
      maxh:=max(maxh,b.y+b.height);
    end;

    if osb=nil then
    begin
      osb:=tbitmap.Create;
      osb.PixelFormat:=pf24bit;
    end;

    osb.canvas.brush.Assign(canvas.brush);
    osb.canvas.pen.assign(canvas.pen);
    osb.canvas.Font.assign(canvas.font);


    if osb.width<maxw then
      osb.width:=system.align(osb.width+256,64);

    if osb.height<maxh then
      osb.height:=system.align(osb.height+256,64);

    //todo: only redraw OSB when something has actually changed

    osb.canvas.brush.color:=diagramConfig.backgroundColor;
    osb.canvas.FillRect(0,0,osb.width,osb.height);
//    osb.Canvas.Clear;

    diagramConfig.canvas:=osb.Canvas;
  end
  else
  begin
    diagramconfig.canvas:=canvas;
  end;

  diagramconfig.scrollx:=ScrollX;
  diagramconfig.scrolly:=ScrollY;


  maxx:=width-hscrollbar.Width;
  maxy:=height-vscrollbar.Height;

  //draw the lines
  for i:=0 to links.count-1 do
  begin
    TDiagramLink(links[i]).render;
    maxx:=max(maxx, TDiagramLink(links[i]).maxx);
    maxy:=max(maxy, TDiagramLink(links[i]).maxy);
  end;


  //draw the visible blocks
  for i:=0 to blocks.count-1 do
  begin
    TDiagramBlock(blocks[i]).render;
    maxx:=max(maxx, TDiagramBlock(blocks[i]).x+TDiagramBlock(blocks[i]).width);
    maxy:=max(maxy, TDiagramBlock(blocks[i]).y+TDiagramBlock(blocks[i]).height);
  end;

  if useopengl and (hglrc<>0) then
  begin
    glPixelTransferf(GL_ALPHA_SCALE, 0.0);
    glPixelTransferf(GL_ALPHA_BIAS,  1.0);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glClearIndex(0.0);
    glClear(GL_COLOR_BUFFER_BIT);

   // glPixelTransferi(GL_MAP_COLOR, GL_FALSE);

    glDisable(GL_DITHER);
    glShadeModel(GL_FLAT);
    glClearColor(0.0, 0.0, 0.5, 0.5);
    glClearDepth(1.0);
    //glEnable(GL_DEPTH_TEST);
    glDisable(GL_DITHER);
    //glDepthFunc(GL_LEQUAL);
    //glHint(GL_PERSPECTIVE_CORRECTION_HINT,GL_NICEST);

    glViewport(0, 0, Width, Height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();

    gluOrtho2D(0, width, height,0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity;

    gluLookAt (0.0, 0.0, 0.0,
               0.0, 1.0, 0.0,
               0.0, 0.0, -1.0);

    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();

    glViewport(0, 0, width, height);
    glPixelZoom(fzoom,-fzoom);
    glRasterPos2f(0,0);

    p:=osb.RawImage.Data;

    rid:=osb.RawImage.Description;
    iw:=osb.width;

    glDrawPixels(osb.width, osb.height, GL_BGR,GL_UNSIGNED_BYTE, p);
    //glDrawPixels(20,20,GL_BGR,GL_UNSIGNED_BYTE, @fck[0]);
    //end;
    SwapBuffers(canvas.handle);

    wglMakeCurrent(0,0);
  end;

  updateScrollbars(maxx,maxy);
end;


procedure TDiagram.paint;
begin
  inherited paint;

  render;


end;

function TDiagram.createBlock: TDiagramBlock;
var b: TDiagramBlock;
begin
  b:=TDiagramBlock.create(diagramConfig);
  b.OnDestroy:=@NotifyBlockDestroy;
  blocks.Add(b);

  result:=b;
end;

function TDiagram.addConnection(originBlock, destinationBlock: TDiagramBlock): TDiagramLink;
var
  o,d: TDiagramBlockSideDescriptor;
  l: TDiagramlink;
begin
  originblock.AutoSide:=true;
  destinationblock.autoside:=true;

  o.block:=originBlock;
  o.side:=dbsTop;
  o.sideposition:=0;

  d.block:=destinationblock;
  d.side:=dbsTop;
  d.sideposition:=0;
  l:=TDiagramLink.create(diagramConfig,o, d);

  links.add(l);
  result:=l;
end;

function TDiagram.addConnection(origin, destination: TDiagramBlockSideDescriptor): TDiagramLink;
var l: TDiagramLink;
begin
  l:=TDiagramLink.create(diagramConfig,origin, destination);
  links.add(l);

  result:=l;
end;

procedure TDiagram.getConnectionsToBlock(b: TDiagramBlock; list: TList);
var
  i: integer;
begin
  for i:=0 to links.count-1 do
    if TdiagramLink(links[i]).getDestinationDescriptor.block=b then
      list.add(links[i]);
end;

procedure TDiagram.getConnectionsFromBlock(b: TDiagramBlock; list: TList);
var
  i: integer;
begin
  for i:=0 to links.count-1 do
    if TdiagramLink(links[i]).getOriginDescriptor.block=b then
      list.add(links[i]);
end;

constructor TDiagram.Create(TheOwner: TComponent);
begin
  inherited create(TheOwner);

  diagramConfig:=TDiagramConfig.create(self);

  blocks:=tlist.create;
  links:=tlist.create;

  fAllowUserToCreatePlotPoints:=true;
  fAllowUserToMovePlotPoints:=true;
  fAllowUserToResizeBlocks:=true;
  fAllowUserToMoveBlocks:=true;
  fAllowUserToChangeAttachPoints:=true;

  fzoom:=1;

  scrollbarbottompanel:=tpanel.Create(self);
  scrollbarbottompanel.BevelOuter:=bvNone;
  scrollbarbottompanel.align:=alBottom;
  scrollbarbottompanel.parent:=self;
  scrollbarbottompanel.color:=clBtnFace;

  hscrollbar:=TScrollBar.Create(self);
  hscrollbar.Parent:=scrollbarbottompanel;
  hscrollbar.AnchorSideLeft.Control:=scrollbarbottompanel;
  hscrollbar.anchorsideLeft.Side:=asrLeft;
  hscrollbar.AnchorSideTop.Control:=scrollbarbottompanel;
  hscrollbar.anchorsideTop.Side:=asrTop;
  hscrollbar.AnchorSideRight.Control:=scrollbarbottompanel;
  hscrollbar.anchorsideRight.Side:=asrRight;
  hscrollbar.Anchors:=[akLeft, akTop, akRight];
  scrollbarbottompanel.autosize:=true;

  vscrollbar:=TScrollBar.Create(self);
  vscrollbar.kind:=sbVertical;
  vscrollbar.Parent:=self;
  vscrollbar.AnchorSideTop.Control:=self;
  vscrollbar.anchorsideTop.Side:=asrTop;
  vscrollbar.AnchorSideRight.Control:=self;
  vscrollbar.anchorsideRight.Side:=asrRight;
  vscrollbar.AnchorSideBottom.Control:=scrollbarbottompanel;
  vscrollbar.anchorsideBottom.Side:=asrTop;

  vscrollbar.Anchors:=[akTop, akRight, akBottom];


  hscrollbar.BorderSpacing.Right:=hscrollbar.Height;

  //scrollx:=10;

  hscrollbar.OnChange:=@scrollbarchange;
  vscrollbar.OnChange:=@scrollbarchange;


end;

destructor TDiagram.Destroy;
var i: integer;
begin
  for i:=0 to links.count-1 do
    TDiagramLink(links[i]).free;

  links.free;
  links:=nil;

  for i:=0 to blocks.count-1 do
    TDiagramBlock(blocks[i]).free;

  blocks.Free;
  blocks:=nil;

  inherited destroy;
end;

end.

