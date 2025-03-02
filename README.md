# fuzzyalgo.dev

## Setup fuzzalgo on your pc

### Dependencies

- forex MT5 ECN accounts from [roboforex.com](https://www.roboforex.com/)
- miniforge python (spyder and notebooks) on windows 64bit

### Create free MT5 demo ECN account at [roboforex.com](https://www.roboforex.com/)

- Forex Broker: [roboforex.com](https://www.roboforex.com/)
- Account type: MT5 DEMO ECN / hedge NO 
- MT5 Server:   RoboForex-ECN

### clone git repo

```bash

# test you access to github
ssh -T git@github.com
cd \<your-source-path>
# clone the directory
git clone git@github.com:fuzzyalgo/fuzzyalgo.git

```

### install miniforge3 for windows 64bit

- [https://github.com/conda-forge/miniforge](https://github.com/conda-forge/miniforge)

```bash
https://github.com/conda-forge/miniforge
https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe

Start Windows Command Prompt:

> wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe -o Miniforge3-Windows-x86_64.exe
> start /wait "" Miniforge3-Windows-x86_64.exe /InstallationType=JustMe /RegisterPython=1 /S /D=%UserProfile%\Miniforge3
> del Miniforge3-Windows-x86_64.exe

    Please update conda by running
        $ conda update -n base -c conda-forge conda

```

### setup fuzzyalgo as linux conda env fuzzyalgo-py384



```bash
$ cd \<your-source-path>\fuzzyalgo
$ conda create -n fuzzyalgo-py312  nb_conda spyder numpy scipy pandas matplotlib sympy cython  python=3.12
$ conda activate fuzzyalgo-py312
# https://github.com/TA-Lib/ta-lib-python
$ conda install -c conda-forge ta-lib
$ conda install -c conda-forge libta-lib
# https://ta-lib.org/install/#linux-build-from-source
# $ wget https://github.com/ta-lib/ta-lib/releases/download/v0.6.4/ta-lib-0.6.4-src.tar.gz
$ cd install
$ tar -xvf ./install/ta-lib-0.6.4-src.tar.gz
$ cd ta-lib-0.6.4
$ ./configure -prefix=/usr
$ make 
$ sudo make install
$ sudo ldconfig
$ python 
>>> import talib
$ cd ..
$ rm -Rf ta-lib-0.6.4
$ cd ..
$ pip install filterpy scikit-fuzzy networkx pynput 
# do that later in wine python installation
# $ pip install MetaTrader5
$ python setup.py
$ conda deactivate
```


### setup fuzzyalgo as conda env fuzzyalgo-py38

- run "Miniforge Prompt" or "Miniforge Powershell" as Administrator (admin previledges for creating symlinks)

```PowerShell
> cd \<your-source-path>\fuzzyalgo
> conda create -n fuzzyalgo-py38  nb_conda spyder numpy scipy pandas matplotlib sympy cython  python=3.8
> conda activate fuzzyalgo-py38
> pip install filterpy scikit-fuzzy networkx pynput MetaTrader5
> pip install .\install\TA_Lib-0.4.24-cp38-cp38-win_amd64.whl
> python setup.py
> conda deactivate
```

```bash
(base) C:\Windows\system32>cd \<your-source-path>\fuzzyalgo
(base) \<your-source-path>\fuzzyalgo>
(base) \<your-source-path>\fuzzyalgo> conda create -n fuzzyalgo-py38  nb_conda spyder numpy scipy pandas matplotlib sympy cython  python=3.8
(fuzzyalgo-py38) \<your-source-path>\fuzzyalgo>
(fuzzyalgo-py38) \<your-source-path>\fuzzyalgo> pip install filterpy scikit-fuzzy networkx pynput MetaTrader5
(fuzzyalgo-py38) \<your-source-path>\fuzzyalgo> pip install .\install\TA_Lib-0.4.24-cp38-cp38-win_amd64.whl
(fuzzyalgo-py38) \<your-source-path>\fuzzyalgo> python setup.py
	Run: win-64bit in conda env:  fuzzyalgo-py38
	dir_py_lib:  \<your-miniforge3-path>\miniforge3\envs\fuzzyalgo-py38\Lib
	dir_cwd:     \<your-source-path>\fuzzyalgo
	dir_script:  \<your-source-path>\fuzzyalgo
	name_user:   <your-username>
	name_host:   <your-hostname>
	mt5-server:  RoboForex-ECN
(fuzzyalgo-py38) \<your-source-path>\fuzzyalgo> conda deactivate
(base) \<your-source-path>\fuzzyalgo>
```

### populate cf_accounts_\<your-username\>@\<your-hostname\>.json with MT5 login and password

- template:
```bash
\<your-source-path>\fuzzyalgo\MetaTrader5_TMPL\config_RoboForex-ECN\cf_accounts.tmpl
```

- original:
```bash
\<your-source-path>\fuzzyalgo\MetaTrader5_TMPL\config_RoboForex-ECN\cf_accounts_<your-username>@<your-hostname>.json
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

#### run from 'Miniforge Prompt'

- start 'Miniforge Cmd Prompt' or 'Miniforge Powershell Prompt' 

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
> conda create -n fuzzyalgo-py38  nb_conda spyder numpy scipy pandas matplotlib sympy cython  python=3.8
> conda activate fuzzyalgo-py38
> python --version
	Python 3.8.15
> pip install filterpy scikit-fuzzy networkx pynput MetaTrader5
> pip install .\install\TA_Lib-0.4.24-cp38-cp38-win_amd64.whl
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

(fuzzyalgo-py38) > copy %APPDATA%\Python\Python38\Scripts\Python\Python38\Scripts\jupyter-*.exe C:\apps\miniforge3\envs\fuzzyalgo-py38\Scripts
```


#### https://stackoverflow.com/questions/40114639/jupyter-conda-tab-an-error-occurred-while-retrieving-package-information/trackback/

```bash
jupyter serverextension disable nb_conda
jupyter serverextension enable nb_conda
conda install -c conda-forge nb_conda_kernels
```


#### TBD use it under linux

```bash

win
> pip install .\install\TA_Lib-0.4.24-cp38-cp38-win_amd64.whl
> pip install MetaTrader5

linux
   https://pypi.org/project/ta-lib
   https://github.com/ta-lib/ta-lib-python
   https://ta-lib.org/
      $ pip install ta-lib

   https://pypi.org/project/MetaTrader5/
      from: MetaTrader5-5.0.4803-cp39-cp39-win_amd64.whl
      to:  MetaTrader5-5.0.4803-cp39-none-any.whl
      $ pip install .\install\MetaTrader5-5.0.4803-cp39-none-any.whl

linux links
   https://pypi.org/project/mt5linux/
      https://github.com/lucas-campagna/mt5linux
   https://pypi.org/project/mt5linux-tc/
      https://github.com/Traders-Connect/mt5linux-tc   
   https://medium.com/@asc686f61/use-mt5-in-linux-with-docker-and-python-f8a9859d65b1
      https://github.com/ASC689561/fx-tinny/
```
