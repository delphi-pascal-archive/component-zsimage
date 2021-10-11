{ - - - - - - - - - - - - - -
      ZSIMAGE
    auteur : ThWilliam
      date : 26/02/2010
  - - - - - - - - - - - - - - }



unit ZSImage;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Forms, Menus, Typinfo, Math, Jpeg; 


type
   TzsiSelectionForm = (sfRectangle, sfEllipse);
   TzsiSelectionType = (stResizeable, stNotResizeable, stMagnetic);
   TzsiMouseDownUpEvent = procedure(Button: TMouseButton; Shift: TShiftState; X, Y: integer) of object;
   TzsiMouseMoveEvent = procedure(Shift: TShiftState; X, Y: integer) of object;

   // effets pour le SlideShow
   // les effets utilisant AnimateWindow doivent s'intituler se_aw_...
   TzsiSlideShowEffects = (se_Blend, se_MiddleToTopBottom, se_MiddleToLeftRight, se_aw_Center, se_aw_Left, se_aw_LeftSlide, se_aw_Right, se_aw_RightSlide,
                        se_aw_Top, se_aw_TopSlide, se_aw_Bottom, se_aw_BottomSlide,
                        se_aw_TopLeft, se_aw_TopLeftSlide, se_aw_TopRight, se_aw_TopRightSlide,
                        se_aw_BottomLeft, se_aw_BottomLeftSlide, se_aw_BottomRight, se_aw_BottomRightSlide);

   TZSImage = class;

   TzsiSlideShow = class; // classe gérant le SlideShow

   TzsiSlideShowList = class(TStringList)  // liste des noms de fichier pour le SlideShow
   private
     FOwner: TzsiSlideShow;
   public
      constructor Create(AOwner: TzsiSlideShow);
      destructor Destroy; override;
      procedure Clear; override;
      procedure Assign(Source: TPersistent); override;
      procedure DeleteObject(Index: integer);
      procedure Delete(Index: Integer); override;
   end;

   TzsiAWPanel = class(TCustomControl) // panel utilisé pour les AnimateWindow
   private
      FBitmap: TBitmap;
      procedure WMEraseBkgnd(var Message: TMessage); message WM_ERASEBKGND;
   protected
      procedure Paint; override;
   public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
   end;

   TzsiSlideShowThread = class(TThread)  // thread pour chargement image dans le SlideShow
   private
      FOwner: TzsiSlideShow;
      FIndex: integer;
      procedure OnEnd(Sender: TObject);
   protected
      procedure Execute; override;
   public
      constructor Create(AOwner: TzsiSlideShow; AIndex: integer);
   end;


   TzsiSlideShow = class(TPersistent)
   private
      FOwner: TZSImage;
      FImgList: TzsiSlideShowList;  // liste des fichiers
      FImgIndex: integer;           // index de l'image en cours dans la liste
      FEffect: TzsiSlideShowEffects;  // effet de transition entre images
      FEffectOnShow: boolean;  // true = produit l'effet pour la nouvelle image
      FEffectOnHide: boolean;  // true = produit l'effet pour l'image actuelle
      FEffectTimeOnShow: DWord;  // temps d'apparition en millionièmes de seconde
      FEffectTimeOnHide: DWord;  // temps de disparition en millionièmes de seconde
      FThread: TzsiSlideShowThread; // thread pour le chargement des images
      FLoadingFile: boolean; // true = thread en cours de chargement d'un fichier
      procedure DoBlend;
      procedure Do_AW_Effect(AEffect: TzsiSlideShowEffects);
      procedure DoCustomEffects(AEffect: TzsiSlideShowEffects);
      procedure SetEffectTimeOnShow(AValue: DWord);
      procedure SetEffectTimeOnHide(AValue: DWord);
   public
      constructor Create(AOwner: TZSImage);
      destructor Destroy; override;
      procedure ShowImage(AIndex : integer; KeepNext: integer = 0; KeepPrevious: integer = 0);
      property List: TzsiSlideShowList read FImgList write FImgList;
      property ImageIndex: integer read FImgIndex;
      property LoadingFile: boolean read FLoadingFile;
      function RandomEffect: TzsiSlideShowEffects;
   published
      property Effect: TzsiSlideShowEffects read FEffect write FEffect default se_Blend;
      property EffectOnShow: boolean read FEffectOnShow write FEffectOnShow default false;
      property EffectOnHide: boolean read FEffectOnHide write FEffectOnHide default false;
      property EffectTimeOnShow: DWord read FEffectTimeOnShow write SetEffectTimeOnShow default 500;
      property EffectTimeOnHide: DWord read FEffectTimeOnHide write SetEffectTimeOnHide default 300;
   end;


  TzsiSelection = class(TCustomControl) // sélection
  private
    FOwner: TzsImage;
    FActivated: boolean;
    FSelRect: TRect;
    FSelectionType: TzsiSelectionType;
    FSelectionForm: TzsiSelectionForm;
    FCursorOnDrawSel: TCursor;
    FCursorOnMoveSel: TCursor;
    FFrameWidth: byte;
    SelectionState: integer;
    OrigCoordX, OrigCoordY: integer;
    function PosOnSelRect(X,Y: integer): integer;
    procedure ChangeSelRect(NewX, NewY, OldX, OldY: integer);
    procedure DrawSelFrame;
    function InverseRect(R: TRect): TRect;
    procedure ChangeCursor;
    procedure WMEraseBkgnd(var Message: TMessage); message WM_ERASEBKGND;
    procedure SetActivated(AValue: boolean);
    procedure SetSelectionForm(AValue: TzsiSelectionForm);
    procedure SetFrameWidth(AValue: byte);
    procedure SetCursorOnDrawSel(AValue: TCursor);
    function  GetSelRect: TRect;
    procedure SetSelRect(AValue: TRect);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Activated: boolean read FActivated write SetActivated default false;
    property SelectionType: TzsiSelectionType read FSelectionType write FSelectionType default stResizeable;
    property SelectionForm: TzsiSelectionForm read FSelectionForm write SetSelectionForm default sfRectangle;
    property FrameWidth: byte read FFrameWidth write SetFrameWidth default 1;
    property CursorOnDrawSel: TCursor read FCursorOnDrawSel write SetCursorOnDrawSel default crCross;
    property CursorOnMoveSel: TCursor read FCursorOnMoveSel write FCursorOnMoveSel default crHandPoint;
    property SelectedRect: TRect read GetSelRect write SetSelRect;
    function SelectionExist: boolean;
    function SelectionAvailable: boolean;
    procedure Deselect;
    property PopUpMenu;
  end;

  TZSImage = class(TCustomControl)
  private
    FOrigBmp: TBitmap;  // bitmap taille originale
    FOrigBmpRect: TRect; // zone de l'image originale qui est affichée à l'écran
    FCanvasBmp: TBitmap;  // bitmap qui a la taille du composant (comprend les marges et la bordure de l'image)
    FCanvasBmpRect: TRect; // coordonnées de l'image écran (c.à.d. sans les marges et la bordure)
    FMargin: word;  // marge écran lorsque l'image est entièrement affichée
    FBkgColor: TColor;  // couleur du fond de l'image
    FBorderColor: TColor;  // couleur du contour du bitmap
    FBorderWidth: word;    // épaisseur du contour
    FEnlarge: boolean;     // false : pas d'agrandissement du bitmap si < taille de TZSImage
    FMagnifierActivated: boolean; // active ou désactive la fonction loupe
    FMagnifierFactor: double;  // 1= taille réelle  0.5 = 50%...
    FMagnifierSize: integer;  // 0 = loupe plein écran, sinon = diamètre de l'ellipse loupe
    FOldMagnifierRect: TRect;   // mémorise la zone précédemment zoomée
    FMagnifierCursor: TCursor;  // curseur lorsque la loupe est Activated
    FDefaultCursor: TCursor; // curseur par défaut
    FStretchFactor: double; // facteur d'affichage de l'image : 0 = taille écran, 1= taille réelle,  0.5 = 50% ...
    FKeyToScroll: integer; // touche clavier à maintenir enfoncée pour pouvoir défiler dans l'image
    FSlideShow: TzsiSlideShow;
    FSelection: TzsiSelection;
    FOnSlideShowEffect: TNotifyEvent;
    FSelectionMouseDown: TzsiMouseDownUpEvent;
    FSelectionMouseUp: TzsiMouseDownUpEvent;
    FSelectionMouseMove: TzsiMouseMoveEvent;
    FSelRectChange: TNotifyEvent;
    OrigMousePoint: TPoint;
    procedure SetMagnifierActivated(AValue: boolean);
    procedure DoScroll(X, Y: integer);
    procedure SetStretchFactor(AValue: double);
  protected
    procedure Paint; override;
    procedure ChangeCursor(ACursor: TCursor);
    procedure WndProc(var Message: TMessage); override;
    procedure StretchFromPoint(SourceBmp, DestBmp: TBitmap; Center: TPoint; AStretchFactor: double; var SourceRect, DestRect: TRect);
    procedure InternSetImage(Source: TPersistent; MustRepaint: boolean);
    procedure ImageChanged;
    procedure DoMagnify(X, Y: integer);
    function CallPopUpMenu(Pop: TPopUpMenu): boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure SetImage(Source: TPersistent); overload;
    procedure SetImage(FileName: string); overload;
    procedure StretchImage; overload;
    procedure StretchImage(ACenter: TPoint); overload;
    property OrigBitmap: TBitmap read FOrigBmp;
    property Selection: TzsiSelection read FSelection write FSelection;
    property CanvasBitmap: TBitmap read FCanvasBmp;
    function GetSelection(var AOrigRect, AStretchRect: TRect): boolean;
    procedure ResizeImage;
    procedure Clear;
    function GetScale: double;
    procedure UpdateRect(AOrigRect, AStretchRect: TRect);
    property Canvas;
  published
    property BkgColor: TColor read FBkgColor write FBkgColor default clgray;
    property BorderColor: TColor read FBorderColor write FBorderColor default clBlack;
    property BorderWidth: word read FBorderWidth write FBorderWidth default 0;
    property Enlarge: boolean read FEnlarge write FEnlarge default false;
    property Margin: word read FMargin write FMargin default 0;
    property CanvasBitmapRect: TRect read FCanvasBmpRect;
    property OrigBitmapRect: TRect read FOrigBmpRect;
    property SlideShow: TzsiSlideShow read FSlideShow write FSlideShow;
    property DefaultCursor: TCursor read FDefaultCursor write FDefaultCursor default crArrow;
    property MagnifierFactor: double read FMagnifierFactor write FMagnifierFactor;
    property MagnifierCursor: TCursor read FMagnifierCursor write FMagnifierCursor default crArrow;
    property MagnifierActivated: boolean read FMagnifierActivated write SetMagnifierActivated default false;
    property MagnifierSize: integer read FMagnifierSize write FMagnifierSize default 0;
    property KeyToScroll: integer read FKeyToScroll write FKeyToScroll default VK_SPACE;
    property StretchFactor: double read FStretchFactor write SetStretchFactor;
    property OnSlideShowEffect: TNotifyEvent read FOnSlideShowEffect write FOnSlideShowEffect;
    property OnSelectionMouseDown: TzsiMouseDownUpEvent read  FSelectionMouseDown write FSelectionMouseDown;
    property OnSelectionMouseUp: TzsiMouseDownUpEvent read  FSelectionMouseUp write FSelectionMouseUp;
    property OnSelectionMouseMove: TzsiMouseMoveEvent read FSelectionMouseMove write FSelectionMouseMove;
    property OnSelectionChange: TNotifyEvent read FSelRectChange write FSelRectChange;
    property Align;
    property Anchors;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Hint;
    property ParentShowHint;
    property PopUpMenu;
    property ShowHint;
    property Tag;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnStartDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

  TMinNavigation = class(TGraphicControl) // miniature de OrigBitmap permettant la navigation
  private
    FMinBmp: TBitmap;
    FImage: TZSIMage;
    FColor: TColor;
    FBorderColor: TColor;
    FMinRect: TRect;
    FOffset: integer;
    FScale: double;
    procedure Execute(X, Y: integer);
    procedure SetColor(AValue: TColor);
    procedure SetBorderColor(AValue: TColor);
  protected
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property MiniatureRect: TRect read FMinRect;
    procedure UpdateMiniature;
    procedure Clear;
  published
    property Image: TZSImage read FImage write FImage;
    property Color: TColor read FColor write SetColor default clWhite;
    property BorderColor: TColor read FBorderColor write SetBorderColor default clBlack;
    property Cursor;
   end;


   procedure Register;



implementation

const
   NULLPOINT = -65000;
   CENTERPOINT: TPoint = (X: -65000; Y: -65000);
   EFFECTMAXTIME = 2400; // time maximum pour slideshow effets


procedure Register;
begin
  RegisterComponents('Exemples', [TZSImage, TMinNavigation]);
end;


function LoadImagefromFile(AFileName: string; ABitmap: TBitmap): boolean;
// fonction utilisée pour l'ouverture d'un fichier image
// ABitmap doit être préalablement créé.
// ne provoque pas d'erreur si le fichier ne peut être ouvert, mais renvoie false
// si erreur : ABitmap servira à afficher l'erreur
var
  Ext: string;
  Jpeg: TJpegImage;
  Picture: TPicture;
  R: TRect;
begin
   Ext:= AnsiLowerCase(ExtractFileExt(AFileName));
   if (Ext = '.jpg') or (Ext = '.jpeg') or (Ext = '.jpe') then
   begin
      Jpeg:= TJpegImage.Create;
      try
         try
            Jpeg.LoadFromFile(AFileName);
            ABitmap.Assign(JPeg);
         except
         end;
      finally
        Jpeg.Free;
      end;
   end
   else
   begin
      Picture:= TPicture.Create;
      try
         try
            Picture.LoadFromFile(AFileName);
            if (Ext = '.wmf') or (Ext = '.emf') then
            begin
               ABitmap.Width:= Picture.MetaFile.Width;
               ABitmap.Height:= Picture.MetaFile.Height;
               ABitmap.Canvas.Draw(0, 0, Picture.Metafile);
            end
            else
            if Ext = '.ico' then
            begin
               ABitmap.Width:= Picture.Icon.Width;
               ABitmap.Height:= Picture.Icon.Height;
               ABitmap.Canvas.Draw(0, 0, Picture.Icon);
            end
            else
            begin
              ABitmap.Assign(Picture.Graphic);
            end;
         except
         end;
      finally
         Picture.Free;
      end;
   end;
   Result:= not(ABitmap.Empty);
   if not Result then
   with ABitmap do
   begin
      Width:= 300;
      Height:= 300;
      Canvas.Brush.Color:= clBlack;
      Canvas.FillRect(Rect(0, 0, Width, Height));
      Canvas.Font.Color:= clRed;
      Canvas.Font.Style:= [fsBold];
      Canvas.Brush.Style:= bsClear;
      R:= Rect(10, 120, Width - 10, 150);
      DrawText(Canvas.handle, 'Erreur à l''ouverture du fichier:', -1, R, DT_CENTER);
      R:= Rect(10, 170, Width - 10, 200);
      DrawText(Canvas.handle, PChar(AFileName), -1, R, DT_CENTER or DT_PATH_ELLIPSIS);
   end;
end;

procedure Wait(Microseconds: int64); // sert de chrono pour effets slideshow
var
  Start: int64;

                 function MyGetTickCount: Int64; // chrono au millionième de seconde
                // function de Michel Bardou sur www.phidels.com
                 var lpPerformanceCount, Frequency: TLargeInteger;
                 begin
                    if not QueryPerformanceCounter(lpPerformanceCount) then
                    begin // il n'y a pas d'horloge haute précision sur l'ordi
                       Result:=GetTickCount * 1000;
                    end
                    else
                    begin  // il y en a une
                       QueryPerformanceFrequency(Frequency);
                       Result:=(lpPerformanceCount*1000000) div Frequency;
                    end;
                 end;
begin
   Start:= MyGetTickCount;
   while (MyGetTickCount - Start) < MicroSeconds do begin end;
end;


function ExCopyRect(Dest: TCanvas; DestRect: Trect; Source: TCanvas; SourceRect: Trect): boolean;
begin
   SetStretchBltMode(Dest.Handle, HALFTONE);
   Result:= StretchBlt(Dest.Handle,
                      DestRect.Left, DestRect.Top, DestRect.Right - DestRect.Left, DestRect.Bottom - DestRect.Top,
                      Source.Handle,
                      SourceRect.Left, SourceRect.Top, SourceRect.Right - SourceRect.Left, SourceRect.Bottom - SourceRect.Top,
                      SRCCOPY);
end;

function RectIsEqual(R1, R2: Trect): boolean;
// renvoie true si les 2 Rect sont identiques
begin
   Result:= ((R1.Left = R2.Left) and (R1.Top = R2.Top)
             and (R1.Right = R2.Right) and (R1.Bottom = R2.Bottom));
end;

function WidthOfRect(R: Trect): integer;
// renvoie la largeur d'un TRect
begin
   Result:= R.Right - R.Left + 1;
end;

function HeightOfRect(R: Trect): integer;
// renvoie la hauteur d'un TRect
begin
   Result:= R.Bottom - R.Top + 1;
end;



{ ----------------------------------------------------------------
                  TzsiSlideShowList
  ---------------------------------------------------------------- }

constructor TzsiSlideShowList.Create(AOwner: TzsiSlideShow);
begin
   inherited Create;
   FOwner:= AOwner;
end;

destructor TzsiSlideShowList.Destroy;
begin
   Clear;
   inherited Destroy;
end;

procedure TzsiSlideShowList.Clear;
var
   I: integer;
begin
   for I:= 0 to Count - 1 do DeleteObject(I);
   FOwner.FImgIndex:= -1;
   inherited Clear;
end;

procedure TzsiSlideShowList.Assign(Source: TPersistent);
begin
   Clear;
   inherited Assign(Source);
end;

procedure TzsiSlideShowList.DeleteObject(Index: integer);
begin
   try
      if Objects[Index] <> nil then
      begin
         (Objects[Index] as TBitmap).Free;
         Objects[Index]:= nil;
      end;
   except
   end;
end;

procedure TzsiSlideShowList.Delete(Index: Integer);
begin
   DeleteObject(Index);
   inherited Delete(Index);
end;


{ ----------------------------------------------------------------
                     TzsiAWPanel
  ---------------------------------------------------------------- }

constructor TzsiAWPanel.Create(AOwner: TComponent);
var
  FOwner: TZSImage;
begin
   inherited Create(nil);
   FOwner:= AOwner as TZSImage;
   FBitmap:= TBitmap.Create;
   FBitmap.Assign(FOwner.FCanvasBmp);
   Parent:= FOwner.Parent;
   SetBounds(FOwner.Left, FOwner.Top, FOwner.Width, FOwner.Height);
end;

destructor TzsiAWPanel.Destroy;
begin
   FBitmap.Free;
   inherited Destroy;
end;

procedure TzsiAWPanel.Paint;
begin
  if FBitmap <> nil then Canvas.Draw(0,0,FBitmap);
end;

procedure TzsiAWPanel.WMEraseBkgnd(var Message: TMessage);
begin
  Message.Result:= 1;
end;


{ ----------------------------------------------------------------
                       TzsiSlideShowThread
  ---------------------------------------------------------------- }

constructor TzsiSlideShowThread.Create(AOwner: TzsiSlideShow; AIndex: integer);
begin
  inherited Create(true);
  FOwner:= AOwner;
  FOwner.FLoadingFile:= true;
  FIndex:= AIndex;
  priority:= tpHighest;
  FreeOnTerminate:= true;
  OnTerminate:= OnEnd;
  Resume;
end;

procedure TzsiSlideShowThread.Execute;
var
  Bmp: TBitmap;
begin
   Bmp:= TBitmap.Create;
   try
     LoadImageFromFile(FOwner.FImgList[FIndex], Bmp);
     FOwner.FImgList.Objects[FIndex]:= Bmp;
   except
     Bmp.Free;
   end;
end;

procedure TzsiSlideShowThread.OnEnd(Sender: TObject);
begin
   FOwner.FLoadingFile:= false;
end;


{ ----------------------------------------------------------------
                       TzsiSlideShow
  ---------------------------------------------------------------- }


constructor TzsiSlideShow.Create(AOwner: TZSImage);
begin
   inherited Create;
   FOwner:= AOwner;
   FEffect:= se_Blend;
   FEffectTimeOnShow:= 500;
   FEffectTimeOnHide:= 300;
   FEffectOnShow:= false;
   FEffectOnHide:= false;
   FImgList:= TzsiSlideShowList.Create(Self);
   FImgIndex:= -1;
   FLoadingFile:= false;
end;

destructor TzsiSlideShow.Destroy;
begin
   FImgList.Free;
   inherited Destroy;
end;

procedure TzsiSlideShow.SetEffectTimeOnShow(AValue: DWord);
begin
  if AValue > EFFECTMAXTIME then AValue:= EFFECTMAXTIME;
  FEffectTimeOnShow:= AValue;
end;

procedure TzsiSlideShow.SetEffectTimeOnHide(AValue: DWord);
begin
  if AValue > EFFECTMAXTIME then AValue:= EFFECTMAXTIME;
  FEffectTimeOnHide:= AValue;
end;

procedure TzsiSlideShow.DoBlend;
// procedure adaptée à partir du code de Cirec. Merci à lui.
var
   Blend: TBLENDFUNCTION;
   SrcBmp: TBitmap;
   DestBmp: TBitmap;
   BigBmp: TBitmap;
   I, Freq: Integer;
   ATime: DWord;
   NotDC: HDC;
  begin
    SrcBmp := TBitmap.Create;
    SrcBmp.Width  := FOwner.Width;
    SrcBmp.Height := FOwner.Height;
    DestBmp := TBitmap.Create;
    DestBmp.Width:= FOwner.Width;
    DestBmp.Height:= FOwner.Height;
    BigBmp:= TBitmap.Create;
    BigBmp.Assign(FImgList.Objects[FImgIndex] as TBitmap);
    FOwner.StretchFromPoint(BigBmp, DestBmp,
                            CENTERPOINT,
                            FOwner.FStretchFactor,
                            FOwner.FOrigBmpRect, FOwner.FCanvasBmpRect);
    NotDC := GetWindowDC(FOwner.Handle);
    try
      SrcBmp.Canvas.Brush.Handle := CreatePatternBrush(DestBmp.handle);
      SrcBmp.Canvas.FillRect(FOwner.ClientRect);
      DestBmp.Canvas.Brush.Handle := CreatePatternBrush(FOwner.FCanvasBmp.Handle);
      ZeroMemory(@Blend, SizeOf(Blend));
      I := 1;
      ATime:= FEffectTimeOnShow;
      if ATime = 0 then ATime:= 1;
      Freq := (EFFECTMAXTIME - ATime) div ATime + 1;
      if Freq <= 0 then Freq:= 1;
      with DestBmp do
      repeat
        Inc(I, Freq);
        If I > 255 Then I := 255;
        Canvas.FillRect(FOwner.ClientRect);
        Blend.SourceConstantAlpha := I;
        AlphaBlend(Canvas.Handle, 0, 0, Width, Height, SrcBmp.Canvas.Handle, 0, 0, SrcBmp.Width, SrcBmp.Height, Blend);
        BitBlt(NotDC, 0, 0, Width, Height, Canvas.Handle, 0, 0, srcCopy);
      until I >= 255;
    finally
      with FOwner do
      begin
         OrigBitmap.Assign(BigBmp);
         FCanvasBmp.Assign(DestBmp);
      end;
      BigBmp.Free;
      DestBmp.Free;
      SrcBmp.Free;
      ReleaseDC(FOwner.Handle, NotDC);
      AnimateWindow(FOwner.Handle, FEffectTimeOnShow, AW_ACTIVATE or AW_Blend);
    end;
end;

procedure TzsiSlideShow.Do_AW_Effect(AEffect: TzsiSlideShowEffects);
// effets avec AnimateWindow
                     function GetFlags: DWord;
                     begin
                       case AEffect of
                           se_aw_Left: Result:= AW_HOR_POSITIVE;
                           se_aw_LeftSlide: Result:= AW_HOR_POSITIVE or AW_SLIDE;
                           se_aw_Right: Result:= AW_HOR_NEGATIVE;
                           se_aw_RightSlide: Result:= AW_HOR_NEGATIVE or AW_SLIDE;
                           se_aw_Top: Result:= AW_VER_POSITIVE;
                           se_aw_TopSlide: Result:= AW_VER_POSITIVE or AW_SLIDE;
                           se_aw_Bottom: Result:= AW_VER_NEGATIVE;
                           se_aw_BottomSlide: Result:= AW_VER_NEGATIVE or AW_SLIDE;
                           se_aw_TopLeft: Result:= AW_HOR_POSITIVE or AW_VER_POSITIVE;
                           se_aw_TopLeftSlide: Result:= AW_HOR_POSITIVE or AW_VER_POSITIVE or AW_SLIDE;
                           se_aw_TopRight: Result:= AW_HOR_NEGATIVE or AW_VER_POSITIVE;
                           se_aw_TopRightSlide: Result:= AW_HOR_NEGATIVE or AW_VER_POSITIVE or AW_SLIDE;
                           se_aw_BottomLeft: Result:= AW_HOR_POSITIVE or AW_VER_NEGATIVE;
                           se_aw_BottomLeftSlide: Result:= AW_HOR_POSITIVE or AW_VER_NEGATIVE or AW_SLIDE;
                           se_aw_BottomRight: Result:= AW_HOR_NEGATIVE or AW_VER_NEGATIVE;
                           se_aw_BottomRightSlide: Result:= AW_HOR_NEGATIVE or AW_VER_NEGATIVE or AW_SLIDE;
                       else
                         Result:= AW_CENTER;
                       end;
                     end;


var
  TempBmp: TBitmap;
  Flags: DWord;
  AWPanel: TzsiAWPanel;
begin
   Flags:= GetFlags;
   with FOwner do
      if FCanvasBmp.Empty then
      begin
         AnimateWindow(Handle, 0, AW_HIDE or AW_VER_NEGATIVE);
         InternSetImage(FImgList.Objects[FImgIndex] as TBitmap, false);
         Brush.Handle:= CreatePatternBrush(FCanvasBmp.Handle);
         AnimateWindow(Handle, FEffectTimeOnShow, AW_ACTIVATE or Flags);
         Exit;
      end;
   if FEffectOnShow and FEffectOnHide then
   begin
      TempBmp:= TBitmap.Create;
      try
          with FOwner do
          begin
             FOrigBmp.Assign(FImgList.Objects[FImgIndex] as TBitmap);
             StretchFromPoint(FOrigBmp, TempBmp, CENTERPOINT,
                              FStretchFactor, FOrigBmpRect, FCanvasBmpRect);
             Brush.Handle:= CreatePatternBrush(FCanvasBmp.Handle);
             AnimateWindow(Handle, FEffectTimeOnHide, AW_HIDE or Flags);
             FCanvasBmp.Assign(TempBmp);
             AnimateWindow(Handle, FEffectTimeOnShow, AW_ACTIVATE or Flags);
          end;
      finally
         TempBmp.Free;
      end;
   end
   else if FEffectOnShow then
   begin
      AWPanel:= TzsiAWPanel.Create(FOwner);
      try
         AWPanel.FBitmap.Assign(FOwner.FCanvasBmp);
         AWPanel.BringToFront;
         with FOwner do
         begin
            AnimateWindow(Handle, 0, AW_HIDE or AW_HOR_NEGATIVE);
            InternSetImage(FImgList.Objects[FImgIndex] as TBitmap, true);
            Brush.Handle:= CreatePatternBrush(FCanvasBmp.Handle);
            AnimateWindow(Handle, FEffectTimeOnShow, AW_ACTIVATE or Flags);
         end;
      finally
         AWPanel.Free;
      end;
   end
   else if FEffectOnHide then
   begin
      AWPanel:= TzsiAWPanel.Create(FOwner);
      try
         AWPanel.BringToFront;
         FOwner.InternSetImage(FImgList.Objects[FImgIndex] as TBitmap, true);
         AWPanel.Brush.Handle:= CreatePatternBrush(AWPanel.FBitmap.Handle);
         AnimateWindow(AWPanel.Handle, FEffectTimeOnHide, AW_HIDE or Flags);
      finally
         AWPanel.Free;
      end;
   end;
end;

procedure TzsiSlideShow.DoCustomEffects(AEffect: TzsiSlideShowEffects);
var
  X, Y, C: integer;
begin
   case AEffect of
      // découverte à partir du milieu vers bords haut et bas
      se_MiddleToTopBottom: with FOwner do
                     begin
                         InternSetImage(FImgList.Objects[FImgIndex] as TBitmap, false);
                         C:= Height div 2;
                         if FEffectOnHide and FEffectOnShow then
                         begin
                            Canvas.Brush.Color:= FOwner.FBkgColor;
                            for Y:= 0 to C do
                            begin
                               Canvas.FillRect(Rect(0, Y, Width, Y + 1));
                               Canvas.FillRect(Rect(0, Height - Y, Width, Height - Y + 1));
                               Wait(FEffectTimeOnHide);
                            end;
                         end
                         else
                         if FEffectOnHide then
                         begin
                            for Y:= 0 to C do
                            begin
                              Canvas.CopyRect(Rect(0, Y, Width, Y + 1), FCanvasBmp.Canvas, Rect(0, Y, Width, Y + 1));
                              Canvas.CopyRect(Rect(0, Height - Y, Width, Height - Y + 1), FCanvasBmp.Canvas, Rect(0, Height - Y, Width, Height - Y + 1));
                              Wait(FEffectTimeOnHide);
                            end;
                         end;
                         if FEffectOnShow then
                            for Y:= 0 to C do
                            begin
                               Canvas.CopyRect(Rect(0, C - Y, Width, C - Y + 1), FCanvasBmp.Canvas,Rect(0, C - Y, Width, C - Y + 1));
                               Canvas.CopyRect(Rect(0, C + Y, Width, C + Y + 1), FCanvasBmp.Canvas,Rect(0, C + Y, Width, C + Y + 1));
                               Wait(FEffectTimeOnShow);
                            end;
                     end;
          // découverte à partir du milieu vers bords gauche et droit
          se_MiddleToLeftRight: with FOwner do
                     begin
                        InternSetImage(FImgList.Objects[FImgIndex] as TBitmap, false);
                        C:= Width div 2;
                        if FEffectOnHide and FEffectOnShow then
                         begin
                            Canvas.Brush.Color:= FOwner.FBkgColor;
                            for X:= 0 to C do
                            begin
                               Canvas.FillRect(Rect(X, 0, X + 1, Height));
                               Canvas.FillRect(Rect(Width - X, 0, Width - X + 1, Height));
                               Wait(FEffectTimeOnHide);
                            end;
                         end
                         else
                         if FEffectOnHide then
                         begin
                            for X:= 0 to C do
                            begin
                              Canvas.CopyRect(Rect(X, 0, X + 1, Height), FCanvasBmp.Canvas, Rect(X, 0, X + 1, Height));
                              Canvas.CopyRect(Rect(Width - X, 0, Width - X + 1, Height), FCanvasBmp.Canvas, Rect(Width - X, 0, Width - X + 1, Height));
                              Wait(FEffectTimeOnHide);
                            end;
                         end;
                         if FEffectOnShow then
                            for X:= 0 to C do
                            begin
                               Canvas.CopyRect(Rect(C - X, 0, C - X + 1, Height), FCanvasBmp.Canvas, Rect(C - X, 0, C - X + 1, Height));
                               Canvas.CopyRect(Rect(C + X, 0, C + X + 1, Height), FCanvasBmp.Canvas, Rect(C + X, 0, C + X + 1, Height));
                               Wait(FEffectTimeOnShow);
                            end;
                     end;
   end; // of case
end;


function TzsiSlideShow.RandomEffect: TzsiSlideShowEffects;
var
  Max: Word;
begin
   Randomize;
   Max:= Word(High(TzsiSlideShowEffects));
   Result:= TzsiSlideShowEffects(Random(Max) + 1);
end;


procedure TzsiSlideShow.ShowImage(AIndex : integer; KeepNext: integer = 0; KeepPrevious: integer = 0);
// AIndex = index dans la liste des fichiers
// KeepNext = nombre d'images suivant AIndex à garder (si elles ont été chargées !)
//            si > 0 : l'image suivante est au besoin chargée dans un thread séparé
// KeepPrevious = nombre d'images précédant AIndex à garder
// Si KeepNext et Keepprevious = -1 : c'est au programme de gérer lui-même la destruction pour libérer de la mémoire
var
  Bmp: TBitmap;
  I: integer;
begin
   if (AIndex < 0) or (AIndex >= FImgList.Count) then Exit;
   while FLoadingFile do Application.ProcessMessages; // thread en cours
   FImgIndex:= AIndex;
   if FImgList.Objects[FImgIndex] = nil then
   begin
      Bmp:= TBitmap.Create;
      LoadImageFromFile(FImgList[FImgIndex], Bmp);
      FImgList.Objects[FImgIndex]:= Bmp;
   end;

   with FOwner do if Assigned(FOnSlideShowEffect) then FOnSlideShowEffect(Self);

   if FEffectOnShow or FEffectOnHide then
   begin
      if FEffect = se_Blend then DoBlend
      else
      if Pos('se_aw_', GetEnumName(typeInfo(TzsiSlideShowEffects),integer(FEffect))) > 0 then
           Do_AW_Effect(FEffect)
      else
           DoCustomEffects(FEffect);
   end
   else
      FOwner.InternSetImage(FImgList.Objects[FImgIndex] as TBitmap, true);

   FOwner.ImageChanged;

   if KeepNext > 0 then
   begin
      while FLoadingFile do Application.ProcessMessages;
      I:= FImgIndex + 1;
      if I < FImgList.Count then
         if FImgList.Objects[I] = nil then // on prépare la photo suivante dans un thread séparé
            FThread:= TzsiSlideShowThread.Create(Self, I);
   end;
   if KeepPrevious > - 1 then
   begin
      if KeepPrevious > 0 then Inc(KeepPrevious); // afin de garder aussi l'image actuelle
      for I:= 0 to FImgIndex - KeepPrevious do   // suppression des images précédentes
         if FImgList.Objects[I] <> nil then FImgList.DeleteObject(I);
   end;
   if KeepNext > - 1 then
      for I:= FImgIndex + KeepNext + 1 to  FImgList.Count - 1 do
         if FImgList.Objects[I] <> nil then FImgList.DeleteObject(I); // suppression des images suivantes
end;



{ ----------------------------------------------------------------
                       TzsiSelection
  ---------------------------------------------------------------- }

constructor TzsiSelection.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   FOwner:= AOwner as TzsImage;
   FActivated:= false;
   Visible:= false;
   FSelRect:= Rect(NULLPOINT, NULLPOINT, NULLPOINT, NULLPOINT);
   FSelectionType:= stResizeable;
   FSelectionForm:= sfRectangle;
   FFrameWidth:= 1;
   FCursorOnDrawSel:= crCross;
   FCursorOnMoveSel:= crHandPoint;
   SelectionState:= -1;
end;

procedure TzsiSelection.CreateParams(var Params: TCreateParams);
begin
   inherited CreateParams(Params);
   ControlStyle := ControlStyle + [csNoDesignVisible];
end;

procedure TzsiSelection.WMEraseBkgnd(var Message: TMessage);
begin
  Message.Result:= 1; // pas d'effacement du fond
end;


procedure TzsiSelection.Paint;
begin
  Canvas.Draw(0,0,FOwner.FCanvasBmp);
  if SelectionExist then
    DrawSelFrame;
end;

procedure TzsiSelection.SetActivated(AValue: boolean);
begin
   if FActivated = AValue then Exit;
   FActivated:= AValue;
   if FActivated then
   begin
      Cursor:= FCursorOnDrawSel;
      Visible:= true;
      BringToFront;
   end
   else Visible:= false;
end;

procedure TzsiSelection.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if FOwner.FCanvasBmp.Empty then Exit;
  if Button = mbRight then
  begin
     if FOwner.CallPopUpMenu(PopUpMenu) then
        PopUpMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y)
     else
     if (ssAlt in Shift) then Deselect; // supprime toute sélection
  end
  else
  if Button = mbLeft then
  begin
     if GetKeyState(FOwner.FKeyToScroll) < 0 then
     begin // scroll dans ZSImage
        FOwner.OrigMousePoint:= Point(X, Y);
        SetActivated(false);
        Exit;
     end;
     if SelectionExist and (SelectionType <> stMagnetic) and (PosOnSelRect(X, Y) < 0) then Deselect;
     if not SelectionExist then
     begin
        OrigCoordX:= X;
        OrigCoordY:= Y;
        SelectionState:= 0;
     end;
     ChangeCursor;
     if Assigned(FOwner.FSelectionMouseDown) then FOwner.FSelectionMouseDown(Button, Shift, X, Y);
  end;
end;


procedure TzsiSelection.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
   if FOwner.FCanvasBmp.Empty then Exit;
   if (ssLeft in Shift) and (GetKeyState(FOwner.FKeyToScroll) < 0) then
   begin  // scroll dans ZSImage
      FOwner.DoScroll(X,Y);
      Exit;
   end;
   if ((Shift = [ssLeft]) and (SelectionState >= 0)) or ((FSelectionType = stMagnetic) and SelectionExist) then
   begin
      DrawSelFrame;  //pour effacer l'ancien rectangle de sélection
      if (FSelectionType = stMagnetic) and (SelectionState <> 0) then
          SelectionState:= 10;
      ChangeCursor;
      if FSelRect.Left = NULLPOINT then FSelRect.Left:= OrigCoordX;
      if FSelRect.Top = NULLPOINT then FSelRect.Top:= OrigCoordY;
      ChangeSelRect(X, Y, OrigCoordX, OrigCoordY); // calcul du nouveau rectangle de sélection
      DrawSelFrame;  //Dessin du nouveau cadre de sélection
   end
   else
   if SelectionExist then
   begin
      SelectionState:= PosOnSelRect(X,Y); // voir la position de la souris sur le cadre
      ChangeCursor;
   end;
   OrigCoordX:= X;
   OrigCoordY:= Y;
   if Assigned(FOwner.FSelectionMouseMove) then FOwner.FSelectionMouseMove(Shift, X, Y);
end;


procedure TzsiSelection.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P: TPoint;
begin
  if not(FActivated) then SetActivated(true);
  if SelectionExist then
  begin
      FSelRect:= InverseRect(FSelRect);
      if (FSelectionType = stMagnetic) and (SelectionState = 0) then
      begin
         with FSelRect do   // calcul du centre de la sélection
         begin
            P.X:= Left + ((Right - Left) div 2);
            P.Y:= Top + ((Bottom - Top) div 2);
         end;
         P:= ClientToScreen(P); // conversion des coordonnées client en coordonnées écran
         SetCursorPos(P.X, P.Y); // on place le curseur au centre de la sélection
         SelectionState:= 10;
         ChangeCursor;
      end;
  end;
  if Assigned(FOwner.FSelectionMouseUp) then FOwner.FSelectionMouseUp(Button, Shift, X, Y);
end;


function TzsiSelection.PosOnSelRect(X,Y: integer): integer;
const
   L = 2; // latitude de position souris
var
   P: TPoint;
begin
   P:= Point(X, Y);
   with FSelRect do
      if (FSelectionType = stNotResizeable) and (PtInRect(Rect(Left - L, Top - L, Right + L +1, Bottom + L +1), P)) then Result:= 9
      else
      if PtInRect(Rect(Left - L, Top - L, Left + L + 1, Top + L + 1), P) then Result:= 1
      else
      if PtInRect(Rect(Left + L +1, Top - L, Right - L, Top + L + 1), P) then Result:= 2
      else
      if PtInRect(Rect(Right - L, Top - L, Right + L + 1, Top + L + 1), P) then Result:= 3
      else
      if PtInRect(Rect(Right - L, Top + L +1, Right + L + 1, Bottom - L), P) then Result:= 4
      else
      if PtInRect(Rect(Right - L, Bottom - L, Right + L + 1, Bottom + L + 1), P) then Result:= 5
      else
      if PtInRect(Rect(Left + L +1, Bottom - L, Right - L, Bottom + L + 1), P) then Result:= 6
      else
      if PtInRect(Rect(Left - L, Bottom - L, Left + L + 1, Bottom + L + 1), P) then Result:= 7
      else
      if PtInRect(Rect(Left - L, Top + L +1, Left + L + 1, Bottom - L), P) then Result:= 8
      else
      if PtInRect(Rect(Left + L +1, Top + L + 1, Right - L, Bottom - L), P) then Result:= 9
      else Result:= -1;
end;


procedure TzsiSelection.SetCursorOnDrawSel(AValue: TCursor);
begin
  FCursorOnDrawSel:= AValue;
  ChangeCursor;
end;


procedure TzsiSelection.ChangeCursor;
var
  NewCursor: TCursor;
begin
  case SelectionState of
      -1, 0: NewCursor:= FCursorOnDrawSel;
        1,5: NewCursor:= crSizeNWSE;
        2,6: NewCursor:= crSizeNS;
        3,7: NewCursor:= crSizeNESW;
        4,8: NewCursor:= crSizeWE;
          9: NewCursor:= FCursorOnMoveSel;
       else
          NewCursor:= crNone;
  end;
  if Cursor <> NewCursor then Cursor:= NewCursor;
end;


procedure TzsiSelection.ChangeSelRect(NewX, NewY, OldX, OldY: integer);
var
  W, H: integer;
begin
  with FSelRect do
  begin
      W:= Right - Left;
      H:= Bottom - Top;
      case SelectionState of
         0 : begin    // sélection en cours de création
                Right:= NewX;
                Bottom:= NewY;
             end;
         1 : begin   //resize par coin supérieur gauche
                Left:=  Left + NewX - OldX;
                Top:= Top + NewY - OldY;
             end;
         2 : Top:= Top + NewY - OldY;  // resize par ligne horizontale top
         3 : begin   // resize par coin supérieur droit
                Right:=  Right + NewX - OldX;
                Top:= Top + NewY - OldY;
             end;
         4 : Right:=  Right + NewX - OldX;  // resize par ligne verticale droite
         5 : begin   // resize par coin inférieur droit
                Right:=  Right + NewX - OldX;
                Bottom:= Bottom + NewY - OldY;
             end;
         6 : Bottom:= Bottom + NewY - OldY;  // resize par ligne horizontale bottom
         7 : begin    // resize par coin inférieur gauche
                Left:=  Left + NewX - OldX;
                Bottom:= Bottom + NewY - OldY;
             end;
         8 : Left:=  Left + NewX - OldX;   //resize par ligne verticale gauche
         9 : begin   // déplacement sans resize
                Left:=  Left + NewX - OldX;
                Top:= Top + NewY - OldY;
                Right:= Left + W;
                Bottom:= Top + H;
             end;
         10: begin   // déplacement d'une sélection magnétique
                Left:= NewX - (W div 2);
                Right:= Left + W;
                Top:= NewY - (H div 2);
                Bottom:= Top + H;
             end;
      end;
      //On vérifie si le rectangle ne sort pas des limites de ZSImage
      if Left < 0 then
      begin
         Left := 0;
         if SelectionState >= 9 then Right:= Left + W;
      end
      else if Left >= Width then Left:= Width - 1;
      if Top < 0 then
      begin
         Top := 0;
         if SelectionState >= 9 then Bottom:= Top + H;
      end
      else if Top >= Height then Top:= Height - 1;
      if Right >= Width then
      begin
         Right := Width - 1;
         if SelectionState >= 9 then Left:= Right - W;
      end
      else if Right < 0 then Right:= 0;
      if Bottom >= Height then
      begin
         Bottom := Height - 1;
         if SelectionState >= 9 then Top:= Bottom - H;
      end
      else if Bottom < 0 then Bottom:= 0;
  end;
  if Assigned(FOwner.FSelRectChange) then FOwner.FSelRectChange(Self);
end;


procedure TzsiSelection.DrawSelFrame;
// dessin du cadre de sélection
var
  R: TRect;
begin
   R:= InverseRect(FSelRect);
   Canvas.Pen.Color:= clGray;
   Canvas.Pen.Mode:= pmXor;
   if R.Bottom = R.Top then  // ligne horizontale
   begin
      Canvas.Pen.Width:= 1;
      Canvas.Pen.Style:= psSolid;
      Canvas.MoveTo(R.Left, R.Top);
      Canvas.LineTo(R.Right + 1, R.Bottom);
   end
   else
   if R.Right = R.Left then  // ligne verticale
   begin
      Canvas.Pen.Width:= 1;
      Canvas.Pen.Style:= psSolid;
      Canvas.MoveTo(R.Left, R.Top);
      Canvas.LineTo(R.Right, R.Bottom + 1);
   end
   else
   begin
      Canvas.Pen.Width:= FFrameWidth;
      if (R.Right - R.Left < 12) or (R.Bottom - R.Top < 12) then
         Canvas.Pen.Style:= psSolid
      else
          Canvas.Pen.Style:= psDot;
      Canvas.Brush.Style:= bsClear;
      if FSelectionForm = sfRectangle then
          Canvas.Rectangle(R.Left, R.Top, R.Right+1, R.Bottom+1)
      else
          Canvas.Ellipse(R.Left, R.Top, R.Right+1, R.Bottom+1);
   end;
end;


function TzsiSelection.InverseRect(R: TRect): TRect;
var
  T: integer;
begin
   if R.Right < R.Left then
   begin
       T:= R.Left;
       R.Left:= R.Right;
       R.Right:= T;
   end;
   if R.Bottom < R.Top then
   begin
       T:= R.Top;
       R.Top:= R.Bottom;
       R.Bottom:= T;
     end;
   Result:= R;
end;


function TzsiSelection.SelectionExist: boolean;
begin
  Result:= ((FSelRect.Left > NULLPOINT) and (FSelRect.Top > NULLPOINT)
             and (FSelRect.Right > NULLPOINT) and (FSelRect.Bottom > NULLPOINT));
end;


function TzsiSelection.SelectionAvailable: boolean;
begin
  Result:= (SelectionExist and (SelectionState >= 9));
end;

procedure TzsiSelection.Deselect;
begin
  FSelRect:= Rect(NULLPOINT, NULLPOINT, NULLPOINT, NULLPOINT);
  if FActivated then Paint;
  SelectionState:= -1;
  ChangeCursor;
  if Assigned(FOwner.FSelRectChange) then FOwner.FSelRectChange(Self);
end;

procedure TzsiSelection.SetSelectionForm(AValue: TzsiSelectionForm);
begin
  if FSelectionForm <> AValue then
  begin
     FSelectionForm:= AValue;
     if FActivated then Paint;
  end;
end;

procedure TzsiSelection.SetFrameWidth(AValue: byte);
begin
  if FFrameWidth <> AValue then
  begin
     FFrameWidth:= AValue;
     if FActivated then Paint;
  end;
end;

function  TzsiSelection.GetSelRect: TRect;
begin
   Result:= InverseRect(FSelRect);
end;

procedure TzsiSelection.SetSelRect(AValue: Trect);
begin
   FSelRect:= AValue;
   if FSelectionType = stMagnetic then SelectionState:= 10;
   if FActivated then Paint;
   if Assigned(FOwner.FSelRectChange) then FOwner.FSelRectChange(Self);
end;


{ ----------------------------------------------------------------
                          TZSImage
  ---------------------------------------------------------------- }

constructor TZSImage.Create(AOwner: TComponent);
begin
   inherited Create(Aowner);
   ControlStyle := ControlStyle + [csOpaque, csReplicatable]; //????
   FBkgColor:= clGray;
   FBorderColor:= clBlack;
   FBorderWidth:= 0;
   FEnlarge:= false;
   FMargin:= 0;
   FOrigBmp:= TBitmap.Create;
   FCanvasBmp := TBitmap.Create;
   FSlideShow:= TzsiSlideShow.Create(self);
   FSelection:= TzsiSelection.Create(self);
   FDefaultCursor:= crArrow;
   Cursor:= FDefaultCursor;
   FMagnifierCursor:= crArrow;
   FMagnifierFactor:= 1;
   FMagnifierActivated:= false;
   FMagnifierSize:= 0;
   FKeyToScroll:= VK_SPACE;
   FStretchFactor:= 0;
   FOldMagnifierRect:= Rect(NULLPOINT, NULLPOINT, NULLPOINT, NULLPOINT);
   with FSelection do
   begin
      Parent:= self;
      Left:= 0;
      Top:= 0;
   end;
   Height := 100;
   Width := 100;
end;

destructor TZSImage.Destroy;
begin
   FSlideShow.Free;
   FCanvasBmp.Free;
   FOrigBmp.Free;
   inherited Destroy;
end;

procedure TZSImage.SetMagnifierActivated(AValue: boolean);
begin
   FMagnifierActivated:= AValue;
   if not(csDesigning in ComponentState) then
   begin
      if FMagnifierActivated then ChangeCursor(FMagnifierCursor)
      else ChangeCursor(FDefaultCursor);
   end;
end;

procedure TZSImage.Paint;
begin
   if csDesigning in ComponentState then
   begin
      with Canvas do
      begin
         Pen.Style := psDash;
         Brush.Style := bsClear;
         Rectangle(0, 0, Width, Height);
      end;
   end
   else
   if not(FCanvasBmp.Empty) then Canvas.Draw(0,0, FCanvasBmp)
   else
   begin
      Canvas.Brush.Color:= FBkgColor;
      Canvas.FillRect(Rect(0, 0, Width, Height));
   end;
end;


procedure TZSImage.InternSetImage(Source: TPersistent; MustRepaint: boolean);
// Attention : cette procedure n'appelle pas ImageChanged
begin
   try
      FOrigBmp.Assign(Source);
      StretchFromPoint(FOrigBmp, FCanvasBmp,
                       CENTERPOINT,
                       FStretchFactor, FOrigBmpRect, FCanvasBmpRect);
      if MustRepaint then Paint;
   except
      MessageBeep(0);
   end;
end;

procedure TZSImage.SetImage(Source: TPersistent);
begin
   InternSetImage(Source, true);
   ImageChanged;
end;

procedure TZSImage.SetImage(FileName: string);
begin
   LoadImageFromFile(FileName, FOrigBmp);
   StretchFromPoint(FOrigBmp, FCanvasBmp,
                    CENTERPOINT,
                    FStretchFactor, FOrigBmpRect, FCanvasBmpRect);
   Paint;
   ImageChanged;
end;

procedure TZSImage.StretchImage;
// Stretch de FOrigBmp en partant du centre de FOrigBmpRect
begin
   StretchFromPoint(FOrigBmp, FCanvasBmp,
                    Point(FOrigBmpRect.Left + (WidthOfRect(FOrigBmpRect) div 2), FOrigBmpRect.Top + (HeightOfRect(FOrigBmpRect) div 2)),
                    FStretchFactor, FOrigBmpRect, FCanvasBmpRect);
   Paint;
   ImageChanged;
end;

procedure TZSImage.StretchImage(ACenter: TPoint);
// Stretch de FOrigBmp en partant de ACenter
begin
   StretchFromPoint(FOrigBmp, FCanvasBmp,
                    ACenter,
                    FStretchFactor, FOrigBmpRect, FCanvasBmpRect);
   Paint;
   ImageChanged;
end;

procedure TZSImage.ImageChanged;
// adapte les modifications de l'image au canvas de FSelection
begin
   with FSelection do
      if FActivated then Paint;
end;

procedure TZSImage.ChangeCursor(ACursor: TCursor);
begin
   if not(csDesigning in ComponentState) then
      if Cursor <> ACursor then
       Cursor:= ACursor;
end;

function TZSImage.CallPopUpMenu(Pop: TPopUpMenu): boolean;
// pour éviter l'apparition des popupmenus avec Alt + clic droit (réservé à la Sélection)
begin
   Result:= false;
   if Assigned(PopUpMenu) then if PopupMenu.AutoPopup then PopUpmenu.AutoPopup:= false;
   with FSelection do
     if Assigned(PopUpMenu) then if PopupMenu.AutoPopup then PopUpmenu.AutoPopup:= false;
   if Assigned(Pop) then
      if GetKeyState(VK_MENU) >= 0 then Result:= true; // pas de touche Alt
end;

procedure TZSImage.WndProc(var Message: TMessage);
var
  Start: DWord;
begin
      case Message.Msg of
         WM_SIZE: if not(csDesigning in ComponentState) then
                  begin
                     if not FOrigBmp.Empty then
                     begin
                        Start:= GetTickCount; // on attend 10 ms avant de refaire le stretch
                        while GetTickCount - Start < 10 do Application.ProcessMessages;
                        StretchImage;
                     end;
                     FSelection.SetBounds(0, 0, Width, Height);
                  end
                  else inherited;
         WM_ERASEBKGND : if not FOrigBmp.Empty then Message.Result:= 1
                             else inherited;
         WM_LBUTTONDOWN : if not(csDesigning in ComponentState) then
                          begin
                                if FMagnifierActivated and (message.WParam = MK_LBUTTON) and (GetKeyState(FKeyToScroll) >= 0) then
                                begin
                                   ChangeCursor(crNone);
                                   DoMagnify(message.LParamLo, message.LParamHi);
                                end;
                                OrigMousePoint:= Point(message.LParamLo, message.LParamHi);
                                inherited;
                          end
                          else inherited;
         WM_RBUTTONDOWN : if not(csDesigning in ComponentState) then
                          begin
                              if CallPopUpMenu(PopUpMenu) then
                                PopUpMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
                              inherited;
                          end
                          else inherited;
         WM_MOUSEMOVE :  if not(csDesigning in ComponentState) then
                         begin
                           if (GetKeyState(VK_LBUTTON) < 0) and (GetKeyState(FKeyToScroll) < 0) then
                             DoScroll(message.LParamLo, message.LParamHi)
                           else if FMagnifierActivated and (message.WParam = MK_LBUTTON) then
                               DoMagnify(message.LParamLo, message.LParamHi);
                           inherited;
                         end
                         else inherited;
         WM_LBUTTONUP : if not(csDesigning in ComponentState) then
                        begin
                           if FMagnifierActivated then
                           begin
                              Paint;
                              ChangeCursor(FMagnifierCursor);
                              FOldMagnifierRect:= Rect(NULLPOINT, NULLPOINT, NULLPOINT, NULLPOINT);
                           end;
                           inherited;
                        end
                        else inherited;
      else
         inherited WndProc(Message);
      end;
end;


function TZSImage.GetScale: double;
// renvoie échelle entre CanvasBmpRect et OrigBmpRect
begin
   if HeightOfRect(FOrigBmpRect) > WidthOfRect(FOrigBmpRect) then
      Result:= HeightOfRect(FCanvasBmpRect) / HeightOfRect(FOrigBmpRect)
      else Result:= WidthOfRect(FCanvasBmpRect) / WidthOfRect(FOrigBmpRect);
end;


procedure TZSImage.StretchFromPoint(SourceBmp, DestBmp: TBitmap; Center: TPoint; AStretchFactor: double; var SourceRect, DestRect: TRect);
{ Stretch à partir d'un centre défini dans SourceBmp.
  Le centre sera éventuellement déplacé afin que DestBmp n'ait aucune zone hors bitmap source.
  AStretchFactor : 0,1 = 10% ... 1 = 100% ...4 = 400% ...
  SourceRect = partie de SourceBmp qui est affichée
  DestRect = emplacement de DestBmp sur le composant ZSImage}
var
  L,R,T,B: integer;
  WMax, HMax: integer;
  NewW, NewH: integer;
  I: integer;
  MustDrawBorder: boolean;
begin
   if SourceBmp.Empty then Exit;
   try
      if DestBmp.PixelFormat <> SourceBmp.PixelFormat then
         DestBmp.PixelFormat:= SourceBmp.PixelFormat;
   except
   end;
   if DestBmp.Width <> Width then DestBmp.Width:= Width;
   if DestBmp.Height <> Height then DestBmp.Height:= Height;
   if AStretchFactor = 0 then    // taille de ZSImage moins marge éventuelle
   begin
     AStretchFactor:= Min((Width - (FMargin * 2)) / SourceBmp.Width,
                          (Height - (FMargin * 2)) / SourceBmp.Height);
     if not(FEnlarge) and (AStretchFactor > 1.0) then AStretchFactor:= 1; // pas d'agrandissement d'une petite image
   end;
   WMax:= Round(Width / AStretchFactor);
   HMax:= Round(Height / AStretchFactor);
   if Center.X = CENTERPOINT.X then Center.X:= SourceBmp.Width div 2;
   if Center.Y = CENTERPOINT.Y then Center.Y:= SourceBmp.Height div 2;
   L:= Center.X - (WMax div 2);
   if L < 0 then L:= 0;
   R:= L + WMax;
   if R > SourceBmp.Width then
   begin
      R:= SourceBmp.Width;
      L:= R - WMax;
      if L < 0 then L:= 0;
   end;
   T:= Center.Y - (HMax div 2);
   if T < 0 then T:= 0;
   B:= T + Hmax;
   if B > SourceBmp.Height then
   begin
      B:= SourceBmp.Height;
      T:= B - HMax;
      if T < 0 then T:= 0;
   end;
   NewW:= Round((R - L) * AStretchFactor);
   NewH:= Round((B - T) * AStretchFactor);
   if (Width > NewW) or (Height > NewH) then  // l'image à afficher est plus petite que la taille de ZSImage
   begin
      Destrect.Left:= (Width - NewW) div 2;
      Destrect.Top:= (Height - NewH) div 2;
      Destrect.Right:= Destrect.Left + NewW;
      Destrect.Bottom:= Destrect.Top + NewH;
      DestBmp.Canvas.Brush.Color:= FBkgColor;
      with DestBmp do Canvas.FillRect(Rect(0,0,Width,Height));
      MustDrawBorder:= ((FBorderWidth > 0) and (FMargin >= FBorderWidth));
   end
   else     // l'image occupe tout l'espace de ZSIMage
   begin
      Destrect:= Rect(0,0,width,Height);
      MustDrawBorder:= false;
   end;
   ExCopyRect(DestBmp.Canvas, Destrect, SourceBmp.Canvas, Rect(L,T,R,B));
   if MustDrawBorder then   // dessin de l'encadrement de l'image
   begin
      DestBmp.Canvas.Brush.Color:= FBorderColor;
      // emploi de FrameRect : plus précis que Rectangle pour bordures larges
      for I:= 1 to FBorderWidth do
         DestBmp.Canvas.FrameRect(Rect(DestRect.Left - I, DestRect.Top - I, DestRect.Right + I, DestRect.Bottom + I));
   end;
   SourceRect:= Rect(L, T, R-1, B-1);
   Dec(DestRect.Right);
   Dec(DestRect.Bottom);
end;

procedure TZSImage.DoMagnify(X, Y: integer);
// stretch provoqué par la loupe
// pas d'utilisation de StretchFromPoint afin que le point cliqué reste toujours
// au centre du zoom.
var
  ROrig, RDest: TRect;
  XOrig, YOrig: integer;
  TempBmp: TBitmap;
  Region: HRGN;
  Size: integer;
  AScale: double;
begin
   if FOrigBmp.Empty then Exit;
   if (X < 0) or (X > Width) or (Y < 0) or (Y > Height) then Exit;
   if MagnifierFactor = 0.0 then Exit;
   // Rectification des points X et Y en cas de clic en dehors de CanvasBitmapRect
   if X < FCanvasBmpRect.Left then X:= FCanvasBmpRect.Left
      else if X > FCanvasBmpRect.Right then X:= FCanvasBmpRect.Right;
   if Y < FCanvasBmpRect.Top then Y:= FCanvasBmpRect.Top
      else if Y > FCanvasBmpRect.Bottom then Y:= FCanvasBmpRect.Bottom;
   // Calcul de l'échelle
   AScale:= GetScale;
   // adaptation du point cliqué sur l'image originale
   XOrig:= Round((X - FCanvasBmpRect.Left) / AScale) + FOrigBmpRect.Left;
   YOrig:= Round((Y - FCanvasBmpRect.Top) / AScale) + FOrigBmpRect.Top;
   // calcul des Rect
   // ROrig = rect à prendre dans FOrigBmp
   // RDest = rect de destination
   RDest.Left:= 0;
   RDest.Top:= 0;
   ROrig.Left:= XOrig - Round(X / MagnifierFactor);
   if ROrig.Left < 0 then
   begin
      RDest.Left:= Round(-ROrig.Left * MagnifierFactor);
      ROrig.Left:= 0;
   end;
   ROrig.Top:= YOrig - Round(Y / MagnifierFactor);
   if ROrig.Top < 0 then
   begin
      RDest.Top:= Round(-ROrig.Top * MagnifierFactor);
      ROrig.Top:= 0;
   end;
   ROrig.Right:= XOrig + Round((Width - X) / MagnifierFactor);
   if ROrig.Right > FOrigBmp.Width then ROrig.Right:= FOrigBmp.Width;
   ROrig.Bottom:= YOrig + Round((Height - Y) / MagnifierFactor);
   if ROrig.Bottom > FOrigBmp.Height then ROrig.Bottom:= FOrigBmp.Height;
   RDest.Right:= RDest.Left + Round((ROrig.Right - ROrig.left) * MagnifierFactor);
   RDest.Bottom:= RDest.Top + Round((ROrig.Bottom - ROrig.Top) * MagnifierFactor);

   if RectIsEqual(ROrig, FOldMagnifierRect) then Exit;

   // adaptation de la taille de la loupe en fonction de la taille de ZSImage
   if FMagnifierSize > Width - 50 then Size:= (Width - 50) div 2
      else Size:= FMagnifierSize div 2;

   TempBmp:= TBitmap.Create;
   try
      if Size = 0 then  // loupe plein écran
      begin
         with TempBmp do
         begin
            Width:= Self.Width;
            Height:= Self.Height;
            Canvas.Brush.Color:= FBkgColor;
            Canvas.FillRect(Rect(0, 0, Width, Height));
         end;
         ExCopyRect(TempBmp.Canvas, RDest, FOrigBmp.Canvas, ROrig);
         Canvas.Draw(0,0,TempBmp);
      end
      else
      begin
          TempBmp.Assign(FCanvasBmp);
          Region:= CreateEllipticRgn(X - Size, Y - Size, X + Size +1, Y  + Size+1);
          SelectClipRgn(TempBmp.Canvas.Handle, Region);
          ExCopyRect(TempBmp.Canvas, RDest, FOrigBmp.Canvas, ROrig);
          Canvas.Draw(0,0,TempBmp);
          SelectClipRgn(TempBmp.Canvas.Handle, 0);
          DeleteObject(Region);
          Canvas.Brush.Style:= bsClear;
          Canvas.Pen.Color:= clgray;
          Canvas.Pen.Mode:= pmXor;
          Canvas.Ellipse(X - Size, Y - Size, X + Size+1, Y  + Size+1);
      end;
      FOldMagnifierRect:= ROrig; // mémorisation du rect zoomé
   finally
      TempBmp.Free;
   end;
end;

procedure TZSImage.DoScroll(X, Y: integer);
// stretch provoqué par le défilement dans l'image (KeyToScroll + clic gauche)
var
  VariationX, VariationY: integer;
begin
  if not(PtInRect(Rect(0,0,Width,Height), Point(X,Y))) then Exit;
  VariationX:= X - OrigMousePoint.X;
  VariationY:= Y - OrigMousePoint.Y;
  if ((VariationX > 0) and (FOrigBmpRect.Left > 0)) or
     ((VariationX < 0) and (FOrigBmpRect.Right < FOrigBmp.Width - 1)) or
     ((VariationY > 0) and (FOrigBmpRect.Top > 0)) or
     ((VariationY < 0) and (FOrigBmpRect.Bottom < FOrigBmp.Height - 1)) then
     StretchImage(Point(FOrigBmpRect.Left + (WidthOfRect(FOrigBmpRect) div 2) - VariationX,
                        FOrigBmpRect.Top + (HeightOfRect(FOrigBmpRect) div 2) - VariationY));
  OrigMousePoint:= Point(X, Y);
end;

procedure TZSImage.SetStretchFactor(AValue: double);
begin
  if AValue < 0 then AValue:= 0;
  if AValue <> FStretchFactor then
  begin
    FStretchFactor:= AValue;
    StretchImage;
  end;
end;


function TZSImage.GetSelection(var AOrigRect, AStretchRect: TRect): boolean;
// renvoie les coordonnées de la sélection
// dans AOrigRect : coordonnées mises à l'échelle dans OrigBitmap
// dans AStretchRect : coordonnées dans CanvasBitmap
var
  AScale: double;
begin
   Result:= false;
   if not(FSelection.SelectionExist) then Exit; // pas de sélection
   if not(InterSectRect(AStretchRect, FSelection.SelectedRect, FCanvasBmpRect)) then Exit;
   //mise à l'échelle dans FOrigBmp
   AScale:= GetScale;
   AOrigRect.Left:= Round((AStretchRect.Left - FCanvasBmpRect.Left) / AScale) + FOrigBmpRect.Left;
   AOrigRect.Top:= Round((AStretchRect.Top - FCanvasBmpRect.Top) / AScale) + FOrigBmpRect.Top;
   AOrigRect.Right:= Round((AStretchRect.Right - FCanvasBmpRect.Left + 1) / AScale) + FOrigBmpRect.Left;
   AOrigRect.Bottom:= Round((AStretchRect.Bottom - FCanvasBmpRect.Top + 1) / AScale) + FOrigBmpRect.Top;
   if AOrigRect.Right >= FOrigBmp.Width then AOrigRect.Right:= FOrigBmp.Width - 1;
   if AOrigRect.Bottom >= FOrigBmp.Height then AOrigRect.Bottom:= FOrigBmp.Height - 1;
   Result:= true;
end;

procedure TZSImage.ResizeImage;
// recadrage de OrigBitmap
var
  AOrigRect, AStretchrect, R: TRect;
  TempBmp: TBitmap;
  Region: HRGN;
begin
   if not(FOrigBmp.Empty) then
   if GetSelection(AOrigRect, AStretchrect) then
   begin
      Inc(AOrigRect.Right);
      Inc(AOrigRect.Bottom);
      TempBmp:= TBitmap.Create;
      try
         with TempBmp do
         begin
            Width:= AOrigRect.Right - AOrigRect.Left;
            Height:= AOrigRect.Bottom - AOrigRect.Top;
            R:= Rect(0, 0, Width, Height);
            PixelFormat:= FOrigBmp.PixelFormat;
         end;
         if FSelection.SelectionForm = sfEllipse then
         begin
             with TempBmp do Region:= CreateEllipticRgnIndirect(R);
             SelectClipRgn(TempBmp.Canvas.Handle, Region);
             with TempBmp.Canvas do CopyRect(R, FOrigBmp.Canvas, AOrigRect);
             DeleteObject(Region);
         end
         else
            with TempBmp.Canvas do CopyRect(R, FOrigBmp.Canvas, AOrigRect);
         SetImage(TempBmp);
      finally
         TempBmp.Free;
      end;
   end;
end;

procedure TZSImage.Clear;
// supprime toute image , vide la liste de FSlideShow
// et supprime toute sélection
begin
   FSelection.Deselect;
   FSlideShow.FImgList.Clear;
   // destruction et recréation des bitmap
   FOrigBmp.Free;
   FCanvasBmp.Free;
   FOrigBmp:= TBitmap.Create;
   FCanvasBmp:= TBitmap.Create;
   Paint;
end;

procedure TZSImage.UpdateRect(AOrigRect, AStretchRect: TRect);
// restretching d'une zone partielle
begin
   ExCopyrect(FCanvasBmp.Canvas, AStretchrect, FOrigBmp.Canvas, AOrigRect);
   Paint;
   ImageChanged;
end;



{ ----------------------------------------------------------------
                          TMinNavigation
  ---------------------------------------------------------------- }

constructor TMinNavigation.Create(AOwner: TComponent);
begin
   inherited Create(AOwner);
   FMinBmp:= TBitmap.Create;
   FImage:= nil;
   FColor:= clWhite;
   FBorderColor:= clBlack;
   FOffset:= 10;
   Width:= 140;
   Height:= 140;
   Cursor:= crHandPoint;
end;

destructor TMinNavigation.Destroy;
begin
   FMinBmp.Free;
   inherited Destroy;
end;

procedure TMinNavigation.Paint;
begin
   Canvas.Brush.Color:= FColor;
   Canvas.FillRect(Rect(0, 0, Width, Height));
   if FBorderColor <> clNone then
   begin
      Canvas.Brush.Color:= FBorderColor;
      Canvas.FrameRect(Rect(0, 0, Width, Height));
   end;
   if not FMinBmp.Empty then
      Canvas.Draw(FMinRect.Left, FMinRect.Top, FMinBmp);
end;

procedure TMinNavigation.UpdateMiniature;
begin
   if (FImage = nil) or (FImage.OrigBitmap.Empty) then Exit;
   FScale:= Min((Width - FOffset)/ FImage.OrigBitmap.Width , (Height - FOffset) / FImage.OrigBitmap.Height);
   FMinBmp.Width:= Round(FImage.OrigBitmap.Width * FScale);
   FMinBmp.Height:= Round(FImage.OrigBitmap.Height * FScale);
   ExCopyRect(FMinBmp.Canvas, Rect(0, 0, FMinBmp.Width, FMinBmp.Height),
                FImage.OrigBitmap.Canvas, Rect(0, 0, FImage.OrigBitmap.Width, FImage.OrigBitmap.Height));
   FMinRect:= Bounds((Width - FMinBmp.Width) div 2, (Height - FMinBmp.Height) div 2,
                       FMinBmp.Width, FMinBmp.Height);
   Paint;
end;

procedure TMinNavigation.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   if Button = mbLeft then Execute(X, Y);
end;

procedure TMinNavigation.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
   if (ssLeft in Shift) and (PtInRect(Rect(0, 0, Width, Height), Point(X,Y))) then Execute(X, Y);
end;


procedure TMinNavigation.Execute(X, Y: integer);
begin
    if (FImage = nil) or (FImage.OrigBitmap.Empty) or (FMinBmp.Empty) then Exit;
    with FImage.OrigBitmapRect do
      if (Left = 0) and (Top = 0) and (Right = FImage.OrigBitmap.Width - 1)
        and (Bottom = FImage.OrigBitmap.Height - 1) then Exit;
    with FMinRect do
    begin
       if X < Left then X:= Left
       else if X > Right then X:= Right
       else X:= X - Left;
       if Y < Top then Y:= Top
       else if Y > Bottom then Y:= Bottom
       else Y:= Y - Top;
    end;
    X:= Round(X / FScale);
    Y:= Round(Y / FScale);
    FImage.StretchImage(Point(X, Y));
end;

procedure TMinNavigation.SetColor(AValue: TColor);
begin
  if FColor <> AValue then
  begin
     FColor:= AValue;
     Paint;
  end;
end;

procedure TMinNavigation.SetBorderColor(AValue: TColor);
begin
   if FBorderColor <> AValue then
   begin
      FBorderColor:= AValue;
      Paint;
   end;
end;

procedure TMinNavigation.Clear;
// destruction de l'image miniature
begin
  FMinBmp.Free;
  FMinBmp:= TBitmap.Create;
  Paint;
end;


end.
