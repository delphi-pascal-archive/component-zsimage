unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, Typinfo, ExtCtrls, ComCtrls, Menus;

type
  TForm1 = class(TForm)
    OpenDialog1: TOpenDialog;
    InfoPanel: TPanel;
    LoadImagesBtn: TButton;
    NextImgBtn: TButton;
    PreviousImgBtn: TButton;
    GroupBox1: TGroupBox;
    GroupBox6: TGroupBox;
    CBEffectsScript: TCheckBox;
    CBEffectOnShow: TCheckBox;
    ComboEffects: TComboBox;
    TrackBarTimeOnShow: TTrackBar;
    TrackBarTimeOnHide: TTrackBar;
    Label1: TLabel;
    Label2: TLabel;
    GroupBox3: TGroupBox;
    LabelMagnifierFactor: TLabel;
    Label3: TLabel;
    CBEffectOnHide: TCheckBox;
    Timer1: TTimer;
    CBAutoSlideShow: TCheckBox;
    TBMagnifierFactor: TTrackBar;
    TBMagnifierSize: TTrackBar;
    MagnifierBtn: TSpeedButton;
    SelResizeableBtn: TSpeedButton;
    SelMagneticBtn: TSpeedButton;
    SelectionFormCB: TComboBox;
    SelectionFrameWidthCB: TComboBox;
    Label4: TLabel;
    ResizeBtn: TSpeedButton;
    SelrectLabel: TLabel;
    TBStretchFactor: TTrackBar;
    LabelStretchFactor: TLabel;
    ImgIndexLabel: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure LoadImagesBtnClick(Sender: TObject);
    procedure NextImgBtnClick(Sender: TObject);
    procedure PreviousImgBtnClick(Sender: TObject);
    procedure TrackBarTimeOnShowChange(Sender: TObject);
    procedure TrackBarTimeOnHideChange(Sender: TObject);
    procedure ComboEffectsChange(Sender: TObject);
    procedure CBEffectOnShowClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure CBAutoSlideShowClick(Sender: TObject);
    procedure TBMagnifierFactorChange(Sender: TObject);
    procedure TBStretchFactorChange(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TBMagnifierSizeChange(Sender: TObject);
    procedure MagnifierBtnClick(Sender: TObject);
    procedure SelResizeableBtnClick(Sender: TObject);
    procedure SelMagneticBtnClick(Sender: TObject);
    procedure SelectionFormCBClick(Sender: TObject);
    procedure SelectionFrameWidthCBClick(Sender: TObject);
    procedure ResizeBtnClick(Sender: TObject);
    procedure CBEffectsScriptClick(Sender: TObject);

  private
    { Déclarations privées }
    procedure ZSIMageSlideShowEffect(Sender: TObject);
    procedure ZSImageSelectionMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: integer);
    procedure ZSImageSelectionMouseMove(Shift: TShiftState; X, Y: integer);
    procedure ZSImageSelectionChange(Sender: TObject);
    procedure PaintInRed;
    procedure ImageChanged;
  public
    { Déclarations publiques }
  end;

var
  Form1: TForm1;

implementation

uses ZSImage;

{$R *.dfm}
{$R Cursors.res}

const
   CURSORMAGNIFYGLASS = 1;
   CURSORRESIZE = 2;
   CURSORPAINT = 3;
var
  ZSImage: TZSImage;
  MinNavigation: TMinNavigation;

procedure TForm1.FormCreate(Sender: TObject);
var
  I: integer;
begin
  Screen.Cursors[CURSORMAGNIFYGLASS]:= LoadCursor(hinstance, 'CRMAGNIFYGLASS');
  Screen.Cursors[CURSORRESIZE]:= LoadCursor(hinstance, 'CRRESIZE');
  Screen.Cursors[CURSORPAINT]:= LoadCursor(hinstance, 'CRPAINT');
  ZSImage:= TZSImage.Create(self);
  with ZSImage do
  begin
    Parent:= Form1;
    Align:= alClient;
    BkgColor:= clGray;
    Margin:= 20;
    BorderWidth:= 2;
    BorderColor:= clBlack;
    MagnifierCursor:= CURSORMAGNIFYGLASS;
    OnSlideShowEffect:= nil;
    OnSelectionMouseDown:= ZSImageSelectionMouseDown;
    OnSelectionMouseMove:= ZSImageSelectionMouseMove;
    OnSelectionChange:= ZSImageSelectionChange;
    TrackBarTimeOnShow.Position:= SlideShow.EffectTimeOnShow;
    TrackBarTimeOnHide.Position:= SlideShow.EffectTimeOnHide;
  end;
  for I:= 0 to Word(High(TzsiSlideShowEffects)) do
      ComboEffects.Items.Add(GetEnumName(typeInfo(TzsiSlideShowEffects),integer(I)));
  ComboEffects.ItemIndex:= 0;
  MinNavigation:= TMinNavigation.Create(InfoPanel);
  with MinNavigation do
  begin
    Parent:= InfoPanel;
    Image:= ZSImage;
    Left:= 35;
    Top:= 145;
  end;
  SelRectLabel.Caption:= '';
end;

procedure TForm1.LoadImagesBtnClick(Sender: TObject);
begin
   with OpenDialog1 do
      if Execute then
      begin
         ZSImage.SlideShow.List.Assign(Files);
         ZSImage.SlideShow.ShowImage(0, 1);
         ImageChanged;
      end;
end;

procedure TForm1.NextImgBtnClick(Sender: TObject);
begin
  with ZSImage.SlideShow do ShowImage(ImageIndex + 1, 1, 1);
  ImageChanged;
end;

procedure TForm1.PreviousImgBtnClick(Sender: TObject);
begin
   with ZSImage.SlideShow do ShowImage(ImageIndex - 1, 1, 1);
   ImageChanged;
end;

procedure TForm1.CBAutoSlideShowClick(Sender: TObject);
begin
   Timer1.Enabled:= CBAutoSlideShow.Checked;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
   Timer1.Enabled:= false;
   with ZSImage.SlideShow do
     if ImageIndex >= List.Count - 1 then ShowImage(0, 1)
       else ShowImage(ImageIndex + 1, 1);
   ImageChanged;
   Timer1.Enabled:= true;
end;

procedure TForm1.ImageChanged;
begin
   with ZSImage.SlideShow do
     ImgIndexLabel.caption:= 'Image en cours : ' + IntToStr(ImageIndex + 1) + '/' + IntToStr(List.Count);
   MinNavigation.UpdateMiniature;
end;

procedure TForm1.TBStretchFactorChange(Sender: TObject);
begin
   if TBStretchFactor.Position = 0 then
      LabelStretchFactor.Caption:= 'Taille écran'
   else
      LabelStretchFactor.Caption:= FloatToStr(TBStretchFactor.Position * 0.25 * 100) + '%';
   ZSImage.StretchFactor:= TBStretchFactor.Position * 0.25;
end;

procedure TForm1.TBMagnifierFactorChange(Sender: TObject);
begin
    ZSImage.MagnifierFactor:= TBMagnifierFactor.Position * 0.25;
    LabelMagnifierFactor.Caption:= FloatToStr(ZSImage.MagnifierFactor * 100) + '%';
end;

procedure TForm1.TBMagnifierSizeChange(Sender: TObject);
begin
    ZSImage.MagnifierSize:= TBMagnifierSize.Position * 100;
end;

procedure TForm1.MagnifierBtnClick(Sender: TObject);
begin
    ZSImage.Selection.Activated:= false;
    ResizeBtn.Enabled:= false;
    ZSImage.MagnifierActivated:= MagnifierBtn.Down;
end;

procedure TForm1.SelResizeableBtnClick(Sender: TObject);
begin
   ZSImage.MagnifierActivated:= false;
   with ZSImage.Selection do
   begin
      Deselect;
      CursorOnDrawSel:= CURSORRESIZE;
      SelectionType:= stresizeable;
      Activated:= SelResizeableBtn.Down;
      ResizeBtn.Enabled:= Activated;
   end;
end;

procedure TForm1.SelMagneticBtnClick(Sender: TObject);
begin
   ZSImage.MagnifierActivated:= false;
   ResizeBtn.Enabled:= false;
   with ZSImage.Selection do
   begin
      Deselect;
      CursorOnDrawSel:= CURSORPAINT;
      SelectionType:= stMagnetic;
      Activated:= SelMagneticBtn.Down;
   end;
end;

procedure TForm1.SelectionFormCBClick(Sender: TObject);
begin
   if SelectionFormCB.ItemIndex = 1 then
      ZSImage.Selection.SelectionForm:= sfEllipse
   else
      ZSImage.Selection.SelectionForm:= sfRectangle;
end;

procedure TForm1.SelectionFrameWidthCBClick(Sender: TObject);
begin
   ZSIMage.Selection.FrameWidth:= SelectionFrameWidthCB.ItemIndex + 1;
end;

procedure TForm1.ResizeBtnClick(Sender: TObject);
begin
   with ZSImage do
     if Selection.SelectionExist then
     begin
        ResizeImage;
        Selection.Deselect;
        MinNavigation.UpdateMiniature;
     end;
end;

procedure TForm1.ComboEffectsChange(Sender: TObject);
begin
    with ComboEffects do ZSImage.SlideShow.Effect:= TzsiSlideShowEffects(GetEnumValue(TypeInfo(TzsiSlideShowEffects), Items[ItemIndex]));
end;

procedure TForm1.CBEffectOnShowClick(Sender: TObject);
begin
   ZSIMage.SlideShow.EffectOnShow:= CBEffectOnShow.Checked;
   ZSImage.SlideShow.EffectOnHide:= CBEffectOnHide.Checked;
end;

procedure TForm1.CBEffectsScriptClick(Sender: TObject);
begin
   if CBEffectsScript.Checked then
     ZSImage.OnSlideShowEffect:= ZSIMageSlideShowEffect
   else
   with ZSImage do
   begin
     OnSlideShowEffect:= nil;
     SlideShow.Effect:= TzsiSlideShowEffects(GetEnumValue(TypeInfo(TzsiSlideShowEffects), ComboEffects.Items[ComboEffects.ItemIndex]));
     SlideShow.EffectOnShow:= CBEffectOnShow.Checked;
     SlideShow.EffectOnHide:= CBEffectOnHide.Checked;
     SlideShow.EffectTimeOnShow:= TrackBarTimeOnShow.Position;
     SlideShow.EffectTimeOnHide:= TrackBarTimeOnHide.Position;
   end;
end;

procedure TForm1.TrackBarTimeOnShowChange(Sender: TObject);
begin
    ZSImage.SlideShow.EffectTimeOnShow:= TrackBarTimeOnShow.Position;
end;

procedure TForm1.TrackBarTimeOnHideChange(Sender: TObject);
begin
   ZSImage.SlideShow.EffectTimeOnHide:= TrackBarTimeOnHide.Position;
end;

procedure TForm1.ZSImageSelectionChange(Sender: TObject);
var
  R,R2: TRect;
begin
   // coordonnées de la sélection par rapport au bitmap original
   with ZSImage do
     if GetSelection(R, R2) then
        with R do SelRectLabel.Caption:= inttostr(Left) + '/' + inttostr(Top) + '/' +
                                         inttostr(Right - Left + 1) + '/' + inttostr(Bottom - Top + 1)
     else SelRectLabel.Caption:= '';
end;

procedure TForm1.ZSImageSelectionMouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: integer);
begin
   ZSImageSelectionMouseMove(Shift, X, Y);
end;

procedure TForm1.ZSImageSelectionMouseMove(Shift: TShiftState; X, Y: integer);
begin
   with ZSImage do
     if (Shift = [ssLeft]) and (Selection.SelectionType = stMagnetic) and Selection.SelectionAvailable then
        PaintInred;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
   // afin que les contrôles ne répondent pas à la touche space
   if Key = VK_SPACE then Key:= 0;
end;

procedure TForm1.PaintInRed;
var
  AOrigRect, AStretchrect: Trect;
begin
  with ZSImage do
  if GetSelection(AOrigRect, AStretchrect) then
  begin
    Inc(AOrigRect.Right);
    Inc(AOrigRect.Bottom);
    Inc(AStretchRect.Right);
    Inc(AStretchRect.Bottom);
    // peinture dans OrigBitmap
    OrigBitmap.Canvas.Brush.Color:= clRed;
    OrigBitmap.Canvas.Pen.Color:= clred;
    if Selection.SelectionForm = sfEllipse then
          OrigBitmap.Canvas.Ellipse(AOrigRect)
        else
           OrigBitmap.Canvas.Rectangle(AOrigRect);
   { maintenant, il faut actualiser CanvasBitmap :
     3 solutions :
        1) refaire la peinture dans CanvasBitmap en prenant AStretchrect
            + faire un refresh de ZSImage pour afficher CanvasBitmap
        2) faire ZSIMage.StretchImage qui va reconstruire CanvasBitmap : plus lent
        3) Restretcher uniquement le rectangle modifié : moins précis que 2)
      solution utilisée : la 3°}
    UpdateRect(AOrigrect, AStretchrect);
  end;
end;

procedure TForm1.ZSIMageSlideShowEffect(Sender: TObject);
// exemple de script d'effet
begin
   with ZSImage.SlideShow do
     case ImageIndex of
       0  : begin
               Effect:= se_Blend;
               EffectOnShow:= true;
               EffectTimeOnShow:= 500;
            end;
       1,4: begin
              Effect:= se_MiddleToLeftRight;
              EffectOnShow:= true;
              EffectOnHide:= true;
              EffectTimeOnShow:= 1000;
            end;
       2,5: begin
              Effect:= se_aw_center;
              EffectOnShow:= true;
              EffectOnHide:= true;
              EffectTimeOnShow:= 500;
              EffectTimeOnHide:= 300;
            end;
       3,6: begin
              Effect:= se_MiddleToTopBottom;
              EffectOnShow:= true;
              EffectOnHide:= true;
              EffectTimeOnShow:= 1000;
              EffectTimeOnHide:= 500;
           end;
     else
     begin
        Effect:= RandomEffect;
        EffectOnShow:= true;
        EffectOnHide:= false;
        EffectTimeOnShow:= 500;
     end;
   end;
end;

end.

