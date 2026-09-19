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

struct sFusionWeights
{
    double w[];

    void InitDefault(const int in_periods_num)
    {
        ArrayResize(w, 0);
        if (in_periods_num <= 0)
            return;

        ArrayResize(w, in_periods_num);
        for (int period_idx = 0; period_idx < in_periods_num; period_idx++)
            w[period_idx] = (double)(period_idx + 1);
    }
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

double FusionStaticWeightAt_g(const sFusionWeights &in_weights, const int in_period_idx)
{
    int weights_num = ArraySize(in_weights.w);
    if (in_period_idx >= 0 && in_period_idx < weights_num)
        return in_weights.w[in_period_idx];
    return (double)(in_period_idx + 1);
}

ENUM_FUSION_SIGNAL FusionSignalFromScore_g(const double in_score)
{
    if (in_score > 0.0)
        return ENUM_FUSION_SIGNAL_BUY;
    if (in_score < 0.0)
        return ENUM_FUSION_SIGNAL_SELL;
    return ENUM_FUSION_SIGNAL_FLAT;
}

ENUM_FUSION_SIGNAL ConfirmationSignalFromVotes_g(const int in_buy_votes,
                                                 const int in_sell_votes,
                                                 const int in_threshold)
{
    if (in_buy_votes >= in_threshold && in_sell_votes >= in_threshold)
        return ENUM_FUSION_SIGNAL_FLAT;
    if (in_buy_votes >= in_threshold)
        return ENUM_FUSION_SIGNAL_BUY;
    if (in_sell_votes >= in_threshold)
        return ENUM_FUSION_SIGNAL_SELL;
    return ENUM_FUSION_SIGNAL_FLAT;
}

int ResolveTieBreakerPeriodIdx_g(const sDataMatrix &in_matrix, const int in_period_idx)
{
    if (in_matrix.periods_num <= 1)
        return -1;
    if (in_period_idx >= 0 && in_period_idx < in_matrix.periods_num)
        return in_period_idx;
    return in_matrix.periods_num - 1;
}

ENUM_FUSION_SIGNAL OCHLTieBreakerSignal_g(const sDataMatrix &in_matrix,
                                          const int in_row_idx,
                                          const int in_symbol_idx,
                                          const int in_period_idx,
                                          double &out_oc_hl,
                                          int &out_tie_breaker_period_idx)
{
    out_oc_hl = 0.0;
    out_tie_breaker_period_idx = ResolveTieBreakerPeriodIdx_g(in_matrix, in_period_idx);
    if (out_tie_breaker_period_idx < 0)
        return ENUM_FUSION_SIGNAL_FLAT;

    int cell_idx = in_matrix.CellIndex(in_row_idx, in_symbol_idx, out_tie_breaker_period_idx);
    if (cell_idx < 0)
        return ENUM_FUSION_SIGNAL_FLAT;

    // OC_HL is already normalized upstream as OC / HL, so only its sign is
    // used here as a scale-independent tie-breaker across periods/symbols.
    out_oc_hl = in_matrix.cells[cell_idx].OC_HL;
    if (out_oc_hl > 0.0)
        return ENUM_FUSION_SIGNAL_BUY;
    if (out_oc_hl < 0.0)
        return ENUM_FUSION_SIGNAL_SELL;
    return ENUM_FUSION_SIGNAL_FLAT;
}

ENUM_FUSION_SIGNAL ApplyOCHLTieBreaker_g(const sDataMatrix &in_matrix,
                                         const int in_row_idx,
                                         const int in_symbol_idx,
                                         const int in_period_idx,
                                         const string in_context,
                                         const bool in_log_tie_breaker,
                                         bool &out_tie_breaker_used)
{
    out_tie_breaker_used = false;

    double oc_hl = 0.0;
    int tie_breaker_period_idx = -1;
    ENUM_FUSION_SIGNAL tie_signal = OCHLTieBreakerSignal_g(in_matrix,
                                                           in_row_idx,
                                                           in_symbol_idx,
                                                           in_period_idx,
                                                           oc_hl,
                                                           tie_breaker_period_idx);
    if (tie_breaker_period_idx < 0)
        return ENUM_FUSION_SIGNAL_FLAT;

    out_tie_breaker_used = true;
    if (in_log_tie_breaker)
    {
        string symbol = "";
        string period = "";
        if (in_symbol_idx >= 0 && in_symbol_idx < ArraySize(in_matrix.symbols_arr))
            symbol = in_matrix.symbols_arr[in_symbol_idx];
        if (tie_breaker_period_idx >= 0 && tie_breaker_period_idx < ArraySize(in_matrix.periods_arr))
            period = in_matrix.periods_arr[tie_breaker_period_idx];

        Print(StringFormat("[SignalFusion tie-breaker] %s row=%d symbol=%s period=%s(idx=%d) OC_HL=%+.6f -> %s",
                           in_context,
                           in_row_idx,
                           symbol,
                           period,
                           tie_breaker_period_idx,
                           oc_hl,
                           FusionSignalToString_g(tie_signal)));
    }

    return tie_signal;
}

double FuseNetflowRow_g(const sDataMatrix &in_matrix,
                        const int in_row_idx,
                        const int in_symbol_idx,
                        const sFusionWeights &in_weights,
                        const bool in_use_adaptive_weighting)
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

        double static_weight = FusionStaticWeightAt_g(in_weights, period_idx);
        if (static_weight <= 0.0)
            continue;

        double effective_weight = static_weight;
        if (in_use_adaptive_weighting)
        {
            // VOLS_TD is ticks-per-second density for this period/row. Higher
            // density means "fresher/richer sample", so we scale static period
            // weights by it to adapt influence per row.
            double volstd = in_matrix.cells[cell_idx].VOLS_TD;
            if (volstd <= 0.0)
                continue;
            effective_weight *= volstd;
        }

        if (effective_weight <= 0.0)
            continue;

        weighted_sum += in_matrix.cells[cell_idx].NETFLOW * effective_weight;
        total_weight += effective_weight;
    }

    if (total_weight <= 0.0)
        return 0.0;

    return weighted_sum / total_weight;
}

bool FuseNetflowSeries_g(const sDataMatrix &in_matrix,
                         const int in_symbol_idx,
                         const sFusionWeights &in_weights,
                         const bool in_use_adaptive_weighting,
                         double &out_scores[])
{
    ArrayResize(out_scores, 0);
    if (in_matrix.sample_count <= 0 || in_matrix.symbols_num <= 0 || in_matrix.periods_num <= 0)
        return false;
    if (in_symbol_idx < 0 || in_symbol_idx >= in_matrix.symbols_num)
        return false;

    ArrayResize(out_scores, in_matrix.sample_count);
    for (int row_idx = 0; row_idx < in_matrix.sample_count; row_idx++)
        out_scores[row_idx] = FuseNetflowRow_g(in_matrix, row_idx, in_symbol_idx, in_weights, in_use_adaptive_weighting);

    return true;
}

double WeightedAverageNetflowScore_g(const sDataMatrix &in_matrix, const int in_row_idx, const int in_symbol_idx)
{
    sFusionWeights default_weights;
    default_weights.InitDefault(in_matrix.periods_num);
    return FuseNetflowRow_g(in_matrix, in_row_idx, in_symbol_idx, default_weights, false);
}

ENUM_FUSION_SIGNAL WeightedAverageFusion_g(const sDataMatrix &in_matrix,
                                           const int in_row_idx,
                                           const int in_symbol_idx,
                                           const sFusionWeights &in_weights,
                                           const bool in_use_adaptive_weighting,
                                           const int in_tie_breaker_period_idx = -1,
                                           const bool in_log_tie_breaker = true)
{
    double score = FuseNetflowRow_g(in_matrix, in_row_idx, in_symbol_idx, in_weights, in_use_adaptive_weighting);
    ENUM_FUSION_SIGNAL signal = FusionSignalFromScore_g(score);
    if (ENUM_FUSION_SIGNAL_FLAT != signal)
        return signal;

    bool tie_breaker_used = false;
    ENUM_FUSION_SIGNAL tie_signal = ApplyOCHLTieBreaker_g(in_matrix,
                                                          in_row_idx,
                                                          in_symbol_idx,
                                                          in_tie_breaker_period_idx,
                                                          in_use_adaptive_weighting ? "weighted-adaptive" : "weighted-static",
                                                          in_log_tie_breaker,
                                                          tie_breaker_used);
    if (ENUM_FUSION_SIGNAL_FLAT != tie_signal)
        return tie_signal;
    return signal;
}

ENUM_FUSION_SIGNAL WeightedAverageFusion_g(const sDataMatrix &in_matrix, const int in_row_idx, const int in_symbol_idx)
{
    sFusionWeights default_weights;
    default_weights.InitDefault(in_matrix.periods_num);
    return WeightedAverageFusion_g(in_matrix, in_row_idx, in_symbol_idx, default_weights, false, -1, true);
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

    sFusionWeights default_weights;
    default_weights.InitDefault(in_matrix.periods_num);

    ArrayResize(out_series, in_matrix.sample_count);
    for (int row_idx = 0; row_idx < in_matrix.sample_count; row_idx++)
        out_series[row_idx] = WeightedAverageFusion_g(in_matrix,
                                                      row_idx,
                                                      in_symbol_idx,
                                                      default_weights,
                                                      false,
                                                      -1,
                                                      true);

    return true;
}

bool WeightedAverageFusionSeries_g(const sDataMatrix &in_matrix,
                                   const int in_symbol_idx,
                                   const sFusionWeights &in_weights,
                                   const bool in_use_adaptive_weighting,
                                   ENUM_FUSION_SIGNAL &out_series[],
                                   const int in_tie_breaker_period_idx = -1,
                                   const bool in_log_tie_breaker = true)
{
    ArrayResize(out_series, 0);
    if (in_matrix.sample_count <= 0 || in_matrix.symbols_num <= 0 || in_matrix.periods_num <= 0)
        return false;
    if (in_symbol_idx < 0 || in_symbol_idx >= in_matrix.symbols_num)
        return false;

    ArrayResize(out_series, in_matrix.sample_count);
    for (int row_idx = 0; row_idx < in_matrix.sample_count; row_idx++)
        out_series[row_idx] = WeightedAverageFusion_g(in_matrix,
                                                      row_idx,
                                                      in_symbol_idx,
                                                      in_weights,
                                                      in_use_adaptive_weighting,
                                                      in_tie_breaker_period_idx,
                                                      in_log_tie_breaker);

    return true;
}

ENUM_FUSION_SIGNAL ConfirmationFusion_g(const sDataMatrix &in_matrix,
                                        const int in_row_idx,
                                        const int in_symbol_idx,
                                        const int in_min_confirmation_count,
                                        const int in_tie_breaker_period_idx = -1,
                                        const bool in_log_tie_breaker = true)
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

    ENUM_FUSION_SIGNAL signal = ConfirmationSignalFromVotes_g(buy_votes, sell_votes, threshold);
    if (ENUM_FUSION_SIGNAL_FLAT != signal)
        return signal;

    bool tie_breaker_used = false;
    ENUM_FUSION_SIGNAL tie_signal = ApplyOCHLTieBreaker_g(in_matrix,
                                                          in_row_idx,
                                                          in_symbol_idx,
                                                          in_tie_breaker_period_idx,
                                                          "confirmation",
                                                          in_log_tie_breaker,
                                                          tie_breaker_used);
    if (ENUM_FUSION_SIGNAL_FLAT != tie_signal)
        return tie_signal;
    return signal;
}

bool ConfirmationFusionSeries_g(const sDataMatrix &in_matrix,
                                const int in_symbol_idx,
                                const int in_min_confirmation_count,
                                ENUM_FUSION_SIGNAL &out_series[],
                                const int in_tie_breaker_period_idx = -1,
                                const bool in_log_tie_breaker = true)
{
    ArrayResize(out_series, 0);
    if (in_matrix.sample_count <= 0 || in_matrix.symbols_num <= 0 || in_matrix.periods_num <= 0)
        return false;
    if (in_symbol_idx < 0 || in_symbol_idx >= in_matrix.symbols_num)
        return false;

    ArrayResize(out_series, in_matrix.sample_count);
    for (int row_idx = 0; row_idx < in_matrix.sample_count; row_idx++)
        out_series[row_idx] = ConfirmationFusion_g(in_matrix,
                                                   row_idx,
                                                   in_symbol_idx,
                                                   in_min_confirmation_count,
                                                   in_tie_breaker_period_idx,
                                                   in_log_tie_breaker);

    return true;
}
