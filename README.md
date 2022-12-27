# fuzzyalgo.dev

## Setup fuzzalgo on your pc

### Dependencies

- forex MT5 ECN accounts from roboforex.com
- anaconda python (spyder and notebooks) on windows 64bit

### Create free MT5 demo ECN account at roboforex.com

- Forex Broker: roboforex.com
- Account type: MT5 DEMO ECN / hedge NO 
- MT5 Server:   RoboForex-ECN

### clone git repo

cd \<your-source-path>
git clone https://github.com/fuzzyalgo/fuzzyalgo.git


### install anaconda3 for windows 64bit

https://www.anaconda.com/products/distribution

### setup fuzzyalgo as conda env fuzzyalgo-py38

- run "Anaconda Prompt" or "Anaconda Powershell" as Administrator (admin previledges for creating symlinks)

> cd \<your-source-path>\fuzzyalgo
> conda create -n fuzzyalgo-py38  nb_conda spyder numpy scipy pandas matplotlib sympy cython  python=3.8
> conda activate fuzzyalgo-py38
> pip install scikit-fuzzy pynput MetaTrader5
> pip install C:\<your-source-path>\fuzzyalgo\install\TA_Lib-0.4.24-cp38-cp38-win_amd64.whl
> python setup.py
> conda deactivate


(base) C:\Windows\system32>cd \<your-source-path>\fuzzyalgo
(base) C:\<your-source-path>\fuzzyalgo>
(base) C:\<your-source-path>\fuzzyalgo> conda create -n fuzzyalgo-py38  nb_conda spyder numpy scipy pandas matplotlib sympy cython  python=3.8
(fuzzyalgo-py38) C:\<your-source-path>\fuzzyalgo>
(fuzzyalgo-py38) C:\<your-source-path>\fuzzyalgo> pip install scikit-fuzzy pynput MetaTrader5
(fuzzyalgo-py38) C:\<your-source-path>\fuzzyalgo> pip install C:\<your-source-path>\fuzzyalgo\install\TA_Lib-0.4.24-cp38-cp38-win_amd64.whl
(fuzzyalgo-py38) C:\<your-source-path>\fuzzyalgo> python setup.py
	Run: win-64bit in conda env:  fuzzyalgo-py38
	dir_py_lib:  C:\<your-anaconda3-path>\anaconda3\envs\fuzzyalgo-py38\Lib
	dir_cwd:     C:\<your-source-path>\fuzzyalgo
	dir_script:  C:\<your-source-path>\fuzzyalgo
	name_user:   <your-username>
	name_host:   <your-hostname>
	mt5-server:  RoboForex-ECN
(fuzzyalgo-py38) C:\<your-source-path>\fuzzyalgo> conda deactivate
(base) C:\<your-source-path>\fuzzyalgo>

### populate cf_accounts_<your-username>@<your-hostname>.json with MT5 login and password

template:
C:\<your-source-path>\fuzzyalgo\MetaTrader5_TMPL\config_RoboForex-ECN\cf_accounts.tmpl
original:
C:\<your-source-path>\fuzzyalgo\MetaTrader5_TMPL\config_RoboForex-ECN\cf_accounts_<your-username>@<your-hostname>.json
links:
C:\%APPDATA%\MetaTrader5_RF5D01\config\cf_accounts_<your-username>@<your-hostname>.json
C:\%APPDATA%\MetaTrader5_RF5D02\config\cf_accounts_<your-username>@<your-hostname>.json
C:\%APPDATA%\MetaTrader5_RF5D03\config\cf_accounts_<your-username>@<your-hostname>.json
C:\%APPDATA%\MetaTrader5_RF5D04\config\cf_accounts_<your-username>@<your-hostname>.json

note: config\*.json are excluded from git

<code>
{
   "RF5D01":{
      "path" : "MetaTrader5_RF5D01\\terminal64.exe",
      "login" : 0,
      "password" : "your-password-here",
      "server" : "RoboForex-ECN",
      "portable" : "True"
   },
   "RF5D02":{
      "path" : "MetaTrader5_RF5D02\\terminal64.exe",
      "login" : 0,
      "password" : "your-password-here",
      "server" : "RoboForex-ECN",
      "portable" : "True"
   },
   "RF5D03":{
   
      "path" : "MetaTrader5_RF5D03\\terminal64.exe",
      "login" : 0,
      "password" : "your-password-here",
      "server" : "RoboForex-ECN",
      "portable" : "True"
   },
   "RF5D04":{
      "path" : "MetaTrader5_RF5D03\\terminal64.exe",
      "login" : 0,
      "password" : "your-password-here",
      "server" : "RoboForex-ECN",
      "portable" : "True"
   }
}
</code>

### run fuzzyalgo conda env fuzzyalgo-py38

#### run from windows start menu 'Spyder (fuzzyalgo-py38)' or 'Jupyter Notebook (fuzzyalgo-py38)'

$ cd  "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Anaconda3 (64-bit)"
$ C:\%APPDATA%\Microsoft\Windows\Start Menu\Programs\Anaconda3 (64-bit)>dir /b
	Anaconda Navigator (anaconda3).lnk
	Anaconda Powershell Prompt (anaconda3).lnk
	Anaconda Prompt (anaconda3).lnk
	Jupyter Notebook (anaconda3).lnk
->	Jupyter Notebook (fuzzyalgo-py38).lnk
	Reset Spyder Settings (anaconda3).lnk
	Reset Spyder Settings (fuzzyalgo-py38).lnk
	Spyder (anaconda3).lnk
->	Spyder (fuzzyalgo-py38).lnk


#### run from 'Anaconda Prompt'

- start 'Anaconda Cmd Prompt' or 'Anaconda Powershell Prompt' 

##### spyder
> conda activate fuzzyalgo-py38
> cd \<your-source-path>\fuzzyalgo
> spyder 
> conda deactivate

##### jupyter notebook
> conda activate fuzzyalgo-py38
> cd \<your-source-path>\fuzzyalgo
> jupyter notebook
> conda deactivate

##### python
> conda activate fuzzyalgo-py38
> cd \<your-source-path>\fuzzyalgo
> python <>
> conda deactivate


