//+------------------------------------------------------------------+ 
//|                                     Our MembershipFunctions.mq5  | 
//|                        Copyright 2016, MetaQuotes Software Corp. | 
//|                                             https://www.mql5.com |
//|                   article: https://www.mql5.com/en/articles/3795 | 
//+------------------------------------------------------------------+ 
#include <Math\Fuzzy\membershipfunction.mqh> 
#include <Graphics\Graphic.mqh> 
//--- Create membership functions 
CZ_ShapedMembershipFunction func2(0.0, 0.6);
CNormalMembershipFunction func1(0.5, 0.2); 
CS_ShapedMembershipFunction func3(0.4, 1.0);

//--- Create wrappers for membership functions 
double NormalMembershipFunction1(double x) { return(func1.GetValue(x)); } 
double ZShapedMembershipFunction(double x) { return(func2.GetValue(x)); }
double SShapedMembershipFunction(double x) { return(func3.GetValue(x)); }
 
//+------------------------------------------------------------------+ 
//| Script program start function                                    | 
//+------------------------------------------------------------------+ 
void OnStart() 
  { 
//--- create graphic 
   CGraphic graphic; 
   if(!graphic.Create(0,"Our MembershipFunctions",0,30,30,780,380)) 
     { 
      graphic.Attach(0,"Our MembershipFunctions"); 
     } 
   graphic.HistoryNameWidth(70); 
   graphic.BackgroundMain("Our MembershipFunctions"); 
   graphic.BackgroundMainSize(16); 
//--- create curve 
   graphic.CurveAdd(NormalMembershipFunction1,0.0,1.0,0.01,CURVE_LINES,"[0.5, 0.2]"); 
   graphic.CurveAdd(ZShapedMembershipFunction,0.0,1.0,0.01,CURVE_LINES,"[0.0, 0.6]"); 
   graphic.CurveAdd(SShapedMembershipFunction,0.0,1.0,0.01,CURVE_LINES,"[0.4, 1.0]"); 
//--- sets the X-axis properties 
   graphic.XAxis().AutoScale(false); 
   graphic.XAxis().Min(0.0); 
   graphic.XAxis().Max(1.0); 
   graphic.XAxis().DefaultStep(0.1); 
//--- sets the Y-axis properties 
   graphic.YAxis().AutoScale(false); 
   graphic.YAxis().Min(0.0); 
   graphic.YAxis().Max(1.1); 
   graphic.YAxis().DefaultStep(0.1); 
//--- plot 
   graphic.CurvePlotAll(); 
   graphic.Update(); 
  }