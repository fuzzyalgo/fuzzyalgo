# FOREX data storage structure for MetaTrader 5

## PARAMS

- ACCOUNT: Forex account name (e.g., RF5D03)
- YEAR: 4-digit year (e.g., 2025)
- MONTH: 2-digit month (e.g., 12)
- DAY: 2-digit day (e.g., 30)
- ANA: "ANA" (fixed string indicating analysis)
- SYMBOL: Trading symbol (EURGBP, EURUSD, GBPJPY & NZDUSD)

## FILE STRUCTURE EXPLANATION (set of data & image files)

- for symbol in [EURGBP, EURUSD, GBPJPY, NZDUSD]:
    - for type in [INP_ALL, INP_CUR, INP_SCR1, INP_SCR2]:
        - file: <SYMBOL>_INP_<TYPE>.<EXT>
            - where <EXT> is csv for data files and png for image files.

- the file stored in global daily folder is:
  - %APPDATA%\MetaTrader5_<ACCOUNT>\MQL5\Files\<ACCOUNT>\<YEAR>\<MONTH>\<DAY>\<SYMBOL>_INP_<TYPE>.<EXT>
  - example: file EURGBP_INP_ALL.csv for on December 30, 2025 for account RF5D03
    - %APPDATA%\MetaTrader5_RF5D03\MQL5\Files\RF5D03\2025\12\30\EURGBP_INP_ALL.csv

- the file stored in each analysis time folder is:
  - %APPDATA%\MetaTrader5_<ACCOUNT>\MQL5\Files\<ACCOUNT>\<YEAR>\<MONTH>\<DAY>\<ANA>\<HH-MM-SS.mmm>\<SYMBOL>_INP_<TYPE>.<EXT>
  - example: file EURGBP_INP_ALL.csv for analysis time 19:01:00.000 on December 30, 2025 for account RF5D03
    - %APPDATA%\MetaTrader5_RF5D03\MQL5\Files\RF5D03\2025\12\30\ANA\19-01-00.000\EURGBP_INP_ALL.csv

- example set of file names for symbols EURGBP, EURUSD, GBPJPY & NZDUSD
    EURGBP_INP_ALL.csv
    EURGBP_INP_CUR.csv
    EURGBP_INP_SCR1.png
    EURGBP_INP_SCR2.png
    EURUSD_INP_ALL.csv
    EURUSD_INP_CUR.csv
    EURUSD_INP_SCR1.png
    EURUSD_INP_SCR2.png
    GBPJPY_INP_ALL.csv
    GBPJPY_INP_CUR.csv
    GBPJPY_INP_SCR1.png
    GBPJPY_INP_SCR2.png
    NZDUSD_INP_ALL.csv
    NZDUSD_INP_CUR.csv
    NZDUSD_INP_SCR1.png
    NZDUSD_INP_SCR2.png

- the existting set of data & image files within the global daily folder and each of the analysis time folders are the same.
- the data files within the global daily folder are overwritten with each new forex tick during the day.
- the data files within each analysis time folder are static and correspond to the analysis time beginning at the time of the day and ending at the analysis time of the folder named by hour-minute-second.millisecond.

- the SYMBOL_INP_SCR1.png file contains the first screenshot image for the symbol.
- the SYMBOL_INP_SCR2.png file contains the second screenshot image for the symbol.

- the SYMBOL_INP_ALL.csv file contains all data for the symbol for the day up to the current time for the global daily folder or the analysis time for the analysis time folder. 
- the SYMBOL_INP_ALL.csv file does not contain a CSV header row. If required, then use the one from the SYMBOL_INP_CUR.csv file, as data columns are the same. The CSV is sepparated by spaces. In total there are 37 columns.
- the SYMBOL_INP_CUR.csv file contains only one data row for the current most recent data for the symbol up to the current time for the global daily folder or the analysis time for the analysis time folder. 
- the SYMBOL_INP_CUR.csv file contains a CSV header row with column names. In total there are 37 columns and two rows, the header row and the data row. The CSV is sepparated by spaces. In total there are 37 columns.

## data contents examples

- %APPDATA%\MetaTrader5_RF5D03\MQL5\Files\RF5D03\2025\12\30\ANA\19-01-00.000\EURGBP_INP_CUR.csv
    - this file contains only one data row for the current most recent data for the symbol up to the analysis time for the analysis time folder, in this example 19:01:00.000 on December 30, 2025
```cs
epocms        date       time         symbol price   dtickms spread spavg    oc    hl oc_hl  vol T dprofit  dtime  sympro  allpro HIST dtstart     dtend  #deal profit #dealwin profitwin #dealloss profitloss comm  #Adeal Aprofit #Adealwin Aprofitwin #Adealloss Aprofitloss Acomm
1767121319457 2025.12.30 19:01:59.457 EURGBP 0.87286     421      3     4     0    29  0.00 0.01 S     -16   3313   -0.22   -0.95   OK 00:00:00 19:01:58      1  1.29      1  1.29      0  0.00 -0.03      4 -2.50      1  1.29      3 -3.79 -0.12
```


- %APPDATA%\MetaTrader5_RF5D03\MQL5\Files\RF5D03\2025\12\30\ANA\19-01-00.000\EURGBP_INP_ALL.csv
    - this file contains all data for the symbol for the day up to the analysis time for the analysis time folder, in this example 19:01:00.000 on December 30, 2025, but does not contain a CSV header row and here are the last four data rows only:
```cs
epocms        date       time         symbol price   dtickms spread spavg    oc    hl oc_hl  vol T dprofit  dtime  sympro  allpro HIST dtstart     dtend  #deal profit #dealwin profitwin #dealloss profitloss comm  #Adeal Aprofit #Adealwin Aprofitwin #Adealloss Aprofitloss Acomm
1767121316570 2025.12.30 19:01:56.570 EURGBP 0.87286    1439      2     4     2    28  0.07 0.01 S     -16   3309   -0.22   -0.93   OK 00:00:00 19:01:55      1  1.29      1  1.29      0  0.00 -0.03      4 -2.50      1  1.29      3 -3.79 -0.12
1767121317460 2025.12.30 19:01:57.460 EURGBP 0.87286     473      3     4     1    29  0.03 0.01 S     -16   3311   -0.22   -0.94   OK 00:00:00 19:01:56      1  1.29      1  1.29      0  0.00 -0.03      4 -2.50      1  1.29      3 -3.79 -0.12
1767121318459 2025.12.30 19:01:58.459 EURGBP 0.87286     639      2     4     0    29  0.00 0.01 S     -16   3312   -0.22   -0.95   OK 00:00:00 19:01:57      1  1.29      1  1.29      0  0.00 -0.03      4 -2.50      1  1.29      3 -3.79 -0.12
1767121319457 2025.12.30 19:01:59.457 EURGBP 0.87286     421      3     4     0    29  0.00 0.01 S     -16   3313   -0.22   -0.95   OK 00:00:00 19:01:58      1  1.29      1  1.29      0  0.00 -0.03      4 -2.50      1  1.29      3 -3.79 -0.12
```

- %APPDATA%\MetaTrader5_RF5D03\MQL5\Files\RF5D03\2025\12\30\EURGBP_INP_CUR.csv
    - this file contains only one data row for the current most recent data for the symbol up to the current time, here 23:55:00, on December 30, 2025
```cs
epocms        date       time         symbol price   dtickms spread spavg    oc    hl oc_hl  vol T dprofit  dtime  sympro  allpro HIST dtstart     dtend  #deal profit #dealwin profitwin #dealloss profitloss comm  #Adeal Aprofit #Adealwin Aprofitwin #Adealloss Aprofitloss Acomm
1767138900068 2025.12.30 23:55:00.068 EURGBP 0.87220    3740      2    17    -7    23 -0.30 0.01 S      49  20893    0.67   -0.07   OK 00:00:00 23:54:59      1  1.29      1  1.29      0  0.00 -0.03      4 -2.50      1  1.29      3 -3.79 -0.12
```


- %APPDATA%\MetaTrader5_RF5D03\MQL5\Files\RF5D03\2025\12\30\EURGBP_INP_ALL.csv
    - this file contains all data for the symbol for the day up to the current time, here 23:55:00, on December 30, 2025, but does not contain a CSV header row and here are the last four data rows only:
```cs
epocms        date       time         symbol price   dtickms spread spavg    oc    hl oc_hl  vol T dprofit  dtime  sympro  allpro HIST dtstart     dtend  #deal profit #dealwin profitwin #dealloss profitloss comm  #Adeal Aprofit #Adealwin Aprofitwin #Adealloss Aprofitloss Acomm
1767138896839 2025.12.30 23:54:56.839 EURGBP 0.87220     511      2    17    -7    23 -0.30 0.01 S      49  20890    0.67   -0.07   OK 00:00:00 23:54:55      1  1.29      1  1.29      0  0.00 -0.03      4 -2.50      1  1.29      3 -3.79 -0.12
1767138898050 2025.12.30 23:54:58.050 EURGBP 0.87220    1722      2    17    -7    23 -0.30 0.01 S      49  20891    0.67   -0.07   OK 00:00:00 23:54:57      1  1.29      1  1.29      0  0.00 -0.03      4 -2.50      1  1.29      3 -3.79 -0.12
1767138899185 2025.12.30 23:54:59.185 EURGBP 0.87220    2857      2    17    -7    23 -0.30 0.01 S      49  20892    0.67   -0.07   OK 00:00:00 23:54:58      1  1.29      1  1.29      0  0.00 -0.03      4 -2.50      1  1.29      3 -3.79 -0.12
1767138900068 2025.12.30 23:55:00.068 EURGBP 0.87220    3740      2    17    -7    23 -0.30 0.01 S      49  20893    0.67   -0.07   OK 00:00:00 23:54:59      1  1.29      1  1.29      0  0.00 -0.03      4 -2.50      1  1.29      3 -3.79 -0.12
```
## meaning of each column in the data files

```cs
epocms        date       time         symbol price   dtickms spread spavg    oc    hl oc_hl  vol T dprofit  dtime  sympro  allpro HIST dtstart     dtend  #deal profit #dealwin profitwin #dealloss profitloss comm  #Adeal Aprofit #Adealwin Aprofitwin #Adealloss Aprofitloss Acomm
1767138900068 2025.12.30 23:55:00.068 EURGBP 0.87220    3740      2    17    -7    23 -0.30 0.01 S      49  20893    0.67   -0.07   OK 00:00:00 23:54:59      1  1.29      1  1.29      0  0.00 -0.03      4 -2.50      1  1.29      3 -3.79 -0.12
```

- epocms: Epoch time in milliseconds
- date: Date in YYYY.MM.DD format
- time: Time in HH:MM:SS.mmm format
- symbol: Trading symbol
- price: Current price
- dtickms: Delta time in milliseconds since last tick
- spread: Current spread in points
- spavg: Average spread in points
- oc: Open-Close price difference in points
- hl: High-Low price difference in points
- oc_hl: Open-Close divided High-Low price difference (oc / hl)
- vol: Volume of trade
- T: Trade direction (B for Buy, S for Sell, - for None)    
- dprofit: Delta profit in points since last tick
- dtime: Delta time in seconds since last trade
- sympro: Symbol profit in account currency
- allpro: All symbols profit in account currency
- HIST: History status (OK for normal, ERR for error)
- dtstart: Trade start time in HH:MM:SS format
- dtend: Trade end time in HH:MM:SS format
- #deal: Number of closed deals
- profit: Symbol total profit from closed deals in account currency
- #dealwin: Symbol number of winning closed deals
- profitwin: Symbol total profit from winning closed deals in account currency
- #dealloss: Symbol number of losing closed deals
- profitloss: Symbol total loss from losing closed deals in account currency
- comm: Symbol total commission from closed deals in account currency
- #Adeal: All symbols number of closed deals
- Aprofit: All symbols total profit from closed deals in account currency
- #Adealwin: All symbols number of winning closed deals
- Aprofitwin: All symbols total profit from winning closed deals in account currency
- #Adealloss: All symbols number of losing closed deals
- Aprofitloss: All symbols total loss from losing closed deals in account currency
- Acomm: All symbols total commission from closed deals in account currency

## which logical groups do the columns belong to

| Logical Group         | Columns                                                                                 |
|-----------------------|-----------------------------------------------------------------------------------------|
| **TIME status**       | epocms, date, time, symbol                                                              |
| **PRICE status**      | price, dtickms, spread, spavg                                                           |
| **SIGNAL status**     | oc, hl, oc_hl                                                                           |
| **TRADE status**      | vol, T, dprofit, dtime, sympro, allpro                                                  |
| **TRADE HISTORY status** | HIST, dtstart, dtend, #deal, profit, #dealwin, profitwin, #dealloss, profitloss, comm, #Adeal, Aprofit, #Adealwin, Aprofitwin, #Adealloss, Aprofitloss, Acomm |



## PATH STRUCTURE EXPLANATION

- this file README.md is located at:
%APPDATA%\MetaTrader5_RF5D03\MQL5\Files\README.md

- generic path explanation:
    - Each account has its own folder under the MQL5\Files folder
    - Each year has its own folder under the account folder 
    - Each month has its own folder under the year folder
    - Each day has its own folder under the month folder
    - Each "ANA" analysis folder has its own folder under the day folder
    - Each analysis time has its own folder under the analysis ANA folder and is named by the analysis time in hour-minute-second.millisecond format.

- data files and images for analysis done on December 30, 2025:
%APPDATA%\MetaTrader5_RF5D03\MQL5\Files\RF5D03\2025\12\30\

- the analysis folder structure is:
  - %APPDATA%\MetaTrader5_<ACCOUNT>\MQL5\Files\<ACCOUNT>\<YEAR>\<MONTH>\<DAY>\<ANA>\<HH-MM-SS.mmm>\
  - where <ACCOUNT> is the forex account name, <YEAR> is the 4-digit year, <MONTH> is the 2-digit month, <DAY> is the 2-digit day, <ANA> is "ANA", and <HH-MM-SS.mmm> is the analysis time in hour-minute-second.millisecond format.
  - example: analysis time 19:01:00.000 on December 30, 2025 for account RF5D03
    - %APPDATA%\MetaTrader5_RF5D03\MQL5\Files\RF5D03\2025\12\30\ANA\19-01-00.000\
  - example: analysis time 19:02:00.000 on December 30, 2025 for account RF5D03
    - %APPDATA%\MetaTrader5_RF5D03\MQL5\Files\RF5D03\2025\12\30\ANA\19-02-00.000\


