# fuzzyalgo.dev

## Setup fuzzalgo on your pc

### Dependencies

- forex MT5 ECN accounts from [roboforex.com](https://www.roboforex.com/)
- anaconda python (spyder and notebooks) on windows 64bit

### Create free MT5 demo ECN account at [roboforex.com](https://www.roboforex.com/)

- Forex Broker: [roboforex.com](https://www.roboforex.com/)
- Account type: MT5 DEMO ECN / hedge NO 
- MT5 Server:   RoboForex-ECN

### clone git repo

```bash
cd \<your-source-path>
git clone https://github.com/fuzzyalgo/fuzzyalgo.git
```

### install anaconda3 for windows 64bit

- [https://www.anaconda.com/products/distribution](https://www.anaconda.com/products/distribution/)

### setup fuzzyalgo as conda env fuzzyalgo-py38

- run "Anaconda Prompt" or "Anaconda Powershell" as Administrator (admin previledges for creating symlinks)

```PowerShell
> cd \<your-source-path>\fuzzyalgo
> conda create -n fuzzyalgo-py38  nb_conda spyder numpy scipy pandas matplotlib sympy cython  python=3.8
> conda activate fuzzyalgo-py38
> pip install scikit-fuzzy pynput MetaTrader5
> pip install .\fuzzyalgo\install\TA_Lib-0.4.24-cp38-cp38-win_amd64.whl
> python setup.py
> conda deactivate
```

```bash
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
```

### populate cf_accounts_\<your-username\>@\<your-hostname\>.json with MT5 login and password

- template:
```bash
C:\<your-source-path>\fuzzyalgo\MetaTrader5_TMPL\config_RoboForex-ECN\cf_accounts.tmpl
```

- original:
```bash
C:\<your-source-path>\fuzzyalgo\MetaTrader5_TMPL\config_RoboForex-ECN\cf_accounts_<your-username>@<your-hostname>.json
```

- links:
```bash
%APPDATA%\MetaTrader5_RF5D01\config\cf_accounts_<your-username>@<your-hostname>.json
%APPDATA%\MetaTrader5_RF5D02\config\cf_accounts_<your-username>@<your-hostname>.json
%APPDATA%\MetaTrader5_RF5D03\config\cf_accounts_<your-username>@<your-hostname>.json
%APPDATA%\MetaTrader5_RF5D04\config\cf_accounts_<your-username>@<your-hostname>.json
```

- note: config\*.json are excluded from git

```JSON
{
   "RF5D01":{
      "login" : 0,
      "password" : "your-password-here",
      "server" : "RoboForex-ECN",
      "portable" : "True"
   },
   "RF5D02":{
      "login" : 0,
      "password" : "your-password-here",
      "server" : "RoboForex-ECN",
      "portable" : "True"
   },
   "RF5D03":{
      "login" : 0,
      "password" : "your-password-here",
      "server" : "RoboForex-ECN",
      "portable" : "True"
   },
   "RF5D04":{
      "login" : 0,
      "password" : "your-password-here",
      "server" : "RoboForex-ECN",
      "portable" : "True"
   }
}
```

### run fuzzyalgo conda env fuzzyalgo-py38

#### run from windows start menu 'Spyder (fuzzyalgo-py38)' or 'Jupyter Notebook (fuzzyalgo-py38)'

```bash
$ cd  "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Anaconda3 (64-bit)"
$ %APPDATA%\Microsoft\Windows\Start Menu\Programs\Anaconda3 (64-bit)>dir /b
	Anaconda Navigator (anaconda3).lnk
	Anaconda Powershell Prompt (anaconda3).lnk
	Anaconda Prompt (anaconda3).lnk
	Jupyter Notebook (anaconda3).lnk
->	Jupyter Notebook (fuzzyalgo-py38).lnk
	Reset Spyder Settings (anaconda3).lnk
	Reset Spyder Settings (fuzzyalgo-py38).lnk
	Spyder (anaconda3).lnk
->	Spyder (fuzzyalgo-py38).lnk
```


#### run from 'Anaconda Prompt'

- start 'Anaconda Cmd Prompt' or 'Anaconda Powershell Prompt' 

##### spyder
```bash
> conda activate fuzzyalgo-py38
> cd \<your-source-path>\fuzzyalgo
> spyder 
> conda deactivate
```

##### jupyter notebook
```bash
> conda activate fuzzyalgo-py38
> cd \<your-source-path>\fuzzyalgo
> jupyter notebook
> conda deactivate
```

##### python
```bash
> conda activate fuzzyalgo-py38
> cd \<your-source-path>\fuzzyalgo
> python <your-python>.py
> conda deactivate
```

## re-install conda env fuzzyalgo-py38

```bash
# if activated, then deactivate first
> conda activate fuzzyalgo-py38
> cd \<your-source-path>\fuzzyalgo
> jupyter notebook
> conda deactivate
# remove the env
> conda env remove -n fuzzyalgo-py38
# re-install the env
> cd \<your-source-path>\fuzzyalgo
> conda create -n fuzzyalgo-py38 spyder numpy scipy pandas matplotlib sympy cython nb_conda
> conda activate fuzzyalgo-py38
> python --version
	Python 3.8.15
> pip install scikit-fuzzy pynput MetaTrader5
> pip install C:\<your-source-path>\fuzzyalgo\install\TA_Lib-0.4.24-cp38-cp38-win_amd64.whl
> python setup.py
> conda deactivate
```

#### https://stackoverflow.com/questions/36851746/jupyter-notebook-500-internal-server-error?rq=1

```bash
(fuzzyalgo-py38) >pip install --upgrade --user nbconvert
	Installing collected packages: mistune, nbconvert
	  WARNING: The scripts jupyter-dejavu.exe and jupyter-nbconvert.exe are installed in '%APPDATA%\Python\Python38\Scripts' which is not on PATH.
	  Consider adding this directory to PATH or, if you prefer to suppress this warning, use --no-warn-script-location.
	Successfully installed mistune-2.0.4 nbconvert-7.2.7

(fuzzyalgo-py38) > dir %APPDATA%\Python\Python38\Scripts

	Directory of %APPDATA%\Python\Python38\Scripts
	23/05/2023  20:09           108.421 jupyter-dejavu.exe
	23/05/2023  20:09           108.407 jupyter-nbconvert.exe
				   2 File(s)        216.828 bytes

(fuzzyalgo-py38) > copy %APPDATA%\Python\Python38\Scripts\Python\Python38\Scripts\jupyter-*.exe C:\apps\anaconda3\envs\fuzzyalgo-py38\Scripts
```


#### https://stackoverflow.com/questions/40114639/jupyter-conda-tab-an-error-occurred-while-retrieving-package-information/trackback/

```bash
jupyter serverextension disable nb_conda
jupyter serverextension enable nb_conda
conda install -c conda-forge nb_conda_kernels
```


