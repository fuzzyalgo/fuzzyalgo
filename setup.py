import sys
import os
import os.path
import struct
import ctypes
import psutil
import re
import json
import shutil


def python_dirs():
    """return path where site-packes Lib directory is"""
    dir_py_lib = os.path.join(sys.prefix, "Lib")
    # get current working dir
    dir_cwd    = os.getcwd()
    # get directory of this script __file__ setup.py
    dir_script = os.path.dirname(os.path.realpath(sys.argv[0])) 
    # get appdata dir
    # https://stackoverflow.com/questions/13184414/how-can-i-get-the-path-to-the-appdata-directory-in-python
    dir_appdata =  os.getenv('APPDATA') 

    return dir_cwd, dir_script, dir_py_lib, dir_appdata

def sanity_checks():
    """check sanity here: win-64bit with admin priviledges in the root dir called from cmd.exe"""

    # first check that we run as: 
    # win-64bit with admin priviledges in the root dir called from cmd.exe

    # check for win platform
    if 'win32' != sys.platform:
        raise ValueError( "E: only runs on win32 and not on: " + sys.platform )
    
    # check for 64bit
    # https://stackoverflow.com/questions/1405913/how-do-i-determine-if-my-python-shell-is-executing-in-32bit-or-64bit
    if 64 != struct.calcsize('P')*8:
        raise ValueError( "E: only runs on 64bits and not on: " + struct.calcsize('P')*8 )

    ## check that setup.py is run from %COMSPEC% cmd.exe
    ##  note: run on cmd.exe as e.g. on powershell.exe mklink.exe
    ##   which is used later is missing.
    ## https://stackoverflow.com/questions/37394484/how-do-i-detect-if-my-python-code-is-running-in-powershell-or-the-command-prompt
    #parent_pid = os.getppid()
    #shell_name = psutil.Process(parent_pid).name()
    #if not bool(re.fullmatch('cmd|cmd.exe', shell_name)):
    #    print( 'shell: ', shell_name )
    #    raise ValueError( "E: only runs on %COMSPEC% cmd.exe and not on " + shell_name )
        
    # https://stackoverflow.com/questions/36539623/how-do-i-find-the-name-of-the-conda-environment-in-which-my-code-is-running
    if bool(re.fullmatch('base', os.environ['CONDA_DEFAULT_ENV'])):
        print("%CONDA_DEFAULT_ENV% : ", os.environ['CONDA_DEFAULT_ENV'])
        print("%CONDA_PREFIX%      : ",  os.environ["CONDA_PREFIX"])
        # https://stackoverflow.com/questions/29925978/python-execute-windows-cmd-functions
        print( "'> conda env list'" )
        os.system("conda env list")
        raise ValueError( "E: please run '> conda activate <your-env>' first before running '> python setup.py' " )

    # https://stackoverflow.com/questions/41851413/ask-for-admin-access-for-a-python-function-in-windows
    if not ctypes.windll.shell32.IsUserAnAdmin():
        raise ValueError( "E: only runs as Admin from cmd.exe")

    dir_cwd, dir_script, dir_py_lib, dir_appdata = python_dirs()

    # run from root dir only
    # execute setup.py as:
    # (jupyter-env) C:\Users\G6\algotrader> python setup.py
    # and not as:
    # (jupyter-env) C:\Users\G6> python algotrader/setup.py
    if dir_cwd != dir_script:
        raise ValueError( "E: execute as: (jupyter-env) " + dir_script + "> python setup.py")


def get_environment():

    # https://stackoverflow.com/questions/4271740/how-can-i-use-python-to-get-the-system-hostname
    # import os
    # os.getenv('computername')
    #  or 
    # import socket
    # socket.gethostname() 
    #  or 
    # import platform
    # platform node

    name_host = os.getenv('computername')
    
    # https://stackoverflow.com/questions/13654122/how-to-make-python-get-the-username-in-windows-and-then-implement-it-in-a-script
    # import os
    # os.getenv('username')
    #   or 
    # import os
    # os.getlogin()
    
    name_user = os.getenv('username')
    
    return name_user, name_host, os.environ['CONDA_DEFAULT_ENV']
    

# https://stackoverflow.com/questions/1447575/symlinks-on-windows
def symlink(source, link_name):
    '''symlink(source, link_name)
       Creates a symbolic link pointing to source named link_name'''
    import ctypes
    csl = ctypes.windll.kernel32.CreateSymbolicLinkW
    csl.argtypes = (ctypes.c_wchar_p, ctypes.c_wchar_p, ctypes.c_uint32)
    csl.restype = ctypes.c_ubyte
    flags = 0
    if source is not None and os.path.isdir(source):
        flags = 1
    if csl(link_name, source, flags) == 0:
        print('ERROR ctypes.windll.kernel32.CreateSymbolicLinkW: ',' link_name: ', link_name, ' source: ', source, ' isdir: ', flags)
        raise ctypes.WinError()   

    
def setup():

    # will raise exception here if there is no sanity
    sanity_checks()

    dir_cwd, dir_script, dir_py_lib, dir_appdata = python_dirs()
    
    name_user, name_host, conda_env = get_environment()
    
    print( 'Run: win-64bit in conda env: ', conda_env  )
    print( 'dir_appdata: ', dir_appdata )
    print( 'dir_py_lib:  ', dir_py_lib )
    print( 'dir_cwd:     ', dir_cwd )
    print( 'dir_script:  ', dir_script )
    print( 'name_user:   ', name_user )
    print( 'name_host:   ', name_host )
    
    
    supported_mt5_servers = []
    supported_mt5_servers.append( 'RoboForex-ECN' )
    for srv in supported_mt5_servers:
        print( 'mt5-server:  ', srv )
        
        # copy template files - cf_periods, cf_symbols, cf_pid_params
        #  TODO later they will be part of cf_accounts
        cf_files = ['cf_periods', 'cf_symbols', 'cf_pid_params']
        for cf in cf_files:
            tp_fn = dir_script + "\\MetaTrader5_TMPL\\config_" + srv + "\\" + cf + ".tmpl"
            cf_fn = dir_script + "\\MetaTrader5_TMPL\\config_" + srv + "\\" + cf + "_" + name_user + "@" + name_host + ".json"
            if not os.path.exists( cf_fn ): 
                shutil.copy(tp_fn, cf_fn)
        # for cf in cf_files:
        
        #
        # create cf_accounts file if not exists
        #
        cf_accounts = {}
        tp_fn = dir_script + "\\MetaTrader5_TMPL\\config_" + srv + "\\cf_accounts.tmpl"
        cf_fn = dir_script + "\\MetaTrader5_TMPL\\config_" + srv + "\\cf_accounts_" + name_user + "@" + name_host + ".json"
        if not os.path.exists( cf_fn ): 
            with open( tp_fn, 'r') as f: cf_accounts = json.load(f)
            for account in cf_accounts:
                print( account, cf_accounts[account] )
            with open(cf_fn, 'w') as f: json.dump(cf_accounts, f, indent=4)
            print( tp_fn, cf_accounts )
        # if not os.path.exists( cf_fn ): 

        #
        # create mt5 env from existing or freshly created cf_accounts file
        #
        
        # create fuzzyalgo libs 
        #  e.g. create link from: 
        #   c:\OneDrive\rfx\git\fuzzyalgo\Lib\algotrader\
        #     to:
        #   c:\apps\anaconda3\envs\jupyter-env\Lib\site-packages\algotrader\ 
        fuzzyalgo_libs = ['algotrader', 'mplfinance']
        for lib in fuzzyalgo_libs:
            fuz_org_fn = dir_script + "\\Lib\\" + lib
            anaconda_fn = dir_py_lib + "\\site-packages\\" + lib 
            if os.path.exists( anaconda_fn ):
                # use os.rmdir here cause LINK is like empty dir
                os.rmdir( anaconda_fn )
            symlink( fuz_org_fn, anaconda_fn )
            
        # create cf_accounts file if not exists
        with open( cf_fn, 'r') as f: cf_accounts = json.load(f)

        # create MetaTrader5 python libraries
        mt5_org_fn = dir_py_lib + "\\site-packages\\MetaTrader5"
        if not os.path.exists( mt5_org_fn ):
            raise ValueError( "E: MetaTrader5 python library missing here: " + mt5_org_fn )
        for account in cf_accounts:
            mt5_acc_fn = dir_py_lib + "\\site-packages\\MetaTrader5_" + account
            shutil.copytree(mt5_org_fn, mt5_acc_fn, dirs_exist_ok=True)
            mt5_cac_fn = mt5_acc_fn + "\\__pycache__"
            if os.path.exists( mt5_cac_fn ):
                # https://www.geeksforgeeks.org/python-move-or-copy-files-and-directories/
                shutil.rmtree(mt5_cac_fn)      

        # unzipping mt5 exes
        # https://stackoverflow.com/questions/3451111/unzipping-files-in-python
        mt5_zipped_bins = ['terminal64', 'metaeditor64', 'metatester64']
        for mt5_bin in mt5_zipped_bins:
            mt5_bin_exe = dir_script + "\\MetaTrader5_TMPL\\" + mt5_bin + ".exe"
            mt5_bin_zip = dir_script + "\\MetaTrader5_TMPL\\" + mt5_bin + ".zip"
            mt5_zip_extract_dir = dir_script + "\\MetaTrader5_TMPL\\."
            if os.path.exists( mt5_bin_exe ):
                os.remove( mt5_bin_exe )
            shutil.unpack_archive(mt5_bin_zip, mt5_zip_extract_dir)

        # create Default profile in MetaTrader5_TMPL directory
        #  copy 
        #    MetaTrader5_TMPL/MQL5/Profiles/Charts/Latest ->
        #    MetaTrader5_TMPL/MQL5/Profiles/Charts/Default
        mt5_mql5_src_fn = dir_script + "\\MetaTrader5_TMPL\\MQL5\\Profiles\\Charts\\Latest"
        mt5_mql5_dst_fn = dir_script + "\\MetaTrader5_TMPL\\MQL5\\Profiles\\Charts\\Default"
        if os.path.exists( mt5_mql5_dst_fn ):
            shutil.rmtree(mt5_mql5_dst_fn)      
        shutil.copytree(mt5_mql5_src_fn, mt5_mql5_dst_fn, dirs_exist_ok=False)

        # create MetaTrader5 directories
        for account in cf_accounts:
            # TODO consolidate create CONFIG CLASS that reads path_mt5_bin and path_mt5_config
            path_mt5 = dir_appdata +  "\\MetaTrader5_" + account
            path_mt5_bin = path_mt5 + "\\terminal64.exe"
            #path_mt5_user =  os.getenv('USERNAME') + '@' + os.getenv('COMPUTERNAME')
            #path_mt5_config = path_mt5 + "\\config\\cf_accounts_" + path_mt5_user + ".json"
            path = path_mt5
            if os.path.exists( path ):
                shutil.rmtree(path)      
            mql5_path = path + "\\MQL5"
            os.makedirs( mql5_path )
            conf_path = path + "\\config"
            os.makedirs( conf_path )
            
            mt5_org_bins = ['terminal64.exe', 'metaeditor64.exe', 'metatester64.exe', 'Terminal.ico', 'uninstall.exe']
            for mt5_bin in mt5_org_bins:
                mt5_bin_src_fn = dir_script + "\\MetaTrader5_TMPL\\" + mt5_bin
                mt5_bin_dst_fn = path       + "\\" + mt5_bin
                shutil.copy( mt5_bin_src_fn, mt5_bin_dst_fn )

            # link servers.dat - main reason for existence of config_RoboForex-ECN directory
            #   if servers.dat is same for all mt5 servers like 'RoboForex-ECN'
            #   then there shall be one config dir only -> TODO consolidate
            mt5_cnf_src_fn = dir_script + "\\MetaTrader5_TMPL\\config_" + srv + "\\servers.dat"
            mt5_cnf_dst_fn = path       + "\\config\\servers.dat"
            symlink( mt5_cnf_src_fn, mt5_cnf_dst_fn )
            
            mt5_org_confs = ['cf_accounts', 'cf_periods', 'cf_symbols', 'cf_pid_params' ]
            for mt5_cnf in mt5_org_confs:
                mt5_cnf_src_fn = dir_script + "\\MetaTrader5_TMPL\\config_" + srv + "\\" + mt5_cnf + "_" + name_user + "@" + name_host + ".json"
                mt5_cnf_dst_fn = path       + "\\config\\"  + mt5_cnf + "_" + name_user + "@" + name_host + ".json"
                symlink( mt5_cnf_src_fn, mt5_cnf_dst_fn )
                
            mt5_org_MQL5s = ['Experts', 'Files', 'Images', 'Include', 'Indicators', 'Libraries', 'Presets', 'Profiles', 'Scripts']
            for mt5_mql5 in mt5_org_MQL5s:
                mt5_mql5_src_fn = dir_script + "\\MetaTrader5_TMPL\\MQL5\\" + mt5_mql5
                mt5_mql5_dst_fn = path       + "\\MQL5\\"  + mt5_mql5
                symlink( mt5_mql5_src_fn, mt5_mql5_dst_fn )
                
            mt5_org_MQL5s = ['Logs', 'Services', 'Shared Project']
            for mt5_mql5 in mt5_org_MQL5s:
                mt5_mql5_dst_fn = path       + "\\MQL5\\"  + mt5_mql5
                os.makedirs( mt5_mql5_dst_fn )

            mt5_mql5_src_fn = dir_script + "\\MetaTrader5_TMPL\\MQL5\\experts.dat"
            mt5_mql5_dst_fn = path       + "\\MQL5\\experts.dat"
            shutil.copy( mt5_mql5_src_fn, mt5_mql5_dst_fn )


        # copy MetaTrader5 binaries
        mt5_bin = []

        
    # for srv in supported_mt5_servers:
    
    """ symlink examples
    # symlink(source, link_name)

    tp_fn = dir_script + "\\MetaTrader5_TMPL\\config_" + srv + "\\cf_periods.tmpl"
    cf_fn = dir_script + "\\MetaTrader5_TMPL\\config_" + srv + "\\cf_periods_" + name_user + "@" + name_host + ".json"
    symlink( tp_fn, cf_fn )

    tp_fn = dir_script + "\\MetaTrader5_TMPL\\config_" + srv
    cf_fn = dir_script + "\\MetaTrader5_TMPL\\config_" + srv + "_link_" + name_user + "@" + name_host 
    symlink( tp_fn, cf_fn )
    
    # create a directory
    import os
    os.makedirs( "a\\b\\c" )
    
    # remove an not empty directory
    import shutil
    shutil.rmtree("a")
    
    # remove empty directory
    os.rmdir( "a" )
    
    # remove file
    os.remove( path_to_file )
    
    """

 
if __name__ == '__main__':
    setup()

