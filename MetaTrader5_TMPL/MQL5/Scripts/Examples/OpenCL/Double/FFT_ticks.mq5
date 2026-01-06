//+------------------------------------------------------------------+
//|                                                          FFT.mq5 |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2000-2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

/*
#include <Math/Stat/Math.mqh>
#include <OpenCL/OpenCL.mqh>

#resource "Kernels/fft.cl" as string cl_program
#define kernel_init  "fft_init"
#define kernel_stage "fft_stage"
#define kernel_scale "fft_scale"
*/

#define NUM_POINTS 128
#define FFT_DIRECTION 1
//+------------------------------------------------------------------+
//| Fast Fourier transform and its inverse (both recursively)        |
//| Copyright (C) 2004, Jerome R. Breitenbach.  All rights reserved. |
//| Reference:                                                       |
//| Matthew Scarpino, "OpenCL in Action: How to accelerate graphics  |
//| and computations", Manning, 2012, Chapter 14.                    |
//+------------------------------------------------------------------+
//| Recursive direct FFT transform                                   |
//+------------------------------------------------------------------+
void fft(const int N, double &x_real[], double &x_imag[], double &X_real[], double &X_imag[])
{
   //--- prepare temporary arrays
   double XX_real[], XX_imag[];
   ArrayResize(XX_real, N);
   ArrayResize(XX_imag, N);
   //--- calculate FFT by a recursion
   fft_rec(N, 0, 1, x_real, x_imag, X_real, X_imag, XX_real, XX_imag);
}
//+------------------------------------------------------------------+
//| Recursive inverse FFT transform                                  |
//+------------------------------------------------------------------+
void ifft(const int N, double &x_real[], double &x_imag[], double &X_real[], double &X_imag[])
{
   int N2 = N / 2; // half the number of points in IFFT
                   //--- calculate IFFT via reciprocity property of DFT
   fft(N, X_real, X_imag, x_real, x_imag);
   x_real[0] = x_real[0] / N;
   x_imag[0] = x_imag[0] / N;
   x_real[N2] = x_real[N2] / N;
   x_imag[N2] = x_imag[N2] / N;
   for (int i = 1; i < N2; i++)
   {
      double tmp0 = x_real[i] / N;
      double tmp1 = x_imag[i] / N;
      x_real[i] = x_real[N - i] / N;
      x_imag[i] = x_imag[N - i] / N;
      x_real[N - i] = tmp0;
      x_imag[N - i] = tmp1;
   }
}
//+------------------------------------------------------------------+
//| FFT recursion                                                    |
//+------------------------------------------------------------------+
void fft_rec(const int N, const int offset, const int delta, double &x_real[], double &x_imag[], double &X_real[], double &X_imag[], double &XX_real[], double &XX_imag[])
{
   static const double TWO_PI = (double)(2 * M_PI);
   int N2 = N / 2;         // half the number of points in FFT
   int k00, k01, k10, k11; // indices for butterflies
   if (N != 2)
   {
      //--- perform recursive step
      //--- calculate two (N/2)-point DFT's
      fft_rec(N2, offset, 2 * delta, x_real, x_imag, XX_real, XX_imag, X_real, X_imag);
      fft_rec(N2, offset + delta, 2 * delta, x_real, x_imag, XX_real, XX_imag, X_real, X_imag);
      //--- combine the two (N/2)-point DFT's into one N-point DFT
      for (int k = 0; k < N2; k++)
      {
         k00 = offset + k * delta;
         k01 = k00 + N2 * delta;
         k10 = offset + 2 * k * delta;
         k11 = k10 + delta;
         double cs = (double)MathCos(TWO_PI * k / (double)N);
         double sn = (double)MathSin(TWO_PI * k / (double)N);
         double tmp0 = cs * XX_real[k11] + sn * XX_imag[k11];
         double tmp1 = cs * XX_imag[k11] - sn * XX_real[k11];
         X_real[k01] = XX_real[k10] - tmp0;
         X_imag[k01] = XX_imag[k10] - tmp1;
         X_real[k00] = XX_real[k10] + tmp0;
         X_imag[k00] = XX_imag[k10] + tmp1;
      }
   }
   else
   {
      //--- perform 2-point DFT
      k00 = offset;
      k01 = k00 + delta;
      X_real[k01] = x_real[k00] - x_real[k01];
      X_imag[k01] = x_imag[k00] - x_imag[k01];
      X_real[k00] = x_real[k00] + x_real[k01];
      X_imag[k00] = x_imag[k00] + x_imag[k01];
   }
}
//+------------------------------------------------------------------+
//| FFT_CPU                                                          |
//+------------------------------------------------------------------+
bool FFT_CPU(int direction, int power, double &data_real[], double &data_imag[], ulong &time_cpu)
{
   //--- calculate the number of points
   int N = 1;
   for (int i = 0; i < power; i++)
      N *= 2;
   //---prepare temporary arrays
   double XX_real[], XX_imag[];
   ArrayResize(XX_real, N);
   ArrayResize(XX_imag, N);
   //--- CPU calculation start
   time_cpu = GetMicrosecondCount();
   if (direction > 0)
      fft(N, data_real, data_imag, XX_real, XX_imag);
   else
      ifft(N, XX_real, XX_imag, data_real, data_imag);
   //--- CPU calculation finished
   time_cpu = ulong((GetMicrosecondCount() - time_cpu));
   //--- copy calculated data
   ArrayCopy(data_real, XX_real, 0, 0, WHOLE_ARRAY);
   ArrayCopy(data_imag, XX_imag, 0, 0, WHOLE_ARRAY);
   //---
   return (true);
}

void FftCalc(const int &size, const MqlTick &mqltickarray[], int direction = 1)
{

   int datacount = size;
   int power = (int)(MathLog(datacount) / M_LN2);
   if (MathPow(2, power) != datacount)
   {
      PrintFormat("Number of elements must be power of 2. Elements: %d", datacount);
      return;
   }
   //--- prepare data for FFT calculation
   double data_real[], data_imag[];
   ArrayResize(data_real, datacount);
   ArrayResize(data_imag, datacount);
   for (int cnt = 0; cnt < datacount; cnt++)
   {
      double val = ((((mqltickarray[cnt].ask + mqltickarray[cnt].bid) / 2) - ((mqltickarray[0].ask + mqltickarray[0].bid) / 2)) / _Point);
      data_real[cnt] = val;
      data_imag[cnt] = 0;
   }
   // int direction=FFT_DIRECTION;
   //--- data arrays for CPU calculation
   double CPU_real[], CPU_imag[];
   ArrayCopy(CPU_real, data_real, 0, 0, WHOLE_ARRAY);
   ArrayCopy(CPU_imag, data_imag, 0, 0, WHOLE_ARRAY);
   ulong time_cpu = 0;
   //--- calculate FFT using CPU

   ArrayPrint(CPU_real);
   // ArrayPrint(CPU_imag);

   double high = 0;
   double low = 1000000000;
   double sum_pos = 0;
   double sum_neg = 0;
   double open = CPU_real[0];
   double close = CPU_real[size-1];
   double OC = close - open;
   for (int cnt = 0; cnt < size; cnt++)
   {
      double val = CPU_real[cnt];
      if (high < val)
         high = val;
      if (low > val)
         low = val;
      if( 0.0 < val )
        sum_pos += val;
      if( 0.0 > val )
        sum_neg += val;

   } // for( cnt = 0; cnt < size; cnt++ )
   double HL = (high-low);
   double OC2 = (high+low)/2;
   double OC3 = (sum_pos+sum_neg)/datacount;
   double OCA = (OC+OC2+OC3)/3;
   double OC_HL = OCA/HL;
   PrintFormat("FFT_INPU: H %7.2f  L %7.2f SP %8.2f  SN %8.2f  OC %8.2f/%8.2f/%8.2f/%8.2f HL %8.2f OC/HL %8.2f   SIZE %5d CPU=%dus.", high, low, sum_pos, sum_neg, OC, OC2, OC3, OCA, HL, OC_HL, datacount, time_cpu);

   FFT_CPU(direction, power, CPU_real, CPU_imag, time_cpu);
   
   int N2 = (int)(size/2);
   ArrayResize(CPU_real, N2 );
   //ArrayPrint(CPU_real);

   ArrayResize(CPU_imag, N2 );
   //ArrayPrint(CPU_imag);

   high = 0;
   low = 1000000000;
   sum_pos = 0;
   sum_neg = 0;
   for (int cnt = 0; cnt < N2; cnt++)
   {
      double val = CPU_real[cnt];
      if (high < val)
         high = val;
      if (low > val)
         low = val;
      if( 0.0 < val )
        sum_pos += val;
      if( 0.0 > val )
        sum_neg += val;

   } // for( cnt = 0; cnt < N2; cnt++ )
   PrintFormat("FFT_REAL: H %7.2f  L %7.2f SP %8.2f  SN %8.2f  SIZE %5d CPU=%dus.", high, low, sum_pos, sum_neg, datacount, time_cpu);

   
   high = 0;
   low = 1000000000;
   sum_pos = 0;
   sum_neg = 0;
   for (int cnt = 0; cnt < N2; cnt++)
   {
      double val = CPU_imag[cnt];
      if (high < val)
         high = val;
      if (low > val)
         low = val;
      if( 0.0 < val )
        sum_pos += val;
      if( 0.0 > val )
        sum_neg += val;

   } // for( cnt = 0; cnt < N2; cnt++ )
   PrintFormat("FFT_IMAG: H %7.2f  L %7.2f SP %8.2f  SN %8.2f  SIZE %5d CPU=%dus.", high, low, sum_pos, sum_neg, datacount, time_cpu);
   // -->
   //PrintFormat("FFT_IMAG: H %7.2f  L %7.2f SP %8.2f  SN %8.2f  SIZE %5d CPU=%dus.", -1*low, -1*high, -1*sum_neg, -1*sum_pos, datacount, time_cpu);
   

   /*
   //--- data arrays for GPU calculation
      double GPU_real[],GPU_imag[];
      ArrayCopy(GPU_real,data_real,0,0,WHOLE_ARRAY);
      ArrayCopy(GPU_imag,data_imag,0,0,WHOLE_ARRAY);
      ulong time_gpu=0;
   //--- calculate FFT using GPU
      if(!FFT_GPU(direction,power,GPU_real,GPU_imag,time_gpu))
        {
         PrintFormat("Error in calculation FFT on GPU.");
         return;
        }
   //--- calculate CPU/GPU ratio
      double CPU_GPU_ratio=0;
      if(time_gpu!=0)
         CPU_GPU_ratio=1.0*time_cpu/time_gpu;
      PrintFormat("FFT calculation for %d points.",datacount);
      PrintFormat("time CPU=%d microseconds, time GPU =%d microseconds, CPU/GPU ratio: %f",time_cpu,time_gpu,CPU_GPU_ratio);
   */
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
   int fft_size = 1024;
   int fft_iterations = 400;
   int fft_iterations_delta_ms = 10*1000;
   int fft_direction = 1;

   MqlTick t;
   if (!SymbolInfoTick(Symbol(), t))
      Print("SymbolInfoTick() failed, error = ", GetLastError());

   MqlTick dst_array[];
   MqlTick src_array[];
   int src_size = 0;
   int dst_size = 0;
   long t0 = 0;
   double c0 = 0.0;
   long tn = 0;
   double cn = 0.0;

   long dt_to = t.time_msc;
   
   //dt_to = 1767373259249; // 1767373259249 2026.01.02 17:00:59.249 
   //dt_to = 1767373200000 - 1200000; // 1767373259249 2026.01.02 17:00:00.000 
   
   int cnt = 0;
   //while( ++cnt < fft_iterations )
   {
   
       string str = StringFormat("%s.%03d", TimeToString(dt_to/1000, TIME_DATE|TIME_SECONDS), dt_to % 1000 );
    
       src_size = CopyTicksRange(_Symbol, src_array, COPY_TICKS_TIME_MS, dt_to - (10) * fft_size * 1000, dt_to );
       if (src_size > fft_size)
       {
          
          ArrayCopy(dst_array, src_array, 0, (src_size - fft_size), fft_size);
          dst_size = ArraySize(dst_array);
          if (fft_size == dst_size)
          {
          
              if(1 == cnt )
              {
                t0 = dst_array[dst_size-1].time_msc;
                c0 = (dst_array[dst_size-1].ask+dst_array[dst_size-1].bid)/2;
              }
              if(1 == cnt )
              {
                t0 = dst_array[dst_size-1].time_msc;
                c0 = (dst_array[dst_size-1].ask+dst_array[dst_size-1].bid)/2;
              }
          
             Print("do FFT @ ", str, " O: ", DoubleToString(dst_array[0].ask, _Digits), " C: ", DoubleToString(dst_array[dst_size-1].ask, _Digits) );
             FftCalc(fft_size, dst_array, fft_direction);
             
          } // if (fft_size == dst_size) 
          
       } // if (src_size > fft_size)

       dt_to += fft_iterations_delta_ms;
   
   }// while( ++cnt < fft_iterations )
   
} // void OnStart()
