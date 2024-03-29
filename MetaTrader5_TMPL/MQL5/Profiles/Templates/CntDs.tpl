<chart>
id=133197151500492081
symbol=GBPJPY
description=Great Britain Pound vs Japanese Yen
period_type=0
period_size=1
digits=3
tick_size=0.000000
position_time=1689982680
scale_fix=0
scale_fixed_min=182.210000
scale_fixed_max=182.310000
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=32
mode=1
fore=0
grid=1
volume=1
scroll=1
shift=1
shift_size=20.361991
fixed_pos=0.000000
ticker=0
ohlc=0
one_click=0
one_click_btn=1
bidline=0
askline=0
lastline=0
days=1
descriptions=0
tradelines=1
tradehistory=1
window_left=0
window_top=473
window_right=755
window_bottom=946
window_type=1
floating=0
floating_left=0
floating_top=0
floating_right=0
floating_bottom=0
floating_type=1
floating_toolbar=1
floating_tbstate=
background_color=16777215
foreground_color=0
barup_color=0
bardown_color=0
bullcandle_color=16777215
bearcandle_color=0
chartline_color=0
volumes_color=32768
grid_color=12632256
bidline_color=12632256
askline_color=12632256
lastline_color=12632256
stops_color=17919
windows_total=1

<window>
height=128.528529
objects=12

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
apply=2
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

<indicator>
name=Moving Average
path=
apply=2
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
period=16
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
date1=1689983640
date2=1689983700
value1=182.269000
value2=182.283250
</object>

<object>
type=20
name=GFRMa_Pivot_Upper Lower Band
hidden=1
descr=GFRMa_Pivot_Upper Lower Band
background=1
z_order=1
filling=1
date1=1689983580
date2=1689983640
value1=182.273563
value2=182.269000
</object>

<object>
type=20
name=GFRMa_Pivot_Lower Band
hidden=1
descr=GFRMa_Pivot_Lower Band
background=1
z_order=1
filling=1
date1=1689983520
date2=1689983580
value1=182.273563
value2=182.276219
</object>

<object>
type=20
name=GFRMa_Pivot_Average Band
hidden=1
descr=GFRMa_Pivot_Average Band
color=16711680
background=1
z_order=1
filling=1
date1=1689983460
date2=1689983520
value1=182.276219
value2=182.278219
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
date1=1689983400
date2=1689983880
value1=182.301000
value2=182.301000
</object>

<object>
type=30
name=GFRMa_Pivot_ middle text lable
hidden=1
color=8388352
width=2
background=1
selectable=0
date1=1689983880
value1=182.301000
</object>

<object>
type=32
name=autotrade #270713071 sell 0.01 GBPJPY at 183.304, GBPJPY
hidden=1
color=1918177
selectable=0
date1=1688403314
value1=183.304000
</object>

<object>
type=31
name=autotrade #270719877 buy 0.01 GBPJPY at 183.222, profit 0.57, G
hidden=1
color=11296515
selectable=0
date1=1688403750
value1=183.222000
</object>

<object>
type=32
name=autotrade #271169112 sell 0.01 GBPJPY at 183.019, GBPJPY
hidden=1
color=1918177
selectable=0
date1=1688645145
value1=183.019000
</object>

<object>
type=31
name=autotrade #271169407 buy 0.01 GBPJPY at 182.991, profit 0.19, G
hidden=1
color=11296515
selectable=0
date1=1688645220
value1=182.991000
</object>

<object>
type=2
name=autotrade #270713071 -> #270719877, profit 0.57, GBPJPY
hidden=1
descr=183.304 -> 183.222
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1688403314
date2=1688403750
value1=183.304000
value2=183.222000
</object>

<object>
type=2
name=autotrade #271169112 -> #271169407, profit 0.19, GBPJPY
hidden=1
descr=183.019 -> 182.991
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1688645145
date2=1688645220
value1=183.019000
value2=182.991000
</object>

</window>
</chart>