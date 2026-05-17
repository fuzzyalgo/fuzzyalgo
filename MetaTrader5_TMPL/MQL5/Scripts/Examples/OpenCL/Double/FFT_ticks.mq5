//+------------------------------------------------------------------+
//|                                                          FFT.mq5 |
//|                             Copyright 2000-2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2000-2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"

#include <FuzzyAlgo/variables.mqh>
#include <FuzzyAlgo/HistogramChart.mqh>
#include <WinAPI/sysinfoapi.mqh>

struct sFftParams
{
    const int fft_size;
    const int fft_min_size;
    const int fft_grid_scale_divider;
    const int fft_direction;
    const int fft_real_part_size_used;
    const int fft_real_part_start_pos;
    const int fft_imag_part_size_used;
    const int fft_imag_part_start_pos;

    sFftParams() : fft_size(0),
                   fft_min_size(0),
                   fft_grid_scale_divider(2),
                   fft_direction(1),
                   fft_real_part_size_used(1),
                   fft_real_part_start_pos(0),
                   fft_imag_part_size_used(1),
                   fft_imag_part_start_pos(1) {};

    sFftParams(const int &_fft_size) : fft_size(_fft_size),
                                       fft_min_size(16),
                                       fft_grid_scale_divider(2),
                                       fft_direction(1),
                                       fft_real_part_size_used(1),
                                       fft_real_part_start_pos(0),
                                       fft_imag_part_size_used(2),
                                       fft_imag_part_start_pos(1) {};

    sFftParams(const int &_fft_size,
               const int &_fft_min_size,
               const int &_fft_grid_scale_divider,
               const int &_fft_direction,
               const int &_fft_real_part_size_used,
               const int &_fft_real_part_start_pos,
               const int &_fft_imag_part_size_used,
               const int &_fft_imag_part_start_pos) : fft_size(_fft_size),
                                                      fft_min_size(_fft_min_size),
                                                      fft_grid_scale_divider(_fft_grid_scale_divider),
                                                      fft_direction(_fft_direction),
                                                      fft_real_part_size_used(_fft_real_part_size_used),
                                                      fft_real_part_start_pos(_fft_real_part_start_pos),
                                                      fft_imag_part_size_used(_fft_imag_part_size_used),
                                                      fft_imag_part_start_pos(_fft_imag_part_start_pos) {};

}; // struct sFftParams

struct sAlgoFftChart
{
    const string name;
    const int x;
    const int y;
    const int width;
    const int height;
    bool created;
    sFftParams fft_params;
    CHistogramChart chart;

    void create()
    {
        if (chart.CreateBitmapLabel(name, x, y, width, height))
        {
            created = true;
            // chart.Accumulative();
            chart.ShowValue(false);
            chart.ShowScaleTop(false);
            chart.ShowScaleBottom(false);
            chart.ShowScaleRight(false);
            chart.ShowLegend(true);
            int size2 = (int)(fft_params.fft_size / fft_params.fft_grid_scale_divider);
            chart.VScaleParams((int)size2, -1 * size2, fft_params.fft_min_size);
        }
        else
        {
            created = false;
            Print("Error creating histogram chart: ", GetLastError());
            // @TODO raise exception here
        }
    }

    void destroy()
    {
        chart.Destroy();
        created = false;
    }

    sAlgoFftChart() : name("FFtChart"),
                      x(10), y(10), width(600), height(450), created(false),
                      fft_params(sFftParams()) {};

    sAlgoFftChart(
        const string &_name,
        const int &_x,
        const int &_y,
        const int &_width,
        const int &_height,
        const sFftParams &_fft_params) : name(_name),
                                         x(_x), y(_y), width(_width), height(_height), created(false),
                                         fft_params(_fft_params)
    {
        create();
    };

}; // sAlgoFftChart

class AlgoFFT
{

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
    } // void fft(const int N, double &x_real[], double &x_imag[], double &X_real[], double &X_imag[])

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
    } // void ifft(const int N, double &x_real[], double &x_imag[], double &X_real[], double &X_imag[])

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
    } // void fft_rec(const int N, const int offset, const int delta, double &x_real[], double &x_imag[], double &X_real[], double &X_imag[], double &XX_real[], double &XX_imag[])

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
    } // bool FFT_CPU(int direction, int power, double &data_real[], double &data_imag[], ulong &time_cpu)

public:
    void FftCalc(const int &size, const MqlTick &in_mqltickarray[], double &out_CPU_input[], double &out_CPU_real[], double &out_CPU_imag[], int direction = 1)
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
            double val = ((((in_mqltickarray[cnt].ask + in_mqltickarray[cnt].bid) / 2) - ((in_mqltickarray[0].ask + in_mqltickarray[0].bid) / 2)) / _Point);
            data_real[cnt] = val;
            data_imag[cnt] = 0;
        }
        // int direction=FFT_DIRECTION;
        //--- data arrays for CPU calculation
        // double CPU_real[], CPU_imag[];
        ArrayCopy(out_CPU_input, data_real, 0, 0, WHOLE_ARRAY);
        ArrayCopy(out_CPU_real, data_real, 0, 0, WHOLE_ARRAY);
        ArrayCopy(out_CPU_imag, data_imag, 0, 0, WHOLE_ARRAY);
        ulong time_cpu = 0;
        //--- calculate FFT using CPU

        ArrayPrint(out_CPU_input);
        // ArrayPrint(CPU_imag);

        double high = 0;
        double low = 1000000000;
        double sum_pos = 0;
        double sum_neg = 0;
        double open = out_CPU_real[0];
        double close = out_CPU_real[size - 1];
        double OC = close - open;
        for (int cnt = 0; cnt < size; cnt++)
        {
            double val = out_CPU_input[cnt];
            if (high < val)
                high = val;
            if (low > val)
                low = val;
            if (0.0 < val)
                sum_pos += val;
            if (0.0 > val)
                sum_neg += val;

        } // for( cnt = 0; cnt < size; cnt++ )
        double HL = (high - low);
        double OC2 = (high + low) / 2;
        double OC3 = (sum_pos + sum_neg) / datacount;
        double OCA = (OC + OC2 + OC3) / 3;
        double OC_HL = OCA / HL;
        PrintFormat("FFT_INPU: H %7.2f  L %7.2f SP %8.2f  SN %8.2f  OC %8.2f/%8.2f/%8.2f/%8.2f HL %8.2f OC/HL %8.2f   SIZE %5d CPU=%dus.", high, low, sum_pos, sum_neg, OC, OC2, OC3, OCA, HL, OC_HL, datacount, time_cpu);

        FFT_CPU(direction, power, out_CPU_real, out_CPU_imag, time_cpu);

        int N2 = (int)(size / 2);
        ArrayResize(out_CPU_real, N2);
        // ArrayPrint(CPU_real);

        ArrayResize(out_CPU_imag, N2);
        // ArrayPrint(CPU_imag);

        high = 0;
        low = 1000000000;
        sum_pos = 0;
        sum_neg = 0;
        for (int cnt = 0; cnt < N2; cnt++)
        {
            double val = out_CPU_real[cnt];
            if (high < val)
                high = val;
            if (low > val)
                low = val;
            if (0.0 < val)
                sum_pos += val;
            if (0.0 > val)
                sum_neg += val;

        } // for( cnt = 0; cnt < N2; cnt++ )
        PrintFormat("FFT_REAL: H %7.2f  L %7.2f SP %8.2f  SN %8.2f  SIZE %5d CPU=%dus.", high, low, sum_pos, sum_neg, datacount, time_cpu);

        high = 0;
        low = 1000000000;
        sum_pos = 0;
        sum_neg = 0;
        for (int cnt = 0; cnt < N2; cnt++)
        {
            double val = out_CPU_imag[cnt];
            if (high < val)
                high = val;
            if (low > val)
                low = val;
            if (0.0 < val)
                sum_pos += val;
            if (0.0 > val)
                sum_neg += val;

        } // for( cnt = 0; cnt < N2; cnt++ )
        PrintFormat("FFT_IMAG: H %7.2f  L %7.2f SP %8.2f  SN %8.2f  SIZE %5d CPU=%dus.", high, low, sum_pos, sum_neg, datacount, time_cpu);
        // -->
        // PrintFormat("FFT_IMAG: H %7.2f  L %7.2f SP %8.2f  SN %8.2f  SIZE %5d CPU=%dus.", -1*low, -1*high, -1*sum_neg, -1*sum_pos, datacount, time_cpu);

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

}; // struct AlgoFFT

void FftCalc(const long &in_time_msc, sAlgoFftChart &afc)
{
    // @TODO move calling of FFT into variables
    int fft_size_divider = 2;
    double CPU_input[];
    double CPU_input_disp[];
    double CPU_real[];
    double CPU_imag[];
    AlgoFFT fft();
    MqlTick src_array[];
    int src_size = CopyTicksRange(_Symbol, src_array, COPY_TICKS_TIME_MS, in_time_msc - (10) * afc.fft_params.fft_size * 1000, in_time_msc);
    if (src_size > afc.fft_params.fft_size)
    {
        MqlTick dst_array[];
        int dst_size = 0;
        long t0 = 0;
        double c0 = 0.0;
        ArrayCopy(dst_array, src_array, 0, (src_size - afc.fft_params.fft_size), afc.fft_params.fft_size);
        dst_size = ArraySize(dst_array);
        if (afc.fft_params.fft_size == dst_size)
        {
            t0 = dst_array[dst_size - 1].time_msc;
            c0 = (dst_array[dst_size - 1].ask + dst_array[dst_size - 1].bid) / 2;
            string time_str = StringFormat("%s.%03d", TimeToString(in_time_msc / 1000, TIME_DATE | TIME_SECONDS), in_time_msc % 1000);
            Print("do FFT @ ", time_str, " O: ", DoubleToString(dst_array[0].ask, _Digits), " C: ", DoubleToString(dst_array[dst_size - 1].ask, _Digits));
            fft.FftCalc(afc.fft_params.fft_size, dst_array, CPU_input, CPU_real, CPU_imag, afc.fft_params.fft_direction);

            if (true == afc.created)
            {
                ArrayResize(CPU_input_disp, afc.fft_params.fft_min_size);
                ArrayCopy(CPU_input_disp, CPU_input, 0, ArraySize(CPU_input) - afc.fft_params.fft_min_size, afc.fft_params.fft_min_size);
                ArrayResize(CPU_real, afc.fft_params.fft_real_part_size_used);
                ArrayResize(CPU_imag, afc.fft_params.fft_imag_part_size_used);
                afc.chart.SeriesUpdate(0, CPU_real, "FFT-REAL");
                afc.chart.SeriesUpdate(1, CPU_imag, "FFT-IMAG");
                afc.chart.SeriesUpdate(2, CPU_input_disp, "INPUT");
            } // if( true == afc.created )

        } // if (fft_size == dst_size)
    } // if (src_size > fft_size)
} // void FftCalc(const long& in_time_msc )

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{

    int ring_buf_num = 10;

    MqlDateTime time_struct = {};
    time_struct.year = 2026;
    time_struct.mon = 5;
    time_struct.day = 15;
    time_struct.hour = 12;
    time_struct.min = 0;
    time_struct.sec = 0;
    long in_time_msc;
    in_time_msc = StructToTime(time_struct) * 1000;
    // in_time_msc = GetSystemTimeMsc();
    // in_time_msc = TimeCurrent()*1000;
    //   in_time_msc = TimeLocal()*1000;
    //   in_time_msc = (datetime)t.time_msc;

    // @TODO move calling of FFT into variables
    sFftParams fftp1(16);
    string name1 = "FFT" + IntegerToString(fftp1.fft_size);
    sAlgoFftChart afc1(name1, (10 + 0 * 640), 10, 640, 450, fftp1);
    FftCalc(in_time_msc, afc1);

    sFftParams fftp2(32);
    string name2 = "FFT" + IntegerToString(fftp2.fft_size);
    sAlgoFftChart afc2(name2, (10 + 1 * 640), 10, 640, 450, fftp2);
    FftCalc(in_time_msc, afc2);

    sFftParams fftp3(64);
    string name3 = "FFT" + IntegerToString(fftp3.fft_size);
    sAlgoFftChart afc3(name3, (10 + 2 * 640), 10, 640, 450, fftp3);
    FftCalc(in_time_msc, afc3);

    sFftParams fftp4(128);
    string name4 = "FFT" + IntegerToString(fftp4.fft_size);
    sAlgoFftChart afc4(name4, (10 + 0 * 640), (10 + 1 * 450), 640, 450, fftp4);
    FftCalc(in_time_msc, afc4);

    sFftParams fftp5(256);
    string name5 = "FFT" + IntegerToString(fftp5.fft_size);
    sAlgoFftChart afc5(name5, (10 + 1 * 640), (10 + 1 * 450), 640, 450, fftp5);
    FftCalc(in_time_msc, afc5);

    sFftParams fftp6(512);
    string name6 = "FFT" + IntegerToString(fftp6.fft_size);
    sAlgoFftChart afc6(name6, (10 + 2 * 640), (10 + 1 * 450), 640, 450, fftp6);
    FftCalc(in_time_msc, afc6);

    sGlobalVars g(in_time_msc);
    Print("symbols " + g.c.SYMBOLS + " | " + IntegerToString(g.c.SYMBOLS_num));
    ArrayPrint(g.c.SYMBOLS_arr);
    Print("symbols " + g.c.PERIODS + " | " + IntegerToString(g.c.PERIODS_num));
    ArrayPrint(g.c.PERIODS_arr);
    Print("symbols " + g.c.HOSTS + " | " + IntegerToString(g.c.HOSTS_num));
    ArrayPrint(g.c.HOSTS_arr);

    sRingBuf<sGlobalVars> ringbuf;
    bool res = ringbuf.init(ring_buf_num, false);
    for (int min_cnt = (ring_buf_num - 1); min_cnt >= 0; min_cnt--)
    {
        long time_msc = in_time_msc - min_cnt * 1 * 1000;
        sGlobalVars tmp(time_msc);
        ringbuf.AddBuf(tmp);
    }

    // @TODO move SUM_POS et.al. into variables
    double c1 = 0;
    int SUM_POS = 0;
    int SUM_NEG = 0;
    int SUM_ALL = 0;

    for (int min_cnt = 0; min_cnt < ring_buf_num; min_cnt++)
    {
        sGlobalVars tmp;
        res = ringbuf.TryGet(min_cnt, tmp);
        if (0 == min_cnt)
        {
            c1 = tmp.sSym[0].sData[0].d.c0;
        }
        double c0 = tmp.sSym[0].sData[0].d.c0;
        double point = SymbolInfoDouble(tmp.sSym[0].symbol, SYMBOL_POINT);
        int p0 = (int)((c0 - c1) / point);
        if (0 < p0)
            SUM_POS += p0;
        if (0 > p0)
            SUM_NEG += p0;
        SUM_ALL += p0;

        long time_msc = tmp.time_msc;
        string msg = "OUT2";
        string str = StringFormat("%s %s.%03d %s | %0.5f %6d %6d %6d %6d | %s %7d %7d %7d %7d | %s %7d %7d %7d %7d | %s %7d %7d %7d %7d", msg,
                                  TimeToString(time_msc / 1000, TIME_DATE | TIME_SECONDS),
                                  time_msc % 1000,
                                  tmp.sSym[0].symbol,

                                  c0,
                                  p0,
                                  SUM_ALL,
                                  SUM_POS,
                                  SUM_NEG,

                                  tmp.sSym[0].sData[0].period,
                                  (int)tmp.sSym[0].sData[0].d.OC,
                                  (int)tmp.sSym[0].sData[0].d.HL,
                                  (int)tmp.sSym[0].sData[0].d.SUM_POS,
                                  (int)tmp.sSym[0].sData[0].d.SUM_NEG,

                                  tmp.sSym[0].sData[1].period,
                                  (int)tmp.sSym[0].sData[1].d.OC,
                                  (int)tmp.sSym[0].sData[1].d.HL,
                                  (int)tmp.sSym[0].sData[1].d.SUM_POS,
                                  (int)tmp.sSym[0].sData[1].d.SUM_NEG,

                                  tmp.sSym[0].sData[2].period,
                                  (int)tmp.sSym[0].sData[2].d.OC,
                                  (int)tmp.sSym[0].sData[2].d.HL,
                                  (int)tmp.sSym[0].sData[2].d.SUM_POS,
                                  (int)tmp.sSym[0].sData[2].d.SUM_NEG);
        Print(str);
    }

    sRefPoint sr3(in_time_msc);

    int min_cnt = 0;
    while (!IsStopped())
    {
        long time_msc = in_time_msc + min_cnt * 60 * 1000;
        // time_msc = GetSystemTimeMsc();
        ulong start = GetTickCount64();
        sGlobalVars tmp1(time_msc, sr3);
        ringbuf.AddBuf(tmp1);
        sGlobalVars tmp;
        res = ringbuf.TryGet(0, tmp);
        min_cnt++;

        double c0 = tmp.sSym[0].sData[0].d.c0;
        double point = SymbolInfoDouble(tmp.sSym[0].symbol, SYMBOL_POINT);
        int p0 = (int)((c0 - c1) / point);
        if (0 < p0)
            SUM_POS += p0;
        if (0 > p0)
            SUM_NEG += p0;
        SUM_ALL += p0;

        // time_msc = tmp.time_msc;
        string msg = "OUT3";
        string str = StringFormat("%s %s.%03d %s %3d | %0.5f %6d %6d %6d %6d | %s %7d %7d %7d %7d | %s %7d %7d %7d %7d | %s %7d %7d %7d %7d", msg,
                                  TimeToString(time_msc / 1000, TIME_DATE | TIME_SECONDS),
                                  time_msc % 1000,
                                  tmp.sSym[0].symbol,
                                  (GetTickCount64() - start),

                                  c0,
                                  p0,
                                  SUM_ALL,
                                  SUM_POS,
                                  SUM_NEG,

                                  tmp.sSym[0].sData[0].period,
                                  (int)tmp.sSym[0].sData[0].d.OC,
                                  (int)tmp.sSym[0].sData[0].d.HL,
                                  (int)tmp.sSym[0].sData[0].d.SUM_POS,
                                  (int)tmp.sSym[0].sData[0].d.SUM_NEG,

                                  tmp.sSym[0].sData[1].period,
                                  (int)tmp.sSym[0].sData[1].d.OC,
                                  (int)tmp.sSym[0].sData[1].d.HL,
                                  (int)tmp.sSym[0].sData[1].d.SUM_POS,
                                  (int)tmp.sSym[0].sData[1].d.SUM_NEG,

                                  tmp.sSym[0].sData[2].period,
                                  (int)tmp.sSym[0].sData[2].d.OC,
                                  (int)tmp.sSym[0].sData[2].d.HL,
                                  (int)tmp.sSym[0].sData[2].d.SUM_POS,
                                  (int)tmp.sSym[0].sData[2].d.SUM_NEG);

        FftCalc(time_msc, afc1);
        FftCalc(time_msc, afc2);
        FftCalc(time_msc, afc3);
        FftCalc(time_msc, afc4);
        FftCalc(time_msc, afc5);
        FftCalc(time_msc, afc6);
        Print(str);
        Sleep(100);

    } // while (!IsStopped())

    afc1.destroy();
    afc2.destroy();
    afc3.destroy();
    afc4.destroy();
    afc5.destroy();
    afc6.destroy();

} // void OnStart()

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
// #include <WinAPI/sysinfoapi.mqh>
// https://www.mql5.com/en/forum/462879/page2
datetime GetSystemTimeMsc(void)
{
    SYSTEMTIME st;
    GetSystemTime(st);

    MqlDateTime dt;
    dt.year = st.wYear;
    dt.mon = st.wMonth;
    dt.day = st.wDay;
    dt.hour = st.wHour;
    dt.min = st.wMinute;
    dt.sec = st.wSecond;
    //---
    return (1000 * (StructToTime(dt) + 3 * 3600 /*7200*/) + st.wMilliseconds);
} // long GetSystemTimeMsc(void)
//+------------------------------------------------------------------+
