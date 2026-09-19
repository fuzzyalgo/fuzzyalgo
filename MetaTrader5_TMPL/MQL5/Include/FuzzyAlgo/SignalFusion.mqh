//+------------------------------------------------------------------+
//|                                                 SignalFusion.mqh |
//|                                        Copyright 2026, fuzzyalgo |
//|                                        https://www.fuzzyalgo.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, fuzzyalgo"
#property link "https://www.fuzzyalgo.com"

// NOTE: this header intentionally relies on variables.mqh types (sData,
// sGlobalVars, sRingBuf). Include variables.mqh before this file.

enum ENUM_FUSION_SIGNAL
{
    ENUM_FUSION_SIGNAL_FLAT = 0,
    ENUM_FUSION_SIGNAL_BUY = 1,
    ENUM_FUSION_SIGNAL_SELL = 2
};

string FusionSignalToString_g(const ENUM_FUSION_SIGNAL in_signal)
{
    if (ENUM_FUSION_SIGNAL_BUY == in_signal)
        return "BUY";
    if (ENUM_FUSION_SIGNAL_SELL == in_signal)
        return "SELL";
    return "FLAT";
}

struct sDataMatrix
{
    int sample_count;
    int symbols_num;
    int periods_num;

    long time_msc[];
    string symbols_arr[];
    string periods_arr[];
    sData cells[];

    sDataMatrix()
    {
        sample_count = 0;
        symbols_num = 0;
        periods_num = 0;
    }

    void Reset()
    {
        sample_count = 0;
        symbols_num = 0;
        periods_num = 0;
        ArrayFree(time_msc);
        ArrayFree(symbols_arr);
        ArrayFree(periods_arr);
        ArrayFree(cells);
    }

    bool Init(const int in_sample_count, const int in_symbols_num, const int in_periods_num)
    {
        Reset();
        if (in_sample_count <= 0 || in_symbols_num <= 0 || in_periods_num <= 0)
            return false;

        sample_count = in_sample_count;
        symbols_num = in_symbols_num;
        periods_num = in_periods_num;

        ArrayResize(time_msc, sample_count);
        ArrayResize(symbols_arr, symbols_num);
        ArrayResize(periods_arr, periods_num);
        ArrayResize(cells, sample_count * symbols_num * periods_num);

        if (ArraySize(time_msc) != sample_count ||
            ArraySize(symbols_arr) != symbols_num ||
            ArraySize(periods_arr) != periods_num ||
            ArraySize(cells) != sample_count * symbols_num * periods_num)
        {
            Reset();
            return false;
        }
        return true;
    }

    int CellIndex(const int in_row_idx, const int in_symbol_idx, const int in_period_idx) const
    {
        if (in_row_idx < 0 || in_row_idx >= sample_count)
            return -1;
        if (in_symbol_idx < 0 || in_symbol_idx >= symbols_num)
            return -1;
        if (in_period_idx < 0 || in_period_idx >= periods_num)
            return -1;

        return (in_row_idx * symbols_num + in_symbol_idx) * periods_num + in_period_idx;
    }
};

bool ExtractRingBufToDataMatrix_g(sRingBuf<sGlobalVars> &in_ringbuf, sDataMatrix &out_matrix)
{
    out_matrix.Reset();

    int sample_count = in_ringbuf.Count();
    if (sample_count <= 0)
        return false;

    sGlobalVars sample0;
    if (!in_ringbuf.TryGet(0, sample0))
        return false;

    if (sample0.c.SYMBOLS_num <= 0 || sample0.c.PERIODS_num <= 0)
        return false;

    if (!out_matrix.Init(sample_count, sample0.c.SYMBOLS_num, sample0.c.PERIODS_num))
        return false;

    ArrayCopy(out_matrix.symbols_arr, sample0.c.SYMBOLS_arr);
    ArrayCopy(out_matrix.periods_arr, sample0.c.PERIODS_arr);

    for (int row_idx = 0; row_idx < sample_count; row_idx++)
    {
        sGlobalVars sample;
        if (!in_ringbuf.TryGet(row_idx, sample))
            continue;

        out_matrix.time_msc[row_idx] = sample.time_msc;

        int sample_symbols_num = ArraySize(sample.sSym);
        for (int symbol_idx = 0; symbol_idx < out_matrix.symbols_num && symbol_idx < sample_symbols_num; symbol_idx++)
        {
            int sample_periods_num = ArraySize(sample.sSym[symbol_idx].sData);
            for (int period_idx = 0; period_idx < out_matrix.periods_num && period_idx < sample_periods_num; period_idx++)
            {
                int cell_idx = out_matrix.CellIndex(row_idx, symbol_idx, period_idx);
                if (cell_idx < 0)
                    continue;
                out_matrix.cells[cell_idx] = sample.sSym[symbol_idx].sData[period_idx].d;
            }
        }
    }

    return true;
}

bool CountNetflowSignAgreement_g(const sDataMatrix &in_matrix,
                                 const int in_row_idx,
                                 const int in_symbol_idx,
                                 int &out_buy_votes,
                                 int &out_sell_votes)
{
    out_buy_votes = 0;
    out_sell_votes = 0;

    if (in_matrix.sample_count <= 0 || in_matrix.symbols_num <= 0 || in_matrix.periods_num <= 0)
        return false;
    if (in_row_idx < 0 || in_row_idx >= in_matrix.sample_count)
        return false;
    if (in_symbol_idx < 0 || in_symbol_idx >= in_matrix.symbols_num)
        return false;

    for (int period_idx = 0; period_idx < in_matrix.periods_num; period_idx++)
    {
        int cell_idx = in_matrix.CellIndex(in_row_idx, in_symbol_idx, period_idx);
        if (cell_idx < 0)
            continue;

        double netflow = in_matrix.cells[cell_idx].NETFLOW;
        if (netflow > 0.0)
            out_buy_votes++;
        else if (netflow < 0.0)
            out_sell_votes++;
    }

    return true;
}

double WeightedAverageNetflowScore_g(const sDataMatrix &in_matrix, const int in_row_idx, const int in_symbol_idx)
{
    if (in_matrix.sample_count <= 0 || in_matrix.symbols_num <= 0 || in_matrix.periods_num <= 0)
        return 0.0;
    if (in_row_idx < 0 || in_row_idx >= in_matrix.sample_count)
        return 0.0;
    if (in_symbol_idx < 0 || in_symbol_idx >= in_matrix.symbols_num)
        return 0.0;

    double weighted_sum = 0.0;
    double total_weight = 0.0;
    for (int period_idx = 0; period_idx < in_matrix.periods_num; period_idx++)
    {
        int cell_idx = in_matrix.CellIndex(in_row_idx, in_symbol_idx, period_idx);
        if (cell_idx < 0)
            continue;

        double weight = (double)(period_idx + 1);
        weighted_sum += in_matrix.cells[cell_idx].NETFLOW * weight;
        total_weight += weight;
    }

    if (total_weight <= 0.0)
        return 0.0;

    return weighted_sum / total_weight;
}

ENUM_FUSION_SIGNAL WeightedAverageFusion_g(const sDataMatrix &in_matrix, const int in_row_idx, const int in_symbol_idx)
{
    double score = WeightedAverageNetflowScore_g(in_matrix, in_row_idx, in_symbol_idx);
    if (score > 0.0)
        return ENUM_FUSION_SIGNAL_BUY;
    if (score < 0.0)
        return ENUM_FUSION_SIGNAL_SELL;
    return ENUM_FUSION_SIGNAL_FLAT;
}

bool WeightedAverageFusionSeries_g(const sDataMatrix &in_matrix,
                                   const int in_symbol_idx,
                                   ENUM_FUSION_SIGNAL &out_series[])
{
    ArrayResize(out_series, 0);
    if (in_matrix.sample_count <= 0 || in_matrix.symbols_num <= 0 || in_matrix.periods_num <= 0)
        return false;
    if (in_symbol_idx < 0 || in_symbol_idx >= in_matrix.symbols_num)
        return false;

    ArrayResize(out_series, in_matrix.sample_count);
    for (int row_idx = 0; row_idx < in_matrix.sample_count; row_idx++)
        out_series[row_idx] = WeightedAverageFusion_g(in_matrix, row_idx, in_symbol_idx);

    return true;
}

ENUM_FUSION_SIGNAL ConfirmationFusion_g(const sDataMatrix &in_matrix,
                                        const int in_row_idx,
                                        const int in_symbol_idx,
                                        const int in_min_confirmation_count)
{
    if (in_matrix.sample_count <= 0 || in_matrix.symbols_num <= 0 || in_matrix.periods_num <= 0)
        return ENUM_FUSION_SIGNAL_FLAT;
    if (in_row_idx < 0 || in_row_idx >= in_matrix.sample_count)
        return ENUM_FUSION_SIGNAL_FLAT;
    if (in_symbol_idx < 0 || in_symbol_idx >= in_matrix.symbols_num)
        return ENUM_FUSION_SIGNAL_FLAT;

    int threshold = in_min_confirmation_count;
    if (threshold <= 0)
        threshold = 1;
    if (threshold > in_matrix.periods_num)
        return ENUM_FUSION_SIGNAL_FLAT;

    int buy_votes = 0;
    int sell_votes = 0;
    if (!CountNetflowSignAgreement_g(in_matrix, in_row_idx, in_symbol_idx, buy_votes, sell_votes))
        return ENUM_FUSION_SIGNAL_FLAT;

    // If both sides meet threshold, treat as conflicting/tied consensus and stay flat.
    if (buy_votes >= threshold && sell_votes >= threshold)
        return ENUM_FUSION_SIGNAL_FLAT;
    if (buy_votes >= threshold)
        return ENUM_FUSION_SIGNAL_BUY;
    if (sell_votes >= threshold)
        return ENUM_FUSION_SIGNAL_SELL;
    return ENUM_FUSION_SIGNAL_FLAT;
}

bool ConfirmationFusionSeries_g(const sDataMatrix &in_matrix,
                                const int in_symbol_idx,
                                const int in_min_confirmation_count,
                                ENUM_FUSION_SIGNAL &out_series[])
{
    ArrayResize(out_series, 0);
    if (in_matrix.sample_count <= 0 || in_matrix.symbols_num <= 0 || in_matrix.periods_num <= 0)
        return false;
    if (in_symbol_idx < 0 || in_symbol_idx >= in_matrix.symbols_num)
        return false;

    ArrayResize(out_series, in_matrix.sample_count);
    for (int row_idx = 0; row_idx < in_matrix.sample_count; row_idx++)
        out_series[row_idx] = ConfirmationFusion_g(in_matrix, row_idx, in_symbol_idx, in_min_confirmation_count);

    return true;
}
