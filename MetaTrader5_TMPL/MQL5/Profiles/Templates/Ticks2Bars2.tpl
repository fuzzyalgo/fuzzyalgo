<chart>
id=133162147869234229
symbol=EURUSD
description=Euro vs US Dollar
period_type=0
period_size=1
digits=5
tick_size=0.000000
position_time=1678687200
scale_fix=0
scale_fixed_min=1.061600
scale_fixed_max=1.063000
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=32
mode=0
fore=0
grid=0
volume=1
scroll=1
shift=1
shift_size=24.409449
fixed_pos=0.000000
ticker=0
ohlc=0
one_click=0
one_click_btn=0
bidline=0
askline=0
lastline=0
days=1
descriptions=0
tradelines=0
tradehistory=0
window_left=0
window_top=0
window_right=706
window_bottom=550
window_type=3
floating=0
floating_left=0
floating_top=0
floating_right=0
floating_bottom=0
floating_type=1
floating_toolbar=1
floating_tbstate=
background_color=0
foreground_color=16777215
barup_color=65535
bardown_color=65535
bullcandle_color=0
bearcandle_color=16777215
chartline_color=4294967295
volumes_color=3329330
grid_color=10061943
bidline_color=10061943
askline_color=255
lastline_color=49152
stops_color=255
windows_total=1

<expert>
name=Ticks2Bars
path=Experts\Ticks2Bars.ex5
expertmode=1
<inputs>
TimeDelta=60
Limit=32000
Reset=true
LoopBack=false
EmulateTicks=true
RenderBars=0
nS1=4
nS2=8
nS3=16
nS4=32
applied_price=1
ma_method=0
</inputs>
</expert>

<window>
height=128.528529
objects=8

<indicator>
name=Main
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1
</indicator>

<indicator>
name=Custom Indicator
path=Indicators\GFRMa_Pivot_HTF.ex5
apply=0
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1

<graph>
name=
draw=0
style=0
width=1
arrow=251
color=
</graph>
<inputs>
Symbols_Sirname=GFRMa_Pivot_
s1_Samples=4
s2_Samples=8
s3_Samples=16
s4_Samples=32
applied_price=1
ma_method=0
Up_Color=16711680
Dn_Color=255
SignalBar=0
SignalLen=15
Middle_color=8388352
Upper_color1=7451452
Lower_color1=255
Upper_color2=16748574
Lower_color2=16711935
</inputs>
</indicator>

<indicator>
name=Moving Average
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1

<graph>
name=
draw=129
style=0
width=1
arrow=251
color=16776960
</graph>
period=4
method=0
</indicator>

<indicator>
name=Moving Average
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1

<graph>
name=
draw=129
style=0
width=1
arrow=251
color=255
</graph>
period=32
method=0
</indicator>
<object>
type=20
name=GFRMa_Pivot_Upper Band
hidden=1
descr=GFRMa_Pivot_Upper Band
color=16711680
background=1
z_order=1
filling=1
date1=1678963320
date2=1678963380
value1=1.062319
value2=1.062360
</object>

<object>
type=20
name=GFRMa_Pivot_Upper Lower Band
hidden=1
descr=GFRMa_Pivot_Upper Lower Band
color=16711680
background=1
z_order=1
filling=1
date1=1678963260
date2=1678963320
value1=1.062273
value2=1.062319
</object>

<object>
type=20
name=GFRMa_Pivot_Lower Band
hidden=1
descr=GFRMa_Pivot_Lower Band
background=1
z_order=1
filling=1
date1=1678963200
date2=1678963260
value1=1.062273
value2=1.062418
</object>

<object>
type=20
name=GFRMa_Pivot_Average Band
hidden=1
descr=GFRMa_Pivot_Average Band
background=1
z_order=1
filling=1
date1=1678963140
date2=1678963200
value1=1.062418
value2=1.062398
</object>

<object>
type=2
name=GFRMa_Pivot_Middle Band
hidden=1
descr=GFRMa_Pivot_Middle Band
color=8388352
width=3
z_order=1
ray1=0
ray2=0
date1=1678963080
date2=1678963560
value1=1.062210
value2=1.062210
</object>

<object>
type=30
name=GFRMa_Pivot_ middle text lable
hidden=1
color=8388352
width=2
background=1
selectable=0
date1=1678963560
value1=1.062210
</object>

</window>
</chart>