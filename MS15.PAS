{$Keep 'MS15'}
{$Optimize -1}
{$MemoryModel 0}
{$Title 'Milestones 2000 Source Listing'}

Program MS2000(input,output);
Uses  Common, ACE, GSOS, ToolLocator, MemoryMgr, MscToolset, QuickdrawII,
   EventMgr, DeskMgr, SoundMgr, IntegerMath, ControlMgr,
   WindowMgr, MenuMgr, LineEdit, DialogMgr, ScrapMgr,
   FontMgr, ResourceMgr;
const  kaboutitem=301;khelpitem=302;kbeginitem=303;
       kabortitem=304;kquititem=305;krallyitem=306;
       kgameitem=307;kplayeritem=308;khallitem=309;
       kapplemenu=1;kgamemenu=2;keditmenu=3;
       kinfomenu=4;
       km50=33;km100=34;km150=35;km200=36;km400=37;
       Empty=44;Gas=45;EF=50;Flat=46;Spare=47;SS=51;
       Crash=42;Repairs=43;SD=49;SL=38;EL=39;Stop=41;Go=40;ROW=48;
       GS=2;human=1;
       coup=1;play=2;discard=3;soundcount=32;
       ksounditem=$136;kdeckitem=$137;

{ ============================================================= }
{ picstats contains the LocInfo data for each graphics resource.}
{ soundsizearray contains the soundparamblock data for each     }
{   sound resource. See the accompanying textfile for a list of }
{   code number meanings.                                       }
{ ============================================================= }

type picstats=record
               width:integer;
               right:integer;
               bottom:integer;
              end;
     picarray=array[1..60] of picstats;
     SizeP=^picarray;
     SizeH=^SizeP;
     ssrec=RECORD
               size,rate,volume,channel:integer;
            end;
     soundsizearray=array[1..soundcount]of ssrec;
     ssptr=^soundsizearray;
     sshdl=^ssptr;
     gsosInstringHdl=^gsosInstringPtr;
     Str200=string[200];Str12=String[12];
     statusflag=array[1..2] of boolean;
     statuscount=array[1..2] of integer;
     a1type=array[Human..GS] of array[1..7] of integer;
     a2type=array[1..10] of Str12;
     a3type=array[1..10] of integer;
     a5type=array[1..10] of real;
     a6type=array[1..101] of integer;
     hoftype=RECORD
           h1:string[12];
           b1,b2,b3,b4,b5:boolean;
           i1,i2,i3,i4,i5,i6:integer;
           f1,f2,f3,f4,f5,f6:statusflag;
           c1,c2,c3,c4,c5:statuscount;
           a1:a1type;
           a2:a2type;
           a3,a4:a3type;
           a5:a5type;
           a6:a6type;
          end;

var
{ ============================================================= }
{  Stuff to keep track of where we are with the system          }
{ ============================================================= }
   gMyMemoryID,gMainmemoryID:Integer;
   gstartstopref:longint;
   tlup,tlum:array [0..255] of integer;
   gdone,cursorvis,savable:boolean;
   gMainEvent:EventRecord;
   gLastwindow,gBordw,gFiniw,gGamew,gAbtw,
     gHallw,gOopsw,gCkptw,gH000w,
     gH001w,gPlyrw,gAborw,gRllyw:GrafPortPtr;
   GameOn,HallOn,H000On,H001On,FiniOn,RllyOn,AbtOn:boolean;
   quitsaveline,soundline,deckline:string[20];
   soundon,deckon:boolean;
   HOFrec:hoftype;

{ ============================================================= }
{  Stuff to help place and manipulate sound and graphics        }
{ ============================================================= }
   tempLI:LocInfo;
   screenport:grafportptr;
   Sizes:picarray;
   bordH,backH,PicH,TempH,inH,PackedH,MaskH,cbH:Handle;
   bordLI,backLI,PicLI,cbLI:Locinfo;
   myRH:RgnHandle;
   S1,S2,S3:str200;
   mode:array[1..60] of integer;
   dph:sshdl;dh:array[1..soundcount]of handle;
   mysound:array[1..5] of soundparamblock;
   lockedsounds:set of 1..soundcount;   {which sound handles need unlocking?}
   hallS2,hallS3,hallS4,FiniS1,FiniS2,FiniS3:Handle;
   tmcode:integer;mainCH:ctlrecHndl;
{ ============================================================= }
{  Stuff to figure out how the game is progressing              }
{ ============================================================= }
   humanname:string[12];
   hofname:a2type;
   hofwin,hoflose:a3type;
   hofsplit:a5type;
   helpsetting,helpshowing:integer;
   upplayer,goesfirst:integer;
   hasROW,hasSS,hasSD,hasEF:statusflag;
   coupROW,coupSS,coupSD,coupEF:boolean;
   underSL,coupable:statusflag;
   upcard,distance,zooms,score,gotchas:statuscount;
   action,card,ckpoint,cardsleft:integer;
   value:array [km50..km400] of integer;
   hands:a1type;
   shuffledeck,newdeck:a6type;

procedure docontrols; forward;
procedure dofinishline; forward;

{ ============================================================= }
{  MYRAND: Returns an integer in the range [1..R]               }
{ ============================================================= }
function myrand(r:integer):integer;
begin
   myrand:=(randominteger mod r) + 1;
end;

{ ============================================================= }
{  ERRORBOMB: dies spectacularly if something major is wrong    }
{ ============================================================= }

procedure Errorbomb;
var s:string[7];Errcode:integer;
begin
   errcode:=toolerror;
   s:=concat('//',cnvis(toolerror));
   Sysfailmgr(Errcode,@s[1]);
   Halt(-1);
end;

procedure stuffzeroes(var S:Str200);
var i:integer;
begin
   for i:=1 to length(s) do
       if s[i]='%' then s[i]:=chr(0);
end;

{==============================}
{ Operations on cards & status }
{==============================}
function isapower(c:integer):boolean;
begin
   isapower:=(c=SS) or (c=EF) or (c=SD) or (c=ROW);
end;

function cancoup(ct:integer):boolean;
var icc:integer;tb:boolean;
begin
 tb:=false;icc:=1;
 repeat
   if Hands[GS,icc]=ct then tb:=true else icc:=icc+1;
 until (tb=true) or (icc>6);
 if coupable[upplayer] then cancoup:=tb else cancoup:=false;
end;

function roadleft(p:integer):integer;
begin
  roadleft:=ckpoint-distance[p];
end;

function playerclose:boolean;
begin
  if upcard[human]<>Go
   then playerclose:=false
   else if underSL[human]
           then playerclose:=roadleft(human) in [50,100]
           else if zooms[human]=2
                  then playerclose:=roadleft(human) in [50,100,150,200]
                  else playerclose:=roadleft(human) in [50,100,150,200,400];
end;

function cardcount(cc:integer):integer;
var ci,cj:integer;
begin
 ci:=0;
 for cj:=1 to 7 do
   if Hands[GS,cj]=cc then ci:=ci+1;
 cardcount:=ci;
end;

function hassafety:integer;
var hsc,isc:integer;
begin
  hsc:=0;
  for isc:=1 to 7 do
    if isapower(Hands[GS,isc]) then hsc:=Hands[GS,isc];
  hassafety:=hsc;
end;

function cangoout:integer;
var cgc:integer;
begin
  cgc:=0;
  case roadleft(GS) of
    50: if cardcount(km50)>0 then cgc:=km50;
    100: if cardcount(km100)>0 then cgc:=km100;
    150: if (cardcount(km150)>0) and (not underSL[GS]) then cgc:=km150;
    200: if (cardcount(km200)>0) and (not underSL[GS]) then cgc:=km200;
    400: if (cardcount(km400)>0) and (zooms[GS]<2) and (not underSL[GS])
           then cgc:=km400;
    otherwise:begin end;
  end{case};
  if (cgc>0) and (hassafety>0) then cgc:=hassafety;
  cangoout:=cgc;
end;

{ ============================================================= }
{  SIZEOFPIC: returns number of bytes in unpacked graphic       }
{ ============================================================= }
Function Sizeofpic(picnum:integer):integer;
begin
   sizeofpic:=Sizes[picnum].width*Sizes[picnum].bottom;
end;

{ ============================================================= }
{  SPEAK: Start sound resource #<CODE>.       }
{ ============================================================= }

procedure speak(code:integer);
var si,sj:integer;qh:handle;
begin
 if soundon then begin
   qh:=loadresource($2BA6,code);
   dh[code]:=NewHandle(gethandlesize(qh)*2,gmymemoryID,
               attrlocked+attrpurge1+attrpage,nil);
   Hlock(qh);lockedsounds:=lockedsounds + [code];
   if odd(dph^^[code].size) then si:=(dph^^[code].size+1) DIV 2
                            else si:=dph^^[code].size DIV 2;
   AceExpBegin;ACEExpand(qh,0,dh[code],0,si,1);
   HUnlock(qh);ReleaseResource(3,$2BA6,code);
   with mysound[1] do begin
       wavestart:=dh[code]^;wavesize:=dph^^[code].size;
       freqoffset:=dph^^[code].rate+40;DOCbuffersize:=5;
       volsetting:=dph^^[code].volume*16;
       nextwaddr:=nil;
       if dph^^[code].channel=1
           then docbuffer:=$4000 else docbuffer:=$8000;
   end {with};
      case dph^^[code].channel of
         1:begin
            FFStopsound($7FEB);
            FFStartsound($0001,mysound[1]);
           end;
         0:begin
            FFStopsound($7FEE);
            FFStartSound($1201,mysound[1]);
           end;
         otherwise: begin end;
      end{case};
  end;
end;

{ ============================================================= }
{  DRAWSETUPWINDOW: Defprocs for all them windows               }
{ ============================================================= }
{$ToolParms+,$DataBank+}
procedure drawH001window;{defproc}
begin
   drawcontrols(gH001w);
end;
procedure drawRllywindow;{defproc}
begin
   drawcontrols(gRllyw);
end;
procedure drawAbtwindow;{defproc}
begin
   drawcontrols(gAbtw);
end;
procedure drawH000window;{defproc}
begin
   drawcontrols(gH000w);
end;
procedure drawGamewindow;{defproc}
begin
   drawcontrols(gGamew);
end;
procedure drawHallwindow;{defproc}
begin
   drawcontrols(gHallw);
end;
procedure drawPlyrwindow;{defproc}
begin
   drawcontrols(gPlyrw);
end;
procedure drawFiniwindow;{defproc}
begin
   drawcontrols(gFiniw);
end;
{$ToolParms-,$DataBank-}

{ ============================================================= }
{  DRAWBORDWINDOW: Defproc for main window of game              }
{ ============================================================= }
{$ToolParms+,$DataBank+}
Procedure DrawBordWindow; {defproc}
var temprect:rect;
begin
   SetRect(temprect,0,0,320,200);
   PPtoPort(@bordLI,temprect,0,0,ModeCopy);
end;
{$ToolParms-,$DataBank-}

procedure endofdeck;
var s:str200;ie:integer;
begin
  initcursor;
  s:=concat('20/',chr(1),'J',chr(1),'%---OUT OF CARDS---/^OK%');
  stuffzeroes(s);speak(26);
  ie:=AlertWindow(1,nil,@s[1]);
  setport(gbordw);beginupdate(gbordw);
  drawbordwindow;endupdate(gbordw);
  action:=0;card:=0;upplayer:=0;
  dofinishline;
end;

function topcard:integer;
var itc:integer;
begin
  if cardsleft=0
   then topcard:=Stop
   else begin
         itc:=myrand(cardsleft);
         topcard:=shuffledeck[itc];
         shuffledeck[itc]:=shuffledeck[cardsleft];
         cardsleft:=cardsleft-1;
        end;
end;

{ ============================================================= }
{  WAITSOUND: Pause game until current sounds finish.           }
{ ============================================================= }
procedure waitsound;
var w:integer;
begin
   repeat until FFsoundDoneStatus(0) and FFSoundDoneStatus(2);
   for w:=1 to soundcount do
       if w in lockedsounds then DisposeHandle(Handle(dh[w]));
   lockedsounds:=[];
end;

function flipacoin:integer;
var s:str200;n,m,o:integer;
begin
   initcursor;
   s:='30/Call the coinflip to see who goes first.../Heads/Tails%';
   stuffzeroes(s);
   n:=Alertwindow(1,nil,@s[1]);
   setport(gbordw);beginupdate(gbordw);
   DrawBordWindow;endupdate(gbordw);
   speak(24);waitsound;
   m:=myrand(2);
   if m=(n+1)
       then begin
               s:=concat('10/Good call!',chr(13),'You go first./^Yay!%');
               stuffzeroes(s);
               o:=Alertwindow(1,nil,@S[1]);flipacoin:=human;
            end
       else begin
               s:=concat('10/Tough luck.',chr(13),'I go first./^Shucks!%');
               stuffzeroes(s);
               o:=Alertwindow(1,nil,@s[1]);flipacoin:=GS;
            end;
   setport(gbordw);beginupdate(gbordw);
   drawbordwindow;endupdate(gbordw);
end;


{ ============================================================= }
{  PAINTONE: Draw graphic #<REZNO> at <X,Y>. If <TOWINDOW>      }
{   is True, put it on the visible screen; if <TOGAME> is       }
{   True, put it on the backup copy of the screen to be         }
{   added next time an update occurs. if <SOUNDNO> is nonzero,  }
{   play that sound while unpacking the graphic.                }
{   MOST IMPORTANTLY, treat all $0 pixels in the graphic as     }
{   transparent.                                                }
{ ============================================================= }
procedure PaintOne(rezno,X,Y:integer;ToWindow,ToGame:boolean;
                       soundno:integer);
var k,l,i1,i2:integer;pa,pb:ptr;p1,p2:^integer;cc:rect;
   r1,r2:longint;
begin
   k:=sizeofpic(rezno);
   packedH:=LoadResource($0BA6,rezno);HLock(packedH);
   pb:=pointer(inH^);pa:=@pb;
   l:=Unpackbytes(packedH^,Loword(gethandlesize(packedH)),Handle(pa),k);
   releaseresource(3,$0BA6,rezno);
   HUnlock(packedH);
   l:=0;k:=sizeofpic(rezno);
   if (rezno<32)
     then begin
           r1:=ord4(inH^);
           r2:=ord4(maskH^);             {figure the transparent mask}
           repeat
               p1:=pointer(r1);p2:=pointer(r2);
               p2^:=tlum[p1^&$00FF]+(tlum[(p1^>>8)&$00FF]<<8);
               r1:=r1+2;r2:=r2+2;
               p1:=pointer(r1);p2:=pointer(r2);
               p2^:=tlum[p1^&$00FF]+(tlum[(p1^>>8)&$00FF]<<8);
               r1:=r1+2;r2:=r2+2;
               p1:=pointer(r1);p2:=pointer(r2);
               p2^:=tlum[p1^&$00FF]+(tlum[(p1^>>8)&$00FF]<<8);
               r1:=r1+2;r2:=r2+2;
               p1:=pointer(r1);p2:=pointer(r2);
               p2^:=tlum[p1^&$00FF]+(tlum[(p1^>>8)&$00FF]<<8);
               r1:=r1+2;r2:=r2+2;
               l:=l+8;
           until l>=k;
          end;
   with PicLI do begin
       ptrtopixelimage:=maskH^;portscb:=$C000;width:=sizes[rezno].width;
       setrect(boundsrect,0,0,sizes[rezno].right,sizes[rezno].bottom);
   end;
   if soundno>0 then speak(soundno);
   if togame then
       begin
           setport(screenport);            {blacken the nontransparent}
           if (rezno<32)
            then pptoport(@PicLI,PicLI.boundsrect,X,Y,modeBIC);    {pixels..}
           picLI.ptrtopixelimage:=inH^;                  {then add the}
           if (rezno>32) and (rezno<52)
            then pptoport(@cbLI,cbLI.boundsrect,X,Y,mode[32]);
           pptoport(@PicLI,picLI.boundsrect,X,Y,mode[rezno]);      {graphic}
       end;
   if towindow
       then begin
              setport(gbordw);picLI.ptrtopixelimage:=maskH^;
              if (rezno<32)
               then pptoport(@PicLI,PicLI.boundsrect,X,Y,modeBIC);
              if (rezno>32) and (rezno<52)
               then pptoport(@cbLI,cbLI.boundsrect,X,Y,mode[32]);
              picLI.ptrtopixelimage:=inH^;
              pptoport(@PicLI,picLI.boundsrect,X,Y,mode[rezno]);
            end;
end;

{Drawing routines}
Procedure Moveacard(x1,y1,x2,y2:integer);
var px,py,dx,dy,nx,ny:integer;pcr,ncr:rect;
begin
   setport(gbordw);
   setpensize(1,1);SetSolidPenPat(15);Setpenmode(modeXOR);
   px:=x1;py:=y1;
   if x1>x2 then dx:=-30 else dx:=30;
   if y1>y2 then dy:=-30 else dy:=30;
   setrect(pcr,px,py,px+67,py+90);
   framerrect(pcr,15,13);ncr:=pcr;
   repeat
       ncr:=pcr;
       if abs(pcr.left-x2)>30 then offsetrect(ncr,dx,0)
                           else offsetrect(ncr,x2-pcr.left,0);
       if abs(pcr.top-y2)>30 then offsetrect(ncr,0,dy)
                           else offsetrect(ncr,0,y2-pcr.top);
       framerrect(ncr,15,13);framerrect(pcr,15,13);pcr:=ncr;
   until (ncr.left=x2) and (ncr.top=y2);
   framerrect(ncr,15,13);
end;

Procedure DrawPlayerHand(movement:boolean;firstcard:integer);
var dh:integer;dr:rect;ds:Str200;
begin
   setport(screenport);
   setsolidbackpat(5);setpenmode(modecopy);
   if firstcard<7 then begin setrect(dr,130,90,220,184);eraserect(dr);end;
   for dh:=firstcard to 7 do
     if Hands[Human,dh]>0
        then begin
              if movement then moveacard(0,50,20*dh-10,94);
              setport(screenport);
              paintone(Hands[Human,dh],20*dh-10,94,movement,true,0);
             end;
   setport(screenport);setrect(dr,200,174,230,184);
   if deckon
    then begin
           if cardsleft>10
               then setsolidbackpat(4) else setsolidbackpat(7);
           eraserect(dr);
           if cardsleft>10 then setforecolor($B) else setforecolor($F);
           settextmode(modeForeCopy);
           ds:=concat(cnvis(cardsleft),'%');stuffzeroes(ds);
           LETextBox2(@ds[1],length(ds)-1,dr,1);
           setpenmode(modeCopy);
           setsolidbackpat(5);
         end
    else eraserect(dr);
   setport(gBordw);
   setrect(dr,0,90,230,190);
   invalrect(dr);
   beginupdate(gBordw);drawbordwindow;endupdate(gBordw);
end;

function pullcard(pc:integer):integer;
var sci,sct:integer;pr:rect;
begin
  sct:=Hands[upplayer,pc];
  if pc<7 then for sci:=pc to 6 do
                   Hands[upplayer,sci]:=Hands[upplayer,sci+1];
  Hands[upplayer,7]:=0;
  if upplayer=Human then begin
                           setport(screenport);
                           setrect(pr,20*pc+12,97,200,179);
                           pptoport(@bordLI,pr,20*pc-8,97,modecopy);
                           Drawplayerhand(false,6);
                           beginupdate(gbordw);drawbordwindow;
                           endupdate(gbordw);
                         end;
  pullcard:=sct;
end;

procedure Drawroad(P:integer);
var xroot,k,L,x1,y1,b1,b2:integer;pa,pb:ptr;
   Drect,Crect:rect;MyClip:RgnHandle;
begin
   waitcursor;
   xroot:=161*p-161;x1:=distance[p] DIV 2;
   setport(screenport);setrect(Drect,xroot,0,xroot+159,89);
   MyClip:=NewRgn;RectRgn(myClip,Drect);
   setclip(MyClip);
   b1:=x1 div 160;b2:=x1 mod 160;
   paintone(53+b1,xroot-b2,0,false,true,0);
   paintone(54+b1,xroot-b2+160,0,false,true,0);
   setrect(Drect,0,0,320,200);
   SetClip(MyRH);
   DisposeRgn(MyClip);
   Case upcard[P] of
       Go:begin
               paintone(20+p,35+Xroot,52,false,true,0);
               paintone(13,105+Xroot,0,false,true,0);
            end;
       0,Gas,Repairs,Stop,Spare:begin
               paintone(20+p,35+Xroot,52,false,true,0);
               paintone(12,105+Xroot,0,false,true,0);
            end;
       Crash:begin
               paintone(26+p,36+Xroot,44,false,true,0);
               paintone(12,105+Xroot,0,false,true,0);
            end;
       Empty:begin
               paintone(24+p,26+Xroot,48,false,true,0);
               paintone(12,105+Xroot,0,false,true,0);
            end;
       Flat:begin
               paintone(22+p,27+Xroot,48,false,true,0);
               paintone(12,105+Xroot,0,false,true,0);
            end;
   end {case};
   if underSL[P] then paintone(14,101+Xroot,35,false,true,0);
   setsolidpenpat(6);setpensize(1,1);setpenmode(modecopy);
   if HasROW[P]
    then begin
           paintone(17,Xroot+140,1,false,true,0);
           if coupROW
               then begin setrect(Crect,xroot+140,1,xroot+155,23);
                       framerect(Crect);end;
         end;
   if HasSS[P]
    then begin
           paintone(18,Xroot+140,23,false,true,0);
           if coupSS
               then begin setrect(Crect,xroot+140,23,xroot+155,45);
                       framerect(Crect);end;
         end;
   if HasEF[P]
    then begin
           paintone(19,Xroot+140,45,false,true,0);
           if coupEF
               then begin setrect(Crect,xroot+140,45,xroot+155,67);
                       framerect(Crect);end;
         end;
   if HasSD[P]
    then begin
           paintone(20,Xroot+140,67,false,true,0);
           if coupSD
               then begin setrect(Crect,xroot+140,67,xroot+155,89);
                       framerect(Crect);end;
         end;
   paintone(11,Xroot+6,26,false,true,0);
   k:=distance[P];y1:=59;
   repeat
       l:=k-(k DIV 10)*10;
       k:=k DIV 10;
       if l=0 then paintone(10,Xroot+6,y1,false,true,0)
              else paintone(l,Xroot+6,y1,false,true,0);
       y1:=y1-9;
   until k=0;
   if distance[P]=1500 then paintone(15,Xroot+125,57,false,true,0);
   if distance[P]=2000 then paintone(16,Xroot+125,57,false,true,0);
   setport(gBordw);setrect(drect,xroot,0,xroot+160,90);
   invalrect(drect);
   beginupdate(gbordw);drawBordwindow;endupdate(gbordw);
   initcursor;
end;

{ ============================================================= }
{  SETUPMENUS: Initialize menu bar.                             }
{ ============================================================= }
procedure setupmenus;
var height:integer;
begin
   setsysbar(CtlRecHndl(newmenubar2(Resourceverb,$0001,nil)));
   setmenubar(nil);
   fixapplemenu(kapplemenu);
   height:=fixmenubar;
   setmenuflag($0080,keditmenu);
   Disablemitem(kbeginitem);
   Disablemitem(kabortitem);
   Disablemitem(krallyitem);
   Disablemitem(kgameitem);
   drawmenubar;
end;

procedure writeMSHOF;
var dparms:destroyOSDCB;cparms:createOSDCB;
    wparms:readwriteOSDCB;oparms:openOSDCB;
    zparms:closeOSDCB;gparms:getfileinfoOSDCB;
    s:GSOSInString;aborting:boolean;w:integer;
begin
    s.thestring:='@:MSHOF';s.size:=7;aborting:=false;
    with gparms do
       begin pcount:=2;pathname:=@s;end;
    GetFileInfoGS(gparms);
    if toolerror<>0
       then begin
              with cparms do
               begin pcount:=5;pathname:=@s;access:=$00C3;
                     filetype:=0;auxtype:=0;storagetype:=1;end;
              CreateGS(cparms);
              aborting:=(toolerror<>0);
             end;
    if not aborting
       then begin
               with oparms do
                   begin pcount:=2;pathname:=@s;refnum:=0;end;
               OpenGS(oparms);
               aborting:=(toolerror<>0);
            end;
    if not aborting
       then begin
              with hofrec do begin
               h1:=humanname;b1:=savable;b2:=coupROW;b3:=coupSS;
               b4:=coupSD;b5:=coupEF;i1:=goesfirst;i2:=upplayer;
               i3:=cardsleft;i4:=ckpoint;i5:=action;i6:=card;
               f1:=hasROW;f2:=hasSS;f3:=hasSD;f4:=hasEF;f5:=underSL;
               f6:=coupable;c1:=score;c2:=upcard;c3:=distance;
               c4:=zooms;c5:=gotchas;a1:=Hands;a2:=Hofname;
               a3:=hofwin;a4:=hoflose;a5:=hofsplit;a6:=shuffledeck;
              end;
              with wparms do
                   begin pcount:=4;refnum:=oparms.refnum;
                         databuffer:=@hofrec;requestcount:=519;
                         transfercount:=0;end;
              writeGS(wparms);
              aborting:=(toolerror<>0);
            end;
    if aborting then begin S1:=concat('34/I had trouble writing MSHOF',
                       ' to disk - the Hall of Fame and',
                       ' saved game are lost. Sorry./^OK%');
                       stuffzeroes(S1);w:=Alertwindow(1,nil,@s1[1]);end
    else begin
           with zparms do begin pcount:=1;refnum:=oparms.refnum;end;
           closeGS(zparms);
         end;
end;
{ ============================================================= }
{  MORESETUP1: Part 2 of 3 initializing stuff -- arrays!!       }
{ ============================================================= }
procedure moresetup1;
var i,j:integer;mytable:Colortable;p1,p2:ptr;
begin
   FFStopsound($7FFF);dph:=sshdl(loadresource($3BA6,1));
   packedH:=LoadResource($0BA7,1);HLock(packedH);
   Sizes:=SizeH(packedH)^^;HUnlock(packedH);
   ReleaseResource(-1,$0BA7,1);
   backH:=NewHandle(32000,gmymemoryID,attrlocked+attrnocross,nil);
   inH:=NewHandle(32000,gmymemoryID,attrlocked+attrnocross,nil);
   maskH:=NewHandle(32000,gmymemoryID,attrlocked+attrnocross,nil);
   cbH:=NewHandle(sizes[32].width*sizes[32].bottom,gmymemoryID,attrlocked,nil);
   packedH:=LoadResource($0BA6,52);   {Load the background screen}
   j:=Sizeofpic(52);HLock(packedH);
   p2:=backH^;p1:=@p2;
   i:=Unpackbytes(packedH^,LoWord(GetHandleSize(packedH)),Handle(p1),j);
   HUnlock(packedH);
   ReleaseResource(-1,$0BA6,52);
   with backLI do begin
       width:=160;portSCB:=$C000;ptrtopixelimage:=backH^;
       setrect(boundsrect,0,0,320,sizes[52].bottom);
   end;
   with tempLI do begin
       width:=160;ptrtopixelimage:=inH^;portSCB:=$C000;
       setrect(boundsrect,0,0,320,200);
   end;
   with CBLI do begin
       width:=sizes[32].width;ptrtopixelimage:=cbH^;portSCB:=$C000;
       setrect(boundsrect,0,0,sizes[32].right,sizes[32].bottom);
   end;
   packedH:=LoadResource($0BA6,32);HLock(PackedH);
   j:=sizeofpic(32);
   p2:=pointer(cbH^);p1:=@p2;
   i:=Unpackbytes(packedH^,LoWord(GetHandleSize(packedH)),Handle(p1),j);
   HUnlock(packedH);releaseresource(-1,$0BA6,32);
   setport(screenport);
   HandtoHand(backH,bordH,160*sizes[52].bottom);
   mytable[0]:=0;mytable[1]:=$0777;mytable[2]:=$0841;mytable[3]:=$072C;
   mytable[4]:=$000F;mytable[5]:=$0080;mytable[6]:=$0F70;mytable[7]:=$0D00;
   mytable[8]:=$0FA9;mytable[9]:=$0FF0;mytable[10]:=$0222;
   mytable[11]:=$04DF;mytable[12]:=$0DAF;mytable[13]:=$078F;
   mytable[14]:=$0CCC;mytable[15]:=$0FFF;
   SETCOLORTABLE(0,mytable);
   for i:=1 to 60 do
    begin
     if i>52 then mode[i]:=modecopy else mode[i]:=modeOR;
     if i=32 then mode[i]:=notBIC;
    end;
end;

{READHALLOFFAME: used by moresetup2 to load old game & hall of fame}
procedure readhalloffame;
var GSn:GSOSInstring;h:integer;oparms:openOSDCB;rparms:readwriteOSDCB;
    cparms:closeOSDCB;
 procedure cleanname(var s:str12);
 var n:integer;
 begin
  for n:=1 to 12 do
   if n=1
    then begin if (s[n]<'{') and (s[n]>chr(96)) then s[n]:=chr(ord(s[n])-32);end
    else if (s[n]<'[') and (s[n]>'@') then s[n]:=chr(ord(s[n])+32);
  while s[length(s)]=' ' do
   s:=copy(s,1,length(s)-1);
 end;
 function ranking(l:integer):real;
 var r1:real;jj:integer;
 begin
   if hofwin[l]+hoflose[l]=0
    then ranking:=-2000000
    else ranking:=hofsplit[l];
 end;
 procedure cleanitup;
 var k,l,k1,k2:integer;s1,s2,stemp:str12;swapped:boolean;rtemp:real;
 begin
  for k1:=1 to 9 do
   begin
    cleanname(hofname[k1]);
    for k2:=k1+1 to 10 do
    begin
     s2:=hofname[k2];cleanname(s2);if s2=hofname[k1]
      then begin
            hofwin[k1]:=hofwin[k1]+hofwin[k2];
            hoflose[k1]:=hoflose[k1]+hoflose[k2];
            hofsplit[k1]:=hofsplit[k1]+hoflose[k2];hofsplit[k2]:=0;
            hofname[k2]:='---';hofwin[k2]:=0;hoflose[k2]:=0;
           end;
    end;
   end;
   cleanname(hofname[10]);
   repeat
    swapped:=false;
    for k:=1 to 9 do
     if (ranking(k)<ranking(k+1))
      then begin
       stemp:=hofname[k];hofname[k]:=hofname[k+1];
       hofname[k+1]:=stemp;l:=hofwin[k];
       hofwin[k]:=hofwin[k+1];hofwin[k+1]:=l;
       l:=hoflose[k];hoflose[k]:=hoflose[k+1];
       hoflose[k+1]:=l;rtemp:=hofsplit[k];
       hofsplit[k]:=hofsplit[k+1];hofsplit[k+1]:=rtemp;
       swapped:=true;
      end;
    until not swapped;
 end;
 procedure errorHOF;
 var s:str200;ig:integer;
 begin
     s:=concat('34/I couldn''t read the file MSHOF. I''l make a ',
               'new one. The old Hall of Fame and saved game are lost.',
               '/^Oh Well%');
     stuffzeroes(s);
     ig:=Alertwindow(1,nil,@s[1]);
 end;
 procedure makeanew;
 var k:integer;
 begin
  humanname:='Human';
  savable:=false;coupROW:=false;coupSS:=false;coupSD:=false;coupEF:=false;
  goesfirst:=0;upplayer:=0;cardsleft:=0;ckpoint:=1500;action:=0;card:=0;
  for k:=1 to 10 do
   begin
     hofname[k]:='---';hofwin[k]:=0;hoflose[k]:=0;hofsplit[k]:=0;
   end;
 end;
 procedure loadvars;
 begin
  with HOFrec do begin
   humanname:=h1;savable:=b1;coupROW:=b2;coupSS:=b3;coupSD:=b4;
   coupEF:=b5;goesfirst:=i1;upplayer:=i2;cardsleft:=i3;ckpoint:=i4;
   action:=i5;card:=i6;hasROW:=f1;hasSS:=f2;hasSD:=f3;hasEF:=f4;
   underSL:=f5;coupable:=f6;score:=c1;upcard:=c2;distance:=c3;
   zooms:=c4;gotchas:=c5;hands:=a1;hofname:=a2;hofwin:=a3;
   hoflose:=a4;hofsplit:=a5;shuffledeck:=a6;
  end;
  if savable
       then setMItemName(@quitsaveline,kquititem)
       else begin goesfirst:=0;upplayer:=0;end;
 end;
begin
 GSn.thestring:='@:MSHOF';GSn.size:=7;
 with oparms do begin pcount:=2;pathname:=@GSn;refnum:=0;end;
 openGS(oparms);
 if toolerror<>0
   then begin errorHOF;makeanew;end
   else begin
         with rparms do
          begin refnum:=oparms.refnum;databuffer:=@HOFrec;
                requestcount:=519;transfercount:=0;pcount:=4;end;
         readGS(rparms);
         if toolerror<>0
           then begin errorHOF;makeanew;end
           else begin
                   loadvars;
                   with cparms do begin pcount:=1;refnum:=oparms.refnum;end;
                   CloseGS(cparms);
                   cleanitup;
                end;
        end;
end;

{ ============================================================= }
{  MORESETUP2: Part 3 of 3 initializing stuff - windows!!!!     }
{ ============================================================= }
procedure moresetup2;
var w:integer;b:byte;mrect:rect;
begin {main dosetup2}
   gbordw:=NewWindow2(nil,0,@drawbordwindow,nil,
                               ResourceVerb,$20000,$800E);
   setport(gbordw);
   mainCH:=NewControl2(gbordw,9,$20000);
   zoomwindow(gbordw);
   drawcontrols(gbordw);
   showpen;
   glastwindow:=gbordw;
   Gameon:=false;Hallon:=false;H000on:=false;
   H001on:=false;Finion:=false;Rllyon:=false;AbtOn:=false;
   for w:=0 to 255 do
       begin
           b:=w;
           if b & $F0 = $00 then tlum[w]:=$00
                            else tlum[w]:=$F0;
           if b & $0F <> $00 then tlum[w]:=tlum[w]+$0F;
       end;
   readhalloffame;
   if humanname<>'Human' then enablemitem(kbeginitem);
   hidecontrol(getctlhandlefromID(gbordw,1));
   if savable
       then begin                    {REDRAW SCREEN OF SAVED GAME}
             paintone(30,235,104,false,true,0);
             drawroad(human);drawroad(GS);
             drawplayerhand(false,1);
            end
       else paintone(31,70,75,false,true,0);       {PAINT TITLE BLOCK}
   for w:=1 to 10 do newdeck[w]:=km50;
   for w:=11 to 20 do newdeck[w]:=km100;
   for w:=21 to 30 do newdeck[w]:=km150;
   for w:=31 to 42 do newdeck[w]:=km200;
   for w:=43 to 46 do newdeck[w]:=km400;
   newdeck[47]:=empty;newdeck[48]:=empty;
   for w:=49 to 54 do newdeck[w]:=gas;newdeck[55]:=EF;
   newdeck[56]:=flat;newdeck[57]:=flat;
   for w:=58 to 63 do newdeck[w]:=spare;newdeck[64]:=SS;
   newdeck[65]:=crash;newdeck[66]:=crash;
   for w:=67 to 72 do newdeck[w]:=repairs;newdeck[73]:=SD;
   for w:=74 to 76 do newdeck[w]:=SL;
   for w:=77 to 82 do newdeck[w]:=EL;
   for w:=83 to 86 do newdeck[w]:=Stop;
   for w:=87 to 100 do newdeck[w]:=Go;newdeck[101]:=ROW;
   value[km50]:=50;value[km100]:=100;value[km150]:=150;
   value[km200]:=200;value[km400]:=400;
   setport(gbordw);setsolidpenpat(15);
end;

{ ============================================================= }
{  INITGLOBALS: Part 1 of 3 initializing stuff                  }
{ ============================================================= }
procedure initglobals;  {establish handles, screens, and game data}
var igi:integer;
begin
   quitsaveline:='Quit & Save';
   myRH:=NewRgn;
   bordH:=newhandle(32000,gmymemoryID,attrlocked+attrnocross,nil);
   setMasterSCB($c000);
   openport(screenport);
   GetVisRgn(myRH);showpen;
   with bordLI do begin
       ptrtopixelimage:=bordH^;portscb:=$c000;width:=160;
       setrect(boundsrect,0,0,320,200);
   end;
   setportloc(bordLI);
   lockedsounds:=[];soundon:=true;deckon:=false;
   cursorvis:=true;gdone:=false;
   moresetup1;
   moresetup2;
end;

{ ============================================================= }
{  "DO" Routines -- for various menu items                      }
{ ============================================================= }

procedure dooops;
var s:Str200;reply:integer;oopr:rect;
begin
   s:='34/';
   s:=concat(S,S1,chr(13),S2,chr(13),S3,'/^OK%');
   stuffzeroes(s);speak(32);
   reply:=Alertwindow(1,nil,@S[1]);
   setrect(oopr,0,90,220,190);
   setport(gBordw);invalrect(oopr);
end;

procedure doabout;
begin
   if abtOn
       then SelectWindow(gAbtw)
       else begin
               waitcursor;
               gAbtw:=NewWindow2(nil,0,@drawabtwindow,nil,
                                        Resourceverb,$13000,$800E);
               setport(gAbtw);
               mainCH:=NewControl2(gAbtw,9,$13000);
               speak(22);
               abton:=true;
               initcursor;
            end;
end;

procedure doabort;
var s:str200;l,reply:integer;cr:rect;
begin
   initcursor;
   s:=concat('34/');
   s:=concat(s,chr(1),'J',chr(1),'%Are you ',chr(1),'C',chr(7),'%SURE ');
   s:=concat(s,chr(1),'C%%you want',chr(13),'to abort this game??');
   s:=concat(s,'/Yes/^No%');l:=length(s);
   stuffzeroes(s);speak(31);
   reply:=AlertWindow(1,nil,@s[1]);
   if reply=0
       then begin
               disablemitem(kabortitem);
               enablemitem(kplayeritem);
               enablemitem(kbeginitem);
               disablemitem(kgameitem);
               disablemitem(krallyitem);
               quitsaveline:='Quit';
               setMItemName(@quitsaveline,kquititem);
               savable:=false;
               setport(gBordw);
               pptoport(@Backli,backli.boundsrect,0,0,modecopy);
               setport(screenport);
               pptoport(@Backli,backli.boundsrect,0,0,modecopy);
               paintone(31,70,75,true,true,0);upplayer:=0;goesfirst:=0;
            end;
end;

procedure dohelp;
var myctlhndl:ctlrechndl;myS:str200; ids:integer;p:pstringptr;jj:integer;
begin {main}
   if h000On
       then SelectWindow(gh000w)
       else begin
               waitcursor;
               gh000w:=NewWindow2(nil,0,@drawh000window,nil,
                                        Resourceverb,$11000,$800E);
               setport(gh000w);
               MainCH:=NewControl2(gh000w,9,$11000);
               speak(23);
               helpsetting:=3;helpshowing:=0;
               H000On:=true;
               initcursor;
            end;
end;

procedure doplayer;
var mylehndl:lerechndl; myctlhndl:ctlrechndl;
      mygs:gsOSInString; code,theID:integer;
      done:boolean; thewindow:grafportptr; ts:string[12];
procedure doplyrcontrol;
var n:integer;
begin
  theid:=loword(gmainevent.Taskdata4);
  case theID of
    1: begin
        myCtlHndl:=GetCtlHandleFromID(gplyrw,3);
        hlock(handle(myctlhndl));
        mylehndl:=lerechndl(myctlhndl^^.ctldata);
        mygs.thestring:='            ';mygs.size:=12;
        if (legettextlen(mylehndl)>0) and (legettextlen(mylehndl)<11)
          then begin
                 blockmove(legettexthand(mylehndl)^,@mygs.thestring,
                                           legettextlen(mylehndl));
                 mygs.size:=legettextlen(mylehndl);
                 ts:=mygs.thestring;
               end
          else humanname:='Human';
        hunlock(handle(myctlhndl));
        for n:=1 to 12 do
         if n=1
           then begin if (ts[n]<'{') and (ts[n]>chr(96))
                        then ts[n]:=chr(ord(ts[n])-32);end
           else if (ts[n]<'[') and (ts[n]>'@')
                 then ts[n]:=chr(ord(ts[n])+32);
        while ts[length(ts)]=' ' do ts:=copy(ts,1,length(ts)-1);
        humanname:=ts;
        closewindow(gplyrw);setport(frontwindow);
        enablemitem(kbeginitem);
       end;
    2: begin closewindow(gplyrw);setport(frontwindow);end;
    otherwise:begin end;
  end {case};
end;
begin
   waitcursor;
   gplyrw:=NewWindow2(nil,0,@drawplyrwindow,nil,Resourceverb,$15000,$800E);
   setport(gplyrw);mainCH:=NewControl2(gplyrw,9,$15000);
   myctlhndl:=getctlhandlefromid(gplyrw,3);
   hlock(handle(myctlhndl));mylehndl:=lerechndl(myctlhndl^^.ctldata);
   mygs.thestring:=humanname;mygs.size:=length(humanname);
   lesettext(@mygs.thestring,mygs.size,mylehndl);
   lesetselect(0,11,mylehndl);hunlock(handle(myctlhndl));
   gmainevent.Taskmask:=$130006;done:=false;
   initcursor;
   repeat
      code:=Taskmaster($FFFF,gmainevent);
      case code of
         winmenubar,winframe,windrag,wincontent,wingoaway,
            winzoom,windesk: SysBeep;
         wincontrol: begin
                      doplyrcontrol;
                      theid:=loword(gmainevent.Taskdata4);
                      if theid<=2 then done:=true;
                     end{wincontrol};
         updateEvt: begin
                     if GrafPortPtr(gmainevent.eventmessage)=gplyrw
                        then begin
                              beginupdate(gplyrw);
                              drawcontrols(gplyrw);
                              endupdate(gplyrw);
                           end;
                  end;
         otherwise: begin end;
      end{case};
   until done;
   gmainevent.taskmask:=$001FFFFF;
end;

procedure dothisgame;
var Game1,Game2,Game3:Handle;myctlhndl:ctlrechndl;s:str200;ig:integer;
begin
     waitcursor;
     ggamew:=NewWindow2(nil,0,@drawgamewindow,nil,
                              Resourceverb,$18000,$800E);
     setport(ggamew);mainCH:=NewControl2(ggamew,9,$18000);
     Game1:=NewHandle(length(Humanname),gmymemoryID,attrpurge2,nil);
     Ptrtohand(@Humanname[1],Game1,length(humanname));
     myctlhndl:=getctlhandlefromID(ggamew,2);
     setctlmoreflags($1001,myctlhndl);
     setctltitle(Game1,myctlhndl);
     s:=concat(chr(1),'J',chr(1),'%',cnvis(score[Human]));
     stuffzeroes(s);
     Game2:=NewHandle(length(s),gmymemoryID,attrpurge2,nil);
     Ptrtohand(@s[1],Game2,length(s));
     myctlhndl:=getctlhandlefromID(ggamew,4);
     setctlmoreflags($1001,myctlhndl);
     setctltitle(Game2,myctlhndl);
     s:=concat(chr(1),'J',chr(1),'%',cnvis(score[GS]));
     stuffzeroes(s);
     Game3:=NewHandle(length(s),gmymemoryID,attrpurge2,nil);
     Ptrtohand(@s[1],Game3,length(s));
     myctlhndl:=getctlhandlefromID(ggamew,5);
     setctlmoreflags($1001,myctlhndl);
     setctltitle(Game3,myctlhndl);
     showwindow(ggamew);
     drawcontrols(ggamew);
     initcursor;
     repeat until button(0);
     ig:=flushevents($0002,0);
     closewindow(ggamew);DisposeHandle(Game1);
     DisposeHandle(Game2);DisposeHandle(Game3);
end;

procedure dothisrally;
Var R1,R2,R3:Handle;myctlhndl:ctlrechndl;s:str200;n:integer;
begin
   waitcursor;
   grllyw:=NewWindow2(nil,0,@drawrllywindow,nil,
                           Resourceverb,$16000,$800E);
   setport(grllyw);mainCH:=NewControl2(grllyw,9,$16000);
   n:=0;if hasROW[human] then n:=100;
   if hasSS[human] then n:=n+100;if hasSD[human] then n:=n+100;
   if hasEF[human] then n:=n+100;
   s:=concat(chr(1),'J',chr(1),'%',cnvis(distance[human]),chr(13),
       cnvis(n),chr(13),cnvis(300*gotchas[human]),chr(13));
   if zooms[human]=0 then s:=concat(s,'Y') else s:=concat(s,'N');
   stuffzeroes(s);
   R1:=Newhandle(length(s),gmymemoryID,attrpurge2,nil);
   Ptrtohand(@s[1],R1,length(s));
   myctlhndl:=getctlhandlefromid(grllyw,3);
   setctlmoreflags($1001,myctlhndl);
   setctltitle(R1,myctlhndl);
   n:=0;if hasROW[GS] then n:=100;
   if hasSS[GS] then n:=n+100;if hasSD[GS] then n:=n+100;
   if hasEF[GS] then n:=n+100;
   s:=concat(chr(1),'J',chr(1),'%',cnvis(distance[GS]),chr(13),
       cnvis(n),chr(13),cnvis(300*gotchas[GS]),chr(13));
   if zooms[GS]=0 then s:=concat(s,'Y') else s:=concat(s,'N');
   stuffzeroes(s);
   R2:=Newhandle(length(s),gmymemoryID,attrpurge2,nil);
   Ptrtohand(@s[1],R2,length(s));
   myctlhndl:=getctlhandlefromid(grllyw,4);
   setctlmoreflags($1001,myctlhndl);
   setctltitle(R2,myctlhndl);
   s:=concat(chr(1),'J',chr(1),'%The Checkpoint is at ',cnvis(ckpoint),
       'km.',chr(13),cnvis(cardsleft),' cards remain in the deck.');
   stuffzeroes(s);
   R3:=Newhandle(length(s),gmymemoryID,attrpurge2,nil);
   Ptrtohand(@s[1],R3,length(s));
   myctlhndl:=getctlhandlefromid(grllyw,7);
   setctlmoreflags($1001,myctlhndl);
   setctltitle(R3,myctlhndl);
   showwindow(grllyw);
   drawcontrols(grllyw);
   initcursor;
   repeat until button(0);
   n:=flushevents($0002,0);
   closewindow(grllyw);DisposeHandle(R1);
   DisposeHandle(R2);DisposeHandle(R3);
end;

procedure dohalloffame;
var myctlhndl:ctlrechndl;myS:str200; ids:integer;
   p:pstringptr;jj:integer;r1:real;
begin
   if hallOn
       then SelectWindow(ghallw)
       else begin
               waitcursor;
               ghallw:=NewWindow2(nil,0,@drawhallwindow,nil,
                                        Resourceverb,$19000,$800E);
               setport(ghallw);
               MainCH:=NewControl2(ghallw,9,$19000);
               myctlhndl:=getctlhandlefromid(ghallw,2);
               myS:=concat(chr(1),chr(74),chr(1));
               for ids:=1 to 10 do
                   if ids=1
                       then myS:=concat(myS,'%',hofname[1])
                       else myS:=concat(myS,chr(13),hofname[ids]);
               myS[4]:=chr(0);
               HallS2:=NewHandle(length(myS),gmymemoryID,attrpurge1,nil);
               PtrtoHand(@mys[1],HallS2,length(myS));
               setctlmoreflags($1001,myctlhndl);
               setctlTitle(HallS2,myctlhndl);
               myctlhndl:=getctlhandlefromid(ghallw,3);
               myS:=concat(chr(1),chr(74),chr(1));
               for ids:=1 to 10 do
                   if ids=1
                       then myS:=concat(myS,'%',cnvis(hofwin[1]),
                                   '-',cnvis(hoflose[1]))
                       else myS:=concat(myS,chr(13),cnvis(hofwin[ids]),
                                   '-',cnvis(hoflose[ids]));
               myS[4]:=chr(0);
               HallS3:=NewHandle(length(myS),gmymemoryID,attrpurge1,nil);
               PtrtoHand(@mys[1],HallS3,length(myS));
               setctlmoreflags($1001,myctlhndl);
               setctlTitle(HallS3,myctlhndl);
               myctlhndl:=getctlhandlefromid(ghallw,4);
               myS:=concat(chr(1),chr(74),chr(1));
               for ids:=1 to 10 do
                 begin
                   jj:=hofwin[ids]+hoflose[ids];
                   if jj<>0
                       then begin r1:=hofwin[ids]+hoflose[ids];
                                  r1:=hofsplit[ids]/r1;jj:=trunc(r1);end;
                   if ids=1
                       then myS:=concat(myS,'%',cnvis(jj))
                       else myS:=concat(myS,chr(13),cnvis(jj));
                 end;
               myS[4]:=chr(0);
               HallS4:=NewHandle(length(myS),gmymemoryID,attrpurge1,nil);
               PtrtoHand(@mys[1],HallS4,length(myS));
               setctlmoreflags($1001,myctlhndl);
               setctlTitle(HallS4,myctlhndl);
               showwindow(ghallw);initcursor;
               hallon:=true;
            end;
end;

{=======================================}
{ GAME PLAYING LOGIC HERE               }
{=======================================}

procedure startarally;
var js:integer;
begin
   waitcursor;waitsound;
   shuffledeck:=newdeck;
   setport(screenport);
   pptoport(@backLI,backli.boundsrect,0,0,modecopy);
   setport(gBordw);
   pptoport(@backLI,backli.boundsrect,0,0,modecopy);
   Paintone(30,235,104,true,true,0);
   cardsleft:=101;ckpoint:=1500;
   for js:=1 to 6 do
       begin Hands[GS,js]:=topcard;Hands[Human,js]:=topcard;end;
   Hands[GS,7]:=0;Hands[Human,7]:=0;
   if (score[GS]=0) and (score[human]=0)
       then goesfirst:=flipacoin;
   upplayer:=goesfirst;
   coupROW:=false;coupSD:=false;coupEF:=false;coupSS:=false;
   for js:=1 to 2 do
       begin
         hasROW[js]:=false;hasSS[js]:=false;hasSD[js]:=false;
         hasEF[js]:=false;underSL[js]:=false;upcard[js]:=0;
         distance[js]:=0;zooms[js]:=0;drawroad(js);action:=0;
         coupable[js]:=false;gotchas[js]:=0;
       end;
   Hands[Upplayer,7]:=topcard;
   drawplayerhand(true,1);
   initcursor;
end;

procedure doquit;
var s:str200;
begin
   if savable
       then begin
               s:=concat('23/Do you want to save this game so that ',
                         'you can continue later?/^Yes/No%');
               stuffzeroes(s);
               savable:=(Alertwindow(1,nil,@s[1])=0);
            end;
   gdone:=true;
end;

procedure dobegin;
begin
   waitcursor;
   score[GS]:=0;score[human]:=0;
   Enablemitem(krallyitem);
   Enablemitem(kgameitem);
   Enablemitem(kabortitem);
   Disablemitem(kbeginitem);
   Disablemitem(kplayeritem);
   quitsaveline:='Quit & Save';
   setmitemname(@quitsaveline,kquititem);
   savable:=true;
   startarally;
end;

procedure GSdecide;
var doneyet:boolean;igs:integer;
 function wherecard(cw:integer):integer;
 var iw,jw:integer;
 begin
  iw:=1;jw:=0;
  repeat
   if Hands[GS,iw]=cw then jw:=iw else iw:=iw+1;
  until jw>0;
  wherecard:=jw;
 end;
 procedure tryplay(ctp:integer);
 begin
  if cardcount(ctp)>0
   then begin
           doneyet:=true;action:=play;
           card:=pullcard(wherecard(ctp));
        end;
 end;
 procedure trydiscard(ctd:integer);
 begin
  if cardcount(ctd)>0
   then begin
           doneyet:=true;action:=discard;
           card:=pullcard(wherecard(ctd));
        end;
 end;
begin
   waitcursor;
   doneyet:=false;
   if ((upcard[GS]=stop) or (underSL[GS])) and cancoup(ROW)
       then begin doneyet:=true;action:=coup;card:=pullcard(wherecard(ROW));end;
   if (not doneyet)
     then if (upcard[GS]=Empty) and cancoup(EF)
       then begin doneyet:=true;action:=coup;card:=pullcard(wherecard(EF));end;
   if (not doneyet)
     then if (upcard[GS]=Crash) and cancoup(SD)
       then begin doneyet:=true;action:=coup;card:=pullcard(wherecard(SD));end;
   if (not doneyet)
     then if (upcard[GS]=Flat) and cancoup(SS)
       then begin doneyet:=true;action:=coup;card:=pullcard(wherecard(SS));end;
   if upcard[GS]=Go
       then begin
               if (not doneyet)
                 then if (cangoout>0)
                 then begin doneyet:=true;action:=play;card:=pullcard(wherecard(cangoout));end;
               if (not doneyet)
                 then if playerclose and (hassafety>0)
                 then begin doneyet:=true;action:=play;card:=pullcard(wherecard(hassafety));end;
               if (not doneyet)
                 then if (not underSL[GS])
                 and (zooms[GS]<2) and (roadleft(GS)>=400)
                 and (Cardcount(km400)>0)
                 then begin doneyet:=true;action:=play;card:=pullcard(wherecard(km400));end
                 else if (roadleft(GS)>=200) and (not underSL[GS]) then tryplay(km200);
               if (not doneyet)
                 then if (upcard[human]<>Go)
                 and (not UnderSL[human]) and (not hasROW[human])
                 then tryplay(SL);
               if upcard[human]=Go
                   then begin
                           if (not doneyet)
                             then if (not hasSS[human]) then tryplay(Flat);
                           if (not doneyet)
                             then if (not hasEF[human]) then tryplay(Empty);
                           if (not doneyet)
                             then if (not hasSD[human]) then tryplay(Crash);
                           if (not doneyet)
                             then if (not hasROW[human]) then tryplay(Stop);
                           if (not doneyet)
                             then if (not hasROW[human])
                              and (not underSL[human])
                              then tryplay(SL);
                        end;
               if (not doneyet)
                 then if UnderSL[GS] then tryplay(EL);
               if (not doneyet)
                 then if UnderSL[GS] then tryplay(ROW);
               if (not doneyet)
                 then if (not UnderSL[GS]) and (Roadleft(GS)>=150)
                 then tryplay(km150);
               if (not doneyet)
                 then if (Roadleft(GS)>=100)
                 then tryplay(km100);
               if (not doneyet) then tryplay(km50);
            end
       else begin
               if (not doneyet)
                 then if playerclose and (hassafety>0)
                 then begin doneyet:=true;action:=play;card:=pullcard(wherecard(hassafety));end;
               if not (upcard[GS] in [0,Stop,Repairs,Spare,Gas])
                 then begin
                       if (not doneyet)
                         then if (upcard[GS]=Crash)
                        then tryplay(Repairs);
                       if (not doneyet)
                         then if (upcard[GS]=Crash)
                        then tryplay(SD);
                       if (not doneyet)
                         then if (upcard[GS]=Empty)
                        then tryplay(Gas);
                       if (not doneyet)
                         then if (upcard[GS]=Empty)
                        then tryplay(EF);
                       if (not doneyet)
                         then if (upcard[GS]=Flat)
                        then tryplay(Spare);
                       if (not doneyet)
                         then if (upcard[GS]=Flat)
                        then tryplay(SS);
                      end
                 else begin
                       if (not doneyet) then tryplay(Go);
                       if (not doneyet) then tryplay(ROW);
                      end;
               if (not doneyet)
                 then if (upcard[human]<>Go)
                 and (not UnderSL[human]) and (not hasROW[human])
                 then tryplay(SL);
               if upcard[human]=Go
                   then begin
                           if (not doneyet)
                             then if (not hasSS[human]) then tryplay(Flat);
                           if (not doneyet)
                             then if (not hasEF[human]) then tryplay(Empty);
                           if (not doneyet)
                             then if (not hasSD[human]) then tryplay(Crash);
                           if (not doneyet)
                             then if (not hasROW[human]) then tryplay(Stop);
                           if (not doneyet)
                             then if (not hasROW[human])
                            and (not underSL[human]) and (RoadLeft(human)>100)
                            then tryplay(SL);
                        end;
               if (not doneyet)
                 then if UnderSL[gs] then tryplay(EL);
               if (not doneyet)
                 then if UnderSL[gs] then tryplay(ROW);
            end;
   if (not doneyet)
     then if hasSD[human] then trydiscard(Crash);
   if (not doneyet)
     then if hasSS[human] then trydiscard(Flat);
   if (not doneyet)
     then if hasEF[human] then trydiscard(Empty);
   if (not doneyet)
     then if hasROW[human] then trydiscard(SL);
   if (not doneyet)
     then if hasROW[human] then trydiscard(stop);
   if (not doneyet)
     then if (Roadleft(GS)<400) then trydiscard(km400);
   if (not doneyet)
     then if(Roadleft(GS)<200) then trydiscard(km200);
   if (not doneyet)
     then if (Roadleft(GS)<150) then trydiscard(km150);
   if (not doneyet)
     then if (Roadleft(GS)<100) then trydiscard(km100);
   if (not doneyet) then trydiscard(km50);
   if (not doneyet)
     then if (Zooms[GS]=2) then trydiscard(km400);
   if (not doneyet)
     then if (hasSD[GS] or (cardcount(SD)=1)) then trydiscard(Repairs);
   if (not doneyet)
     then if (hasSS[GS] or (cardcount(SS)=1)) then trydiscard(Spare);
   if (not doneyet)
     then if (hasEF[GS] or (cardcount(EF)=1)) then trydiscard(Gas);
   if (not doneyet)
     then if (hasROW[GS] or (cardcount(ROW)=1)) then trydiscard(EL);
   if (not doneyet)
     then if (hasROW[GS] or (cardcount(ROW)=1)) then trydiscard(Go);
   if (not doneyet) then trydiscard(km50);
   if (not doneyet) then trydiscard(km100);
   if (not doneyet) then trydiscard(km150);
   if (not doneyet)
     then if (cardcount(EL)>1) then trydiscard(EL);
   if (not doneyet)
     then if (cardcount(Repairs)>1) then trydiscard(Repairs);
   if (not doneyet)
     then if (cardcount(Spare)>1) then trydiscard(Spare);
   if (not doneyet)
     then if (Cardcount(Gas)>1) then trydiscard(Gas);
   if (not doneyet)
     then if (cardcount(Go)>2) then trydiscard(Go);
   if (not doneyet) then trydiscard(km200);
   if (not doneyet) then trydiscard(km400);
   if (not doneyet)
     then if (not isapower(Hands[GS,7])) then trydiscard(Hands[GS,7]);
   if (not doneyet)
    then begin
           igs:=1;
           repeat
               if isapower(Hands[GS,igs]) then igs:=igs+1 else trydiscard(Hands[GS,igs]);
           until doneyet;
         end;
   initcursor;
end;

procedure togglesound;
begin
  if soundon
    then begin
      soundline:='Turn Sound On';soundon:=false;
      setMitemName(@soundline,ksounditem);
      end
    else begin
      soundline:='Turn Sound Off';soundon:=true;
      setMitemName(@soundline,ksounditem);
      end;
end;
procedure toggledeck;
begin
  waitcursor;
  if deckon
    then begin
      deckline:='Turn DeckCount On';deckon:=false;
      setMitemName(@deckline,kdeckitem);
      end
    else begin
      deckline:='Turn DeckCount Off';deckon:=true;
      setMitemName(@deckline,kdeckitem);
      end;
  if upplayer>0 then drawplayerhand(false,6);
  initcursor;
end;


{ ============================================================= }
{  HANDLEMENU: Take care of menu events.                        }
{ ============================================================= }
procedure handlemenu;
var themenu,theitem:integer;
begin
   themenu:=hiword(gmainevent.taskdata);
   theitem:=loword(gmainevent.taskdata);
   case theitem of
      kquititem: doquit;
      kaboutitem: doabout;
      kbeginitem: dobegin;
      kabortitem: doabort;
      khelpitem: dohelp;
      kplayeritem: doplayer;
      kgameitem: dothisgame;
      krallyitem: dothisrally;
      khallitem: dohalloffame;
      ksounditem: togglesound;
      kdeckitem: toggledeck;
      otherwise: begin end;
   end;
   hilitemenu(false,themenu);
end;

procedure docontrols;
var myctlhndl:ctlrechndl;theID:integer;mylehndl:LERecHndl;
   mygs:gsOSInString;q:integer;ts:string[12];jj:integer;
begin
   theID:=loword(gmainevent.taskdata4);
   if (glastwindow=gabtw) and (theID=1) and abton
       then begin closewindow(gabtw);
               abton:=false;end;
   if (glastwindow=ghallw) and (theID=1) and hallon
       then begin
               Closewindow(ghallw);
               Disposehandle(HallS2);DisposeHandle(Halls3);
               DisposeHandle(HallS4);
               hallon:=false;
            end;
   if (glastwindow=gH000w) and H000on
       then case theID of
               1: if h001on
                   then begin
                         setport(gH001w);
                         HideControl(getctlhandlefromID(gH001w,helpshowing+1));
                         DisposeControl(getctlhandlefromID(gH001w,helpshowing+1));
                         mainCH:=NewControl2(gH001w,2,$42000+helpsetting);
                         helpshowing:=helpsetting;
                         selectwindow(gH001w);
                        end
                   else begin
                         gH001w:=NewWindow2(nil,0,@drawH001window,nil,
                                       ResourceVerb,$12000,$800E);
                         setport(gH001w);
                         mainCH:=NewControl2(gH001w,2,$42000);
                         mainCH:=NewControl2(gH001w,2,$42001);
                         mainCH:=NewControl2(gH001w,2,$42002);
                         mainCH:=NewControl2(gH001w,2,$42000+helpsetting);
                         helpshowing:=helpsetting;
                         showwindow(gH001w);
                         h001on:=true;
                        end;
               2: begin closewindow(gH000w);H000on:=false;
                   if H001on then closewindow(gH001w);
                   h001on:=false;
                  end;
               otherwise: if (theID>2) and (theID<25)
                           then helpsetting:=theID;
            end{case};
   if (glastwindow=gH001w) and H001on
       then case theID of
             1: begin closewindow(gH001w);h001on:=false;end;
             2: If helpshowing>3
                 then begin
                       Setport(gH001w);
                       Hidecontrol(getctlhandlefromid(gH001w,helpshowing+1));
                       Disposecontrol(getctlhandlefromid(gH001w,helpshowing+1));
                       helpshowing:=helpshowing-1;
                       MainCH:=Newcontrol2(gH001w,2,$42000+helpshowing);
                       ShowControl(MainCH);
                      end
                 else sysbeep;
             3:  If helpshowing<24
                 then begin
                       Setport(gH001w);
                       Hidecontrol(getctlhandlefromid(gH001w,helpshowing+1));
                       Disposecontrol(getctlhandlefromid(gH001w,helpshowing+1));
                       helpshowing:=helpshowing+1;
                       MainCH:=Newcontrol2(gH001w,2,$42000+helpshowing);
                       ShowControl(MainCH);
                      end
                 else sysbeep;
             otherwise: begin end;
            end{case};
end;

procedure checkboard;
var p,np:point;cbr:rect;wc,targ,icb:integer;
 function whichcard:integer;
 var ww,c1:integer;
 begin
   ww:=0;c1:=(p.h+10) div 20;
   if (p.v>94) and (p.v<184)
       then if (c1>0) and (c1<7)
               then ww:=c1
               else if (p.h>130) and (p.h<197) then ww:=7;
   whichcard:=ww;
 end;
 function whichrect:integer;
 var ww,c1:integer;
 begin
   ww:=0;
   if (p.v<90)
       then if p.h<160 then ww:=8 else ww:=9
       else if (p.h>235) then ww:=10
                         else begin
                               c1:=(p.h+10) div 20;
                               if c1>7 then c1:=7;
                               if c1<1 then c1:=1;
                               ww:=c1;
                              end;
   whichrect:=ww;
 end;
 procedure checkhelpplay(cn:integer);
 begin
   case Hands[Human,cn] of
     km50,km100,km150,km200,km400:if upcard[human]<>Go
           then begin
                   S1:='You cannot play distance';
                   S2:='cards until you fix your';
                   S3:='problem & get a green light.';dooops;
                end
           else if ckpoint-distance[Human]<value[Hands[Human,cn]]
                   then begin
                           S1:='That would take you past the';
                           S2:='checkpoint -- you must reach';
                           S3:=concat(cnvis(ckpoint),' exactly.');
                           dooops;
                        end
                   else if underSL[human] and (Value[Hands[Human,cn]]>100)
                           then begin
                                 S1:='You have a Speed Limit! You';
                                 S2:='can only play 50km or 100km';
                                 S3:='Distance Cards.';dooops;
                                end
                           else if (Hands[Human,cn]=km400) and (zooms[human]=2)
                                   then begin
                                         S1:='You have already played two';
                                         S2:='400km cards this rally.';
                                         S3:='Two is the limit.';
                                         dooops;
                                        end
                                   else begin action:=play;card:=pullcard(cn);end;
     Gas:if upcard[human]<>Empty
           then begin S1:='That card only works';
                 S2:='when you are out of gas.';
                 S3:='It won''t help now.';dooops;end
           else begin action:=play;card:=pullcard(cn);end;
     Repairs:if upcard[human]<>Crash
           then begin S1:='That card only works';
                      S2:='when you have crashed.';
                      S3:='It won''t help now.';dooops;end
           else begin action:=play;card:=pullcard(cn);end;
     Spare:if upcard[human]<>Flat
           then begin S1:='That card only works';
                      S2:='when you have a flat tire.';
                      S3:='It won''t help now.';dooops;end
           else begin action:=play;card:=pullcard(cn);end;
     EL:if not underSL[human]
           then begin S1:='That card is not needed';
                      S2:='unless you are under a';
                      S3:='Speed Limit.';dooops;end
           else begin action:=play;card:=pullcard(cn);end;
     Go:if not (upcard[Human] in [0,Gas,Repairs,Spare,Stop])
           then begin S1:='Go! is only useful when';
                      S2:='your car is OK and the';
                      S3:='light is red.';dooops;end
           else begin action:=play;card:=pullcard(cn);end;
     Crash,SL,Stop,Flat,Empty:begin
                               S1:='That''s a PROBLEM card!!';
                               S2:='What are you doing, trying';
                               S3:='to throw the rally??';
                               dooops;
                              end;;
     ROW:if ((upcard[Human]=Stop) or UnderSL[Human])
          and Coupable[Human] and (cn<7)
           then begin action:=coup;card:=pullcard(cn);end
           else begin action:=play;card:=pullcard(cn);end;
     SD:if (upcard[Human]=Crash) and Coupable[Human] and (cn<7)
           then begin action:=coup;card:=pullcard(cn);end
           else begin action:=play;card:=pullcard(cn);end;
     EF:if (upcard[Human]=Empty) and Coupable[Human] and (cn<7)
           then begin action:=coup;card:=pullcard(cn);end
           else begin action:=play;card:=pullcard(cn);end;
     SS:if (upcard[Human]=Flat) and Coupable[Human] and (cn<7)
           then begin action:=coup;card:=pullcard(cn);end
           else begin action:=play;card:=pullcard(cn);end;
     otherwise:begin end;
   end{case};
 end;
 procedure checkhurtplay(cn:integer);
 begin
   case Hands[Human,cn] of
     SL:if hasROW[GS]
           then begin s1:='The GS has Right Of Way';
                   s2:='and is immune to';
                   s3:='Speed Limit cards.';dooops;end
           else if undersl[GS]
                  then begin S1:='The GS is already under';
                         S2:='a Speed Limit.';S3:='Wait until it ends.';
                         dooops;end
                  else begin action:=play;card:=pullcard(cn);end;
     Crash:if hasSD[GS]
             then begin S1:='The GS has Super Driver';
                    S2:='and is immune to';S3:='Crash cards.';dooops;end
             else if upcard[GS]<>Go
                   then begin S1:='You may not play that';
                           S2:='problem unless the';
                           S3:='GS has a green light.';dooops;end
                   else begin action:=play;card:=pullcard(cn);end;
     Flat:if hasSS[GS]
             then begin S1:='The GS has Self-Sealer';
                   S2:='and is immune to';S3:='Flat cards.';dooops;end
             else if upcard[GS]<>Go
                   then begin S1:='You may not play that';
                          S2:='problem unless the';
                          S3:='GS has a green light.';dooops;end
                   else begin action:=play;card:=pullcard(cn);end;
     Empty:if hasEF[GS]
             then begin S1:='The GS has Extra Fuel';
                   S2:='and is immune to';S3:='Empty cards.';dooops;end
             else if upcard[GS]<>Go
                   then begin S1:='You may not play that';
                         S2:='problem unless the';
                         S3:='GS has a green light.';dooops;end
                   else begin action:=play;card:=pullcard(cn);end;
     Stop:if hasROW[GS]
             then begin S1:='The GS has Right of Way';
                   S2:='and is immune to';S3:='Stop cards.';dooops;end
             else if upcard[GS]<>Go
                   then begin S1:='You may not play that';
                         S2:='problem unless the';
                         S3:='GS has a green light.';dooops;end
                   else begin action:=play;card:=pullcard(cn);end;
     otherwise:begin
                 S1:='That card may not be';
                 S2:='played on your opponent.';
                 S3:='Use it to help yourself.';
                 dooops;
               end;
   end{case};
 end;
 procedure sortcards;
 var temp,m:integer;
 begin
  waitcursor;
  if wc<>targ
   then if wc<targ
         then begin
               temp:=hands[Human,wc];
               for m:=wc to targ-1 do hands[Human,m]:=hands[Human,m+1];
               hands[Human,targ]:=temp;
              end
         else begin
               temp:=hands[Human,wc];
               for m:=wc downto targ+1 do hands[Human,m]:=hands[Human,m-1];
               hands[Human,targ]:=temp;
              end;
  if wc<targ then drawplayerhand(false,wc) else drawplayerhand(false,targ);
  initcursor;
  end;
begin {main checkboard}
   p:=gmainevent.eventwhere;
   p.v:=p.v-13;
   wc:=whichcard;
   if wc>0
       then begin
               paintone(Hands[Human,wc],20*wc-10,94,true,false,0);
               setport(gbordw);
               setrect(cbr,20*wc-10,94,20*wc+57,184);
               setsolidpenpat(4);setpenmode(modeCopy);
               setpensize(3,3);framerrect(cbr,15,13);
               setsolidpenpat(15);setpenmode(modeXOr);
               setpensize(1,1);framerrect(cbr,15,13);
               while not GetNextEvent(mUpMask,gMainEvent) do begin
                   np:=gMainEvent.eventwhere;
                   np.v:=np.v-13;
                   if (np.h<>p.h) or (np.v<>p.v)
                     then begin
                            framerrect(cbr,15,13);
                            offsetrect(cbr,np.h-p.h,np.v-p.v);
                            framerrect(cbr,15,13);
                            p:=np;
                          end;
               end{while};
               framerrect(cbr,15,13);
               targ:=whichrect;
               case targ of
                 8:begin
                     checkhelpplay(wc);
                     if action=play
                         then paintone(card,47,0,true,false,card-32);
                   end;
                 9:begin
                     checkhurtplay(wc);
                     if action>0
                         then paintone(card,207,0,true,false,card-32);
                   end;
                 10:begin action:=discard;card:=pullcard(wc);
                    end;
                 otherwise:begin
                             sortcards;
                             setrect(cbr,0,90,220,186);setport(gbordw);
                             invalrect(cbr);
                             beginupdate(gbordw);drawbordwindow;
                             endupdate(gbordw);
                           end;
               end;
            end {if};
end;

{ ============================================================= }
{  CHECKFRONTW: Get rid of NDAs when game is in progress. Our   }
{    window isn't movable, so NDA windows will disappear.       }
{    Let NDAs have access to the Edit menu.                     }
{ ============================================================= }
procedure checkfrontw;
var thewindow:grafportptr;
procedure editoff;
begin
  setmenuflag($0080,keditmenu);
  drawmenubar;
end;
procedure editon;
begin
  setmenuflag($FF7F,keditmenu);
  drawmenubar;
end;
begin {main checkfrontw}
   thewindow:=grafportptr(gmainevent.eventmessage);
   if (gmainevent.eventmodifiers & $0001) = 0
       then editon
       else begin
               if thewindow=nil
                   then editoff
                   else if getsyswflag(thewindow)=true
                        then editon
                        else editoff;
               glastwindow:=thewindow;
            end;
end;

procedure closeawindow;
var myctlhndl:ctlrechndl;
begin
   waitcursor;
   if (glastwindow=ghallw) and hallon
       then begin
               closewindow(ghallw);
               Disposehandle(HallS2);DisposeHandle(Halls3);
               DisposeHandle(HallS4);
               hallon:=false;end;
  if (glastwindow=gH000w) and H000on
       then begin closewindow(gH000w);H000on:=false;
                   if H001on then closewindow(gH001w);
                   h001on:=false;
                  end;
  if (glastwindow=gH001w) and H001on
       then begin closewindow(gH001w);h001on:=false;end;
  initcursor;
end;
{ ================================== }
{ SHOW routines: do card effects     }
{ ================================== }

procedure dofinishline;
var myctlhndl:ctlrechndl;myS:str200;swapped:boolean;
    idf,k,l,winner,jj,jk,jl,jm,finalH,finalG:integer;p:pstringptr;
    stemp:Str200;rtemp:real;
 function avgsplit(l:integer):integer;
 var r1:real;jj:integer;
 begin
   if hofwin[l]+hoflose[l]=0
    then avgsplit:=0
    else begin jj:=hofwin[l]+hoflose[l];
               r1:=hofsplit[l]/jj;avgsplit:=trunc(r1);end;
 end;
 function ranking(l:integer):real;
 var r1:real;jj:integer;
 begin
   if hofwin[l]+hoflose[l]=0
    then ranking:=-2000000
    else ranking:=hofsplit[l];
 end;
 procedure cleanuphof;
 var lineno,k:integer;
 begin
   if ((score[GS]>=5000) or (score[Human]>=5000))
      and (score[GS]<>score[Human])
      then begin
             if score[GS]>score[Human]
              then winner:=GS else winner:=Human;
             setport(gBordw);
             beginupdate(gBordw);drawbordwindow;endupdate(gBordw);
             paintone(29,winner*160-105,19,true,true,0);
             lineno:=0;
             For k:=1 to 10 do
              if (hofname[k]<>'Human') and (hofname[k]=humanname)
                  then lineno:=k;
             if lineno>0
              then begin
                    if winner=Human then hofwin[lineno]:=hofwin[lineno]+1
                                    else hoflose[lineno]:=hoflose[lineno]+1;
                    hofsplit[lineno]:=hofsplit[lineno]+score[human]-score[GS];
                    repeat
                       swapped:=false;
                       for k:=1 to 9 do
                         if (ranking(k)<ranking(k+1))
                          then begin
                                stemp:=hofname[k];hofname[k]:=hofname[k+1];
                                hofname[k+1]:=stemp;l:=hofwin[k];
                                hofwin[k]:=hofwin[k+1];hofwin[k+1]:=l;
                                l:=hoflose[k];hoflose[k]:=hoflose[k+1];
                                hoflose[k+1]:=l;rtemp:=hofsplit[k];
                                hofsplit[k]:=hofsplit[k+1];hofsplit[k+1]:=rtemp;
                                swapped:=true;
                               end;
                    until not swapped;
                   end
              else begin
                    lineno:=0;
                    for k:=10 downto 1 do
                     if (hofwin[k]+hoflose[k]=0)
                      or (avgsplit(k)<(score[human]-score[GS]))
                      then lineno:=k;
                    if lineno>0
                      then begin
                             for k:=9 downto lineno do
                              begin
                               hofname[k+1]:=hofname[k];
                               hofwin[k+1]:=hofwin[k];
                               hoflose[k+1]:=hoflose[k];
                               hofsplit[k+1]:=hofsplit[k];
                              end;
                             hofname[lineno]:=humanname;
                             hofsplit[lineno]:=score[human]-score[gs];
                             if winner=Human then begin hofwin[lineno]:=1;
                                                        hoflose[lineno]:=0;end
                                             else begin hoflose[lineno]:=1;
                                                        hofwin[lineno]:=0;end;
                           end;
                   end;
           end
      else begin
             winner:=0;goesfirst:=3-goesfirst;
             startarally;
           end;
 end;
begin {main dofinishline}
        waitcursor;
        gFiniw:=NewWIndow2(nil,0,@drawFiniwindow,nil,
                      Resourceverb,$1B000,$800E);
        setport(gFiniw);
        mainCH:=NewControl2(gFiniw,9,$1B000);
        speak(28);
        myctlhndl:=getctlhandlefromID(gFiniw,3);
        myS:=concat(chr(1),chr(74),chr(1),'%');
        myS:=concat(myS,cnvis(score[human]),chr(13),
                   cnvis(distance[human] DIV 2),chr(13));
        jj:=0;
        if hasROW[human] then jj:=jj+100;if hasSS[human] then jj:=jj+100;
        if hasSD[human] then jj:=jj+100;if hasEF[human] then jj:=jj+100;
        if jj=400 then jj:=700;
        myS:=concat(myS,cnvis(jj),chr(13),cnvis(gotchas[human]*300),chr(13));
        if distance[human]=ckpoint
          then begin
                if ckpoint=1500 then jk:=400 else jk:=600;
                if zooms[human]=0 then jl:=300 else jl:=0;
                if distance[GS]=0 then jm:=500 else jm:=0;
               end
          else begin jk:=0;jl:=0;jm:=0;end;
        finalH:=score[human]+(distance[human] DIV 2)
                   +jj+Gotchas[Human]*300+jk+jl+jm;
        myS:=concat(myS,cnvis(jk),chr(13),cnvis(jl),chr(13),
                      cnvis(jm),chr(13),chr(13),
                      cnvis(finalH));
        stuffzeroes(myS);
        FiniS1:=NewHandle(length(myS),gmymemoryID,attrpurge2,nil);
        PtrtoHand(@myS[1],FiniS1,length(myS));
        setctlmoreflags($1001,myctlhndl);
        setctltitle(FiniS1,myctlhndl);
        myctlhndl:=getctlhandlefromID(gFiniw,4);
        myS:=concat(chr(1),chr(74),chr(1),'%');
        myS:=concat(myS,cnvis(score[GS]),chr(13),
                   cnvis(distance[GS] DIV 2),chr(13));
        jj:=0;
        if hasROW[GS] then jj:=jj+100;if hasSS[GS] then jj:=jj+100;
        if hasSD[GS] then jj:=jj+100;if hasEF[GS] then jj:=jj+100;
        if jj=400 then jj:=700;
        myS:=concat(myS,cnvis(jj),chr(13),cnvis(gotchas[GS]*300),chr(13));
        if distance[GS]=ckpoint
          then begin
                if ckpoint=1500 then jk:=400 else jk:=600;
                if zooms[GS]=0 then jl:=300 else jl:=0;
                if distance[human]=0 then jm:=500 else jm:=0;
               end
          else begin jk:=0;jl:=0;jm:=0;end;
        finalG:=score[GS]+(distance[GS] DIV 2)+jj+gotchas[GS]*300+jk+jl+jm;
        myS:=concat(myS,cnvis(jk),chr(13),cnvis(jl),chr(13),
                      cnvis(jm),chr(13),chr(13),
                      cnvis(FinalG));
        stuffzeroes(myS);
        FiniS2:=NewHandle(length(myS),gmymemoryID,attrpurge2,nil);
        PtrtoHand(@myS[1],FiniS2,length(myS));
        setctlmoreflags($1001,myctlhndl);
        setctltitle(FiniS2,myctlhndl);
        myctlHndl:=getctlhandlefromID(gfiniw,5);
        myS:=humanname;
        FiniS3:=NewHandle(length(myS),gmymemoryID,attrpurge2,nil);
        PtrtoHand(@myS[1],FiniS3,length(myS));
        setctlmoreflags($1001,myctlhndl);
        setctltitle(FiniS3,myctlhndl);
        showwindow(gFiniw);
        drawcontrols(gFiniw);initcursor;
        Finion:=true;initcursor;
        repeat until button(0);
        jj:=flushevents($0002,0);
        waitcursor;
        Closewindow(gFiniw);
        DisposeHandle(FiniS1);DisposeHandle(FiniS2);
        DisposeHandle(FiniS3);
        Finion:=false;
        score[GS]:=finalG;score[Human]:=FinalH;
        cleanuphof;initcursor;
        case winner of
           Human:begin
                   speak(29);
                   stemp:=concat('20/Congratulations!',chr(13),'You won!/^Thanks%');
                   stuffzeroes(stemp);
                   k:=Alertwindow(1,nil,@stemp[1]);
                 end;
           GS:begin
                speak(21);
                stemp:=concat('20/I win!',chr(13),'Thanks for the game!/^Sigh%');
                stuffzeroes(stemp);
                k:=Alertwindow(1,nil,@stemp[1]);
              end;
           otherwise:begin end;
        end;
        if winner>0
          then begin
                 disablemitem(kabortitem);disablemitem(kgameitem);
                 disablemitem(krallyitem);enablemitem(kplayeritem);
                 enablemitem(kbeginitem);upplayer:=0;savable:=false;
                 goesfirst:=0;quitsaveline:='Quit';
                 setMitemname(@quitsaveline,kquititem);
                 paintone(31,70,75,true,true,0);
               end;
end;

procedure askatckpt;
var s:string[1000];reply,a,b,i:integer;
begin
 waitcursor;
 s:=concat('80/',chr(1),'J',chr(1),'%Congratulations on reaching',chr(13),
           'the Checkpoint!',chr(13),chr(13),'You can stop now for a 400-pt',
           chr(13),'bonus, or try to reach 2000km',chr(13),
           'for a 600-point bonus.',chr(13),chr(13));
 s:=concat(s,'The deck has ',cnvis(cardsleft),' cards left.',chr(13));
 a:=score[Human]+750+300*Gotchas[Human];
 b:=score[GS]+(distance[GS] DIV 2)+300*Gotchas[GS];
 if distance[GS]=0 then a:=a+500;
 if hasROW[human] then a:=a+100;
 if hasSS[human] then a:=a+100;
 if hasSD[human] then a:=a+100;
 if hasEF[human] then a:=a+100;
 if hasROW[human] and hasSS[human] and hasSD[human] and hasEF[human]
   then a:=a+300;
 if zooms[human]=0 then a:=a+300;
 if hasROW[GS] then b:=b+100;
 if hasSS[GS] then b:=b+100;
 if hasSD[GS] then b:=b+100;
 if hasEF[GS] then b:=b+100;
 if hasROW[GS] and hasSS[GS] and hasSD[GS] and hasEF[GS]
   then b:=b+300;
 s:=concat(s,'Score: ',Humanname,'=',cnvis(a),',GS=',cnvis(b),'.');
 s:=concat(s,'/Stop here/Go for 2000%');
 for i:=1 to length(s) do if s[i]='%' then s[i]:=chr(0);
 initcursor;speak(27);
 reply:=Alertwindow(1,nil,@s[1]);
 setport(gbordw);beginupdate(gbordw);
 drawbordwindow;endupdate(gbordw);
 if reply=1 then begin
                   ckpoint:=2000;
                   upplayer:=GS;
                   Hands[GS,7]:=topcard;
                 end
            else dofinishline;
end;

procedure GSmaybegoon;
var a,b,i:integer;s:str200;
begin
 a:=score[Human]+(distance[Human] DIV 2)+300*Gotchas[Human];
 b:=score[GS]+(distance[GS] DIV 2)+300*Gotchas[GS];
 if distance[human]=0 then b:=b+500;
 if hasROW[human] then a:=a+100;
 if hasSS[human] then a:=a+100;
 if hasSD[human] then a:=a+100;
 if hasEF[human] then a:=a+100;
 if hasROW[human] and hasSS[human] and hasSD[human] and hasEF[human]
   then a:=a+300;
 if zooms[GS]=0 then b:=b+300;
 if hasROW[GS] then b:=b+100;
 if hasSS[GS] then b:=b+100;
 if hasSD[GS] then b:=b+100;
 if hasEF[GS] then b:=b+100;
 if hasROW[GS] and hasSS[GS] and hasSD[GS] and hasEF[GS]
   then b:=b+300;
 if ckpoint=1500 then b:=b+400 else b:=b+600;
 if ((b>=5000) and (b>=a)) or (ckpoint=2000) or (cardsleft<31)
  or (distance[human]>1000)
   then dofinishline
   else begin
         s:='20/I''m going for 2000!!/^OK%';stuffzeroes(s);
         initcursor;
         a:=Alertwindow(1,nil,@s[1]);
         setport(gbordw);beginupdate(gbordw);
         drawbordwindow;endupdate(gbordw);
         ckpoint:=2000;
         upplayer:=Human;
         Hands[human,7]:=topcard;
         Moveacard(0,50,130,94);
         paintone(Hands[Human,7],130,94,true,true,0);
        end;
end;

procedure endturn;
var se:str200;
begin
  waitsound;
  if distance[upplayer]=ckpoint
   then begin
          if ckpoint=1500
              then if upplayer=Human
                     then askatckpt else GSmaybegoon
              else dofinishline;
        end
   else if cardsleft=0
        then endofdeck
        else begin
              upplayer:=3-upplayer;
              Hands[upplayer,7]:=topcard;
              if upplayer=Human then begin
                                      Moveacard(0,50,130,94);
                                      paintone(Hands[Human,7],130,94,true,true,0);
                                      drawplayerhand(false,7);
                                      initcursor;
                                     end
                                else waitcursor;
             end;
end;

procedure showcoup;
var cv,sci:integer;sr:rect;
begin
  cv:=card;waitcursor;
  paintone(cv,160*upplayer-113,0,true,false,19+upplayer);
  Case cv of
   ROW:begin
        hasROW[upplayer]:=true;gotchas[upplayer]:=Gotchas[upplayer]+1;
        if undersl[upplayer] and (upcard[upplayer] in [crash,flat,empty])
          then begin undersl[upplayer]:=false;coupROW:=true;end
          else begin upcard[upplayer]:=Go;underSL[upplayer]:=false;
                       coupROW:=true;end
       end;
   SD: begin
        hasSD[upplayer]:=true;gotchas[upplayer]:=gotchas[upplayer]+1;
        upcard[upplayer]:=Go;coupSD:=true;
       end;
   SS: begin
        hasSS[upplayer]:=true;gotchas[upplayer]:=gotchas[upplayer]+1;
        upcard[upplayer]:=Go;coupSS:=true;
       end;
   EF: begin
        hasEF[upplayer]:=true;gotchas[upplayer]:=gotchas[upplayer]+1;
        upcard[upplayer]:=Go;coupEF:=true;
       end;
   otherwise:begin end;
  end{case};
  Drawroad(upplayer);coupable[upplayer]:=false;
 if cardsleft<=0
 then endturn
 else begin
  Hands[upplayer,7]:=topcard;
  if upplayer=Human then begin
                            Moveacard(0,50,130,94);
                            paintone(Hands[Human,7],130,94,true,true,0);
                          end;
      end;
  action:=0;card:=0;
end;

procedure showplay;
var cv,spi:integer;sr:rect;
begin
  cv:=card;waitcursor;
  coupable[upplayer]:=false;
  case cv of
   Go,Gas,Spare,Repairs:begin
                         if upplayer=GS
                          then begin Moveacard(150,-64,207,0);
                                 paintone(cv,207,0,true,false,cv-32);end;
                         upcard[upplayer]:=cv;
                         if HasROW[upplayer] then upcard[upplayer]:=Go;
                         drawroad(upplayer);
                        end;
   Empty,Flat,Stop,Crash:begin
                             if upplayer=GS
                              then begin Moveacard(150,-64,47,0);
                                     paintone(cv,47,0,true,false,cv-32);end;
                             upcard[3-upplayer]:=cv;
                             coupable[3-upplayer]:=true;
                             drawroad(3-upplayer);
                            end;
   km50,km100,km150,km200,km400:begin
                                 if upplayer=GS
                                  then begin Moveacard(150,-64,207,0);
                                         paintone(cv,207,0,true,false,cv-32);end;
                                 distance[upplayer]:=distance[upplayer]
                                                      +value[cv];
                                 if cv=km400 then zooms[upplayer]:=zooms[upplayer]+1;
                                 drawroad(upplayer);
                                end;
   EL:begin
       if upplayer=GS then begin Moveacard(150,-64,207,0);
                             paintone(cv,207,0,true,false,7);end;
       underSL[upplayer]:=false;
       drawroad(upplayer);
      end;
   SL:begin
       if upplayer=GS then begin Moveacard(150,-64,47,0);
                             paintone(cv,47,0,true,false,6);end;
       underSL[3-upplayer]:=true;coupable[3-upplayer]:=true;
       drawroad(3-upplayer);
      end;
   ROW:begin
        if upplayer=GS then begin Moveacard(150,-64,207,0);
                              paintone(cv,207,0,true,false,16);end;
        hasROW[upplayer]:=true;
        if upcard[upplayer] in [0,Stop,Gas,Repairs,Spare]
           then upcard[upplayer]:=Go;
        underSL[upplayer]:=false;
        drawroad(upplayer);
       end;
   SS:begin
       if upplayer=GS then begin Moveacard(150,-64,207,0);
                             paintone(cv,207,0,true,false,19);end;
       hasSS[upplayer]:=true;
       if upcard[upplayer]=Flat then upcard[upplayer]:=Go;
       drawroad(upplayer);
      end;
   SD:begin
       if upplayer=GS then begin Moveacard(150,-64,207,0);
                             paintone(cv,207,0,true,false,17);end;
       hasSD[upplayer]:=true;
       if upcard[upplayer]=Crash then upcard[upplayer]:=Go;
       drawroad(upplayer);
      end;
   EF:begin
       if upplayer=GS then begin Moveacard(150,-64,207,0);
                             paintone(cv,207,0,true,false,18);end;
       hasEF[upplayer]:=true;
       if upcard[upplayer]=Empty then upcard[upplayer]:=Go;
       drawroad(upplayer);
      end;
   otherwise:begin end;
  end{case};
  action:=0;card:=0;
  if (cv in [ROW,SS,SD,EF]) and (cardsleft>0)
     then begin
           Hands[upplayer,7]:=topcard;
           if upplayer=Human then begin
                            Moveacard(0,50,130,94);
                            paintone(Hands[Human,7],130,94,true,true,0);
                            initcursor;
                          end;
          end
     else endturn;
end;

procedure showdiscard;
var cv,sdi:integer;sr:rect;
begin
  cv:=card;waitcursor;
  coupable[upplayer]:=false;
  if upplayer=GS then Moveacard(150,-64,250,94);
  paintone(cv,250,94,true,true,0);
  action:=0;card:=0;
  endturn;
end;

{ ============================================================= }
{  MAINEVENTLOOP: All together now...                           }
{ ============================================================= }
procedure maineventloop;
var ignore:integer;
begin
   gmainevent.taskmask:=$001FFFFF;
   gdone:=false;
   repeat
      tmcode:=taskmaster($FFFF,gmainevent);
      case tmcode of
         activateevt: checkfrontw;
         winspecial: HandleMenu;
         winmenubar: HandleMenu;
         wincontrol: docontrols;
         wincontent: if (upplayer=human) and (action=0) then checkboard;
         wingoaway: closeawindow;
         otherwise: begin end;
      end;
      if not gdone
       then begin
               if upplayer=GS then GSdecide;
               case Action of
                coup:Showcoup;
                play:Showplay;
                discard:Showdiscard;
                otherwise:begin end;
               end{case};
            end;
      ignore:=randominteger;
   until gdone;
end;

begin {MAIN!}
   gmainmemoryID:=MMStartup;
   gmymemoryID:=gmainmemoryid+$0700;
   gstartstopref:=startuptools(gmainmemoryid,Resourceverb,$0001);
   if Toolerror=0 then
       begin
          SetupMenus;
          InitGlobals;
          if savable then begin
                           enablemitem(krallyitem);
                           enablemitem(kgameitem);
                           enablemitem(kabortitem);
                           disablemitem(kbeginitem);
                           disablemitem(kplayeritem);
                          end
                     else doplayer;
          Initcursor;if upplayer=GS then waitcursor;
          MainEventLoop;
          Speak(30);
          repeat until FFSoundDoneStatus(0) and FFsoundDonestatus(2);
          writeMSHOF;
       end
       else Errorbomb;
   DisposeAll(gmymemoryid);
   Shutdowntools(Handleverb,gstartstopref);
end.

