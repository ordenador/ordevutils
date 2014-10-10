#!/usr/local/bin/python
# -*- coding: utf-8 -*-
import os
import stat
import subprocess
import sys, getopt
import urllib
import errno
import socket
import datetime
import crypt
import pwd
import time
try:
    from hashlib import md5
except ImportError:
    from md5 import md5
from sys import argv
from sys import stdout, stdin
from subprocess import Popen, call, PIPE
from signal import SIGINT, SIGTERM
import optparse 
from stat import ST_MODE

##############################
########   VERSION    ########
##############################
program_version="%prog 1.0.17"
##############################

## Paquetes HDLM
RPMS_HDLM = ['libstdc++.i686']

RPMS = ['rpm-yum-repo', 'lshw', 'apr-devel', 'apr-devel', 'apr-util-devel', 'keyutils', 'lsscsi', 'subversion-devel']
RPMS += ['openmotif', 'sysstat']
## Paquetes Common
RPMS += ['sistbin', 'nagios-scripts', 'osutils']
## Paquetes Post Discos Storage
RPMS += ['ctm64-cl', 'nmon']

RPMS_NOT = ['bluez-utils', 'bluez-gnome', 'bluez-hcldump ']
##RPM Dudosos si agregarlos a la lista o no: 'wireless-tools'

###########################
# LIST DIR LINK MOUNT FILE#
###########################

DIR_PDB = ['/u01/home','/u01/home/apli','/u81/home/adms','/u81/home/oper','/u81/home/sist','/u81/home/dba']
LINK_PDB = ['/u01/home/adms','/u01/home/dba','/u01/home/oper','/u01/home/sist']
DIR_TDB = ['/u01/home','/u01/home/adms','/u01/home/oper','/u01/home/sist','/u01/home/dba','/u01/home/apli']
DIR_APP = ['/u01/home','/u01/home/adms','/u01/home/oper','/u01/home/sist','/u01/home/dba','/u01/home/sweb','/u01/home/apli','/u01/home/www']

MOUNT_PDB = ['/u01','/u03','/u80','/u81']
MOUNT_TDB = ['/u01','/u03','/u80']
MOUNT_APP = ['/u01']

FILE_DB = ['/usr/local/bin/asmcheck.pl']
FILE_APP = []

###########################
# PERL MODULES            #
###########################

PERL_MODULES = ['DBI']

####################
# LIST NO SERVICES #
####################

NOSERVICES = ['acpid','avahi-daemon','apmd','autofs','bluetooth','cups','gpm','identd','lpd','netfs','nfs','nfslock','portmap','radvd','rawdevices']
NOSERVICES += ['rhnsd','sendmail','snmpd','snmptrapd','smartd','xfs','xinetd','yppasswdd','ypserv','ypxfrd','httpd','smartd','yum-updatesd']
NOSERVICES += ['NetworkManager', 'iptables', 'ip6tables']

####################
# GLOBAL VARIABLES #
####################

VERBOSE = False
ANO = datetime.datetime.now().strftime("%Y")

EXECAS_FILE = "/usr/local/etc/execas.dat"

# SSH KEYS
ORACLE_AUTHORIZED_FILE = '/u01/home/app/oracle/.ssh/authorized_keys'
ORACLE_AUTHORIZED_MD5SUM = '82ee3bdc5d9cb0792a15a0bc28a8a07f'
ADMBD_AUTHORIZED_FILE = '/u01/home/dba/admbd/.ssh/authorized_keys'
ADMBD_AUTHORIZED_MD5SUM = '968e9e42ba212736abbed11ea90d0a08'
ROOT_AUTHORIZED_FILE = '/root/.ssh/authorized_keys'
ROOT_AUTHORIZED_MD5SUM = 'f61441c8c504e21ed7fa2f9685c1bc85'

# Console colors
W  = '\033[0m'  # white (normal)
R  = '\033[31m' # red
G  = '\033[32m' # green
O  = '\033[33m' # orange
B  = '\033[34m' # blue
P  = '\033[35m' # purple
C  = '\033[36m' # cyan
GR = '\033[37m' # gray

# Create temporary directory to work in
from tempfile import mkdtemp
temp = mkdtemp(prefix='postinstall')
if not temp.endswith(os.sep):
    temp += os.sep

# /dev/null, send output from programs so they don't print to screen.
DN = open(os.devnull, 'w')

REMOTE_SERVER   = "10.1.1.249"
REMOTE_PATCH    = ""

OS_NAME = ""
OS_VERSION = ""
IP = ""
HOSTNAME = ""
TYPE = ""
e = False

####################
# UTILS FUNCTIONS  #
####################

def exit_gracefully(code=0):
    """
        We may exit the program at any time.
        We want to remove the temp folder and any files contained within it.
        Removes the temp files/folder and exists with error code "code".
    """
    global e
    # Remove temp files and folder
    if os.path.exists(temp):
        for file in os.listdir(temp):
            os.remove(temp + file)
        os.rmdir(temp)
    # Disable monitor mode if enabled by us
    if code == 2:
        print R+" ["+O+"!"+R+"]"+O+" OS not supported"+W
        sys.exit(code)    
    if code == 1 or e == True:
        print R+" ["+O+"!"+R+"]"+O+" Cueck!! FIX ERROR"+W
    else:
        print G+" [+]"+W+" Exelent!!! ALL OK"
    sys.exit(code)


def program_exists(program):
    """
        Uses 'which' (linux command) to check if a program is installed.
    """
    proc = Popen(['which', program], stdout=PIPE, stderr=PIPE)
    txt = proc.communicate()
    if txt[0].strip() == '' and txt[1].strip() == '':
        return False
    if txt[0].strip() != '' and txt[1].strip() == '':
        return True
    return not (txt[1].strip() == '' or txt[1].find('no %s in' % program) != -1)


def log_ok(textvar, var, mesagge='',):
    global VERBOSE
    ## Acortar largo de textvar y var
    if len(var) > 20:
        var = var[0:17]+'...'
    if len(textvar) > 14:
        textvar = textvar[0:11]+'...'
    if VERBOSE == True:
        print G+" [+] "+W+textvar.ljust(14)+": "+C+var.ljust(20)+G+" ["+W+mesagge+G+"]"+W

def log_error(textvar, var, mesagge=''):
    global e
    ## Acortar largo de textvar y var
    if len(var) > 20:
        var = var[0:17]+'...'
    if len(textvar) > 14:
        textvar = textvar[0:11]+'...'
    e = True
    print R+" ["+O+"!"+R+"] "+O+textvar.ljust(14)+": "+C+var.ljust(20)+R+" ["+O+mesagge+R+"]"+W


def findstr_in_file(text, file):
    ##cambiar a tue false
    try:
        f = open(file, "r")
    except Exception, e:
        raise e
    match = 0
    for line in f:
        if line.find(text) >= 0:
            match += 1
    f.close()
    return(match)


def run(command):
    '''takes a string command and hands back a subprocess object'''
    process = subprocess.Popen(command.split(), shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    process.wait()
    return process

def run_noBuffer(command):
    '''takes a string command and hands back a subprocess object'''
    process = subprocess.Popen(command.split(), shell=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, err = process.communicate()
    return output, err

def md5sum(file):
    m = md5()
    try:
        #open and read buffer
        f = open(file, "r").read(8096)
        m.update(f)
        return m.hexdigest()
    except:
        return 0

####################
#  FUNCTIONS       #
####################

def inital_info():
    global OS_NAME, OS_VERSION
    if os.path.isfile('/etc/oracle-release'):
        OS_NAME="Oracle Linux"
    else:
        OS_NAME="Red Hat Linux"
    command = run('cat /etc/redhat-release')
    output, err = command.communicate()
    OS_VERSION = output.split()[6]
    if OS_VERSION in ['5.8','6.3']:
        log_ok("OS Version", OS_NAME + ' ' + OS_VERSION, "OK")
    else:
        log_error("OS Version", OS_NAME + ' ' + OS_VERSION, "postinstall funciona en RHEL 5.8+ o OL 5.8+")
        sys.exit(2) 

def check_network():
    """
        Check: ip - hostname - hosts - resolv
    """
    global IP, HOSTNAME, e
    try:
        IP = socket.gethostbyname(socket.gethostname())
    except:
        e = True
    if not IP:
        log_error("IP", "", "IP to resolve by hostname")
    elif IP == "127.0.0.1":
        log_error("IP", IP, "check host table")
    else:
        log_ok("IP", IP, "OK")

    HOSTNAME = socket.gethostname()
    ## Check hostname in /etc/hosts
    if HOSTNAME == "localhost" or "." in HOSTNAME or findstr_in_file("DNS", "/etc/sysconfig/network"):
        log_error("Hostname", HOSTNAME, "check hostname")
    else:
        log_ok("Hostname", HOSTNAME, "OK")

    ## check namesever 10.108.1.1
    if findstr_in_file("10.108.1.1", "/etc/resolv.conf"):
        log_ok("Resolv", "10.108.1.1", "OK")
    else:
        log_error("Resolv", "", "check /etc/resolv.conf")

    ## check namesever DNS.com
    if findstr_in_file("DNS.com", "/etc/resolv.conf"):
        log_ok("Resolv", "DNS.com", "OK")
    else:
        log_error("Resolv", "", "check /etc/resolv.conf")

    ## check namesever IPV6
    if findstr_in_file("NETWORKING_IPV6=no", "/etc/sysconfig/network"):
        log_ok("IPV6", "no", "OK")
    else:
        log_error("IPV6", "?", "revisar archivo /etc/sysconfig/network")

    ## check hostname vs dns
    try:
        if HOSTNAME == socket.gethostbyaddr(IP)[0]:
            log_ok("Hostname", "vs DNS", "OK")
        else:
            log_error("Hostname", "Hostname vs DNS", "check hostname and name resolv, in hosts table: first name is without domain")
    except:
        log_error("Hostname", "Hostname vs DNS", "check hosts table")

def check_rpm(rpms):
    """
        Installed rpms.
    """
    for rpm in rpms:
        command = run("rpm -q "+rpm)
        output, err = command.communicate()
        if not 'is not installed' in output:
            log_ok("RPM", rpm, "installed")
        else:
            log_error("RPM", rpm, "not installed")

def check_nrpm(rpms):
    """
        Installed rpms.
    """
    for rpm in rpms:
        command = run("rpm -q "+rpm)
        output, err = command.communicate()
        if 'is not installed' in output:
            log_ok("RPM", rpm, "Not Installed")
        else:
            log_error("RPM", rpm, "installed")

def check_perl():
    command = run("perl -v | grep '(v' | awk '{print $9}'")
    output, err = command.communicate()
    perl_version = output.split()[8]
    if '5.16' in perl_version:
        log_ok("Perl version", perl_version, "OK")
        command = run('perl -V:config_args')
        output, err = command.communicate()
        perl_args = output.split('=')[1].rstrip('\n')
        if 'Dusethreads' in perl_args:
            log_ok("Perl args", perl_args, "OK")
        else:
            log_error("Perl args", perl_args, "check perl args")
    else:
        log_error("Perl version", perl_version, "check perl version")

def check_perl_modules(perlModules):
    myFile = open('/tmp/modules_perl.pl', 'w')
    myFile.write('use ExtUtils::Installed;'+'\n')
    myFile.write('my ($inst) = ExtUtils::Installed->new();'+'\n')
    myFile.write('print $inst->modules();'+'\n')
    myFile.close()
    for perlModule in perlModules:
        command = run("perl /tmp/modules_perl.pl")
        output, err = command.communicate()
        if perlModule in output:
            log_ok("Perl Module", perlModule, "OK")
        else:
            log_error("Perl version", perlModule, "Not Installed")

def check_perl_archname():
    command = run("perl -V | grep archname")
    output, err = command.communicate()
    perl_archname = output.split('archname=')[1].split('\n')[0]
    if 'x86_64-linux-thread-multi' in perl_archname:
        log_ok("Perl Archname", perl_archname, "OK")
    else:
        log_error("Perl Archname", perl_archname, "Not Installed")

def check_selinux():
    command = run("/usr/sbin/sestatus")
    output, err = command.communicate()
    selinux = output.split()[2]
    if 'disabled' in selinux:
        log_ok("SELinux", selinux, "OK")
    else:
        log_error("SELinux", selinux, "check SELinux 'sestatus'")

def check_kdump():
    command = run("/etc/init.d/kdump status")
    output, err = command.communicate()
    kdump = output.split()[2]
    if 'not' in kdump:
        log_ok("Kdump", kdump, "OK")
    else:
        log_error("Kdump", kdump, "check service Kdump")

def check_ntp():
    command = run("/usr/sbin/ntpdate camry")
    output, err = command.communicate()
    if not err:
        log_ok("NTP camry Net", "Hora actualizada", "OK")
    else:
        log_error("NTP camry Net", "Error", "check puerto NTP a camry")

def check_zdump():
    global ANO
    output, err = run_noBuffer("zdump -v /etc/localtime")
    largoANO = len(output.split(str(ANO)))
    largo2100 = len(output.split("2100"))
    if largoANO == 9 and not largo2100 == 9:
        log_ok("zdump", "zdump", "OK")
    else:
        log_error("zdump", "Error", "Configurar Zona horaria")

def check_ksh():
    command = run("ls -l /bin/ksh")
    output, err = command.communicate()
    if '/bin/zsh' in output:
        log_ok("ksh", "-> /bin/zsh", "OK")
    else:
        log_error("ksh", "!-> /bin/zsh", "check symbolic link")

def check_shell_root():
    command = run("grep :root: /etc/passwd")
    output, err = command.communicate()
    userShell = output.split('\n')[0].split(':')[-1]
    if userShell == '/bin/ksh':
        log_ok("Shell root", "/bin/ksh", "OK")
    else:
        log_error("Shell root", "!/bin/ksh", "check shell of root")

def check_dir(dirs):
    """
        Check path (dir)
    """
    for dir in dirs:
        if os.path.isdir(dir):
            log_ok("Path is dir", dir, "OK")
        else:
            log_error("Path is dir", dir, "Check dir: "+dir)

def check_link(links):
    """
        Check path (link)
    """
    for link in links:
        if os.path.islink(link):
            log_ok("Path is link", link, "OK")
        else:
            log_error("Path is link", link, "Check link: "+link)

def check_mount(mounts):
    """
        Check path (mount)
    """
    for mount in mounts:
        if os.path.ismount(mount):
            log_ok("Path is mount", mount, "OK")
        else:
            log_error("Path is mount", mount, "Check mount: "+mount)

def check_file(files):
    """
        Check path (file)
    """
    for file in files:
        file_name = file.split('/')[-1]
        if os.path.isfile(file):
            log_ok('Exist file?', file_name, "OK")
        else:
            log_error('Exist file?', file_name, "Check file: "+file)

def check_profile():
    f = open('/etc/passwd', 'r')
    for line in f:
        if not line == '\n':
            s = line.split(':')
            ## if group: 1000, 1500, 4000, 3000, 14000
            if s[3] in ['1000','1500','4000','3000','14000']:
                userShell = s[6].split('\n')[0]
                userGroup = s[3]
                if userShell == '/bin/ksh' or userShell == '/bin/bash' and userGroup == '1500':
                    log_ok('User shell', s[0] + ' shell:' + s[6].split('\n')[0],'OK')
                else:
                    log_error('User shell', 'Shell ' + s[6].split('\n')[0], 'check shell: grep ' + s[0] + ' /etc/passwd')
                pathProfile = s[5]+'/.profile'
                if os.path.isfile(pathProfile):
                    st = os.stat(pathProfile)
                    uid = st.st_uid
                    gid = st.st_gid
                    if s[2] == str(uid) and s[3] == str(gid):
                        if  not findstr_in_file('/sist_bin/basico.prf', pathProfile) or not findstr_in_file('/sist_bin/oracle.prf', pathProfile) and s[3] == '14000':
                            log_error('User profile', 'Load .prf', 'check '+pathProfile)
                        else:
                            log_ok('User profile', s[0],'OK')
                    else:
                        log_error('User profile', 'Owner file', 'check '+pathProfile)
                else:
                    log_error('User profile', 'Not exists profile', 'check '+pathProfile)
    f.close()

def check_execas_db():
    if os.path.isfile(EXECAS_FILE):
        if  not findstr_in_file('asroot:su -:/bin:N:root::dba', EXECAS_FILE) or not findstr_in_file('asoracle:su - oracle:/bin:N:root::dba', EXECAS_FILE):
            log_error('Execas', 'asroot or asoracle','check '+EXECAS_FILE)
        else:
            log_ok('Execas', 'asroot or asoracle','OK')
    else:
        log_error('Execas', 'Not exists execas.dat', 'check '+EXECAS_FILE)

def check_file_md5sum(file_path, file_md5sum, file_msg):
    file_name = file_path.split('/')[-1]
    if os.path.isfile(file_path):
        if md5sum(file_path) == file_md5sum:
            log_ok(file_msg, file_name,'OK')
        else:
            log_error(file_msg, 'Wrong data', 'check '+file_path)
    else:
        log_error(file_msg, 'Not exists file: '+file_name, 'check '+file_path)

def check_ssh_dba():
    check_file_md5sum(ORACLE_AUTHORIZED_FILE, ORACLE_AUTHORIZED_MD5SUM, "Ssh Key oracle")
    check_file_md5sum(ADMBD_AUTHORIZED_FILE, ADMBD_AUTHORIZED_MD5SUM, "Ssh Key admbd")

def check_ssh_root():
    check_file_md5sum(ROOT_AUTHORIZED_FILE, ROOT_AUTHORIZED_MD5SUM, "Ssh Key root")

def check_ntp_rclocal():
    if not findstr_in_file('/usr/sbin/ntpdate camry', '/etc/rc.local') and not findstr_in_file('ntpdate camry', '/etc/rc.local'):
        log_error('NTP rc.local', 'NTP to camry','check /etc/rc.local')
    else:
        log_ok('NTP rc.local', 'NTP to camry','OK')

def check_ntp_cron():
    if os.path.isfile('/var/spool/cron/root'):
        if  not findstr_in_file('/usr/sbin/ntpdate camry', '/var/spool/cron/root'):
            log_error('NTP cron', 'no ntpdate camry in cron','check /var/spool/cron/root')
        else:
            log_ok('NTP cron', 'crontab','OK')
    else:
        log_error('NTP cron', 'Not exists root cron', 'check /var/spool/cron/root')

def check_fiber():
    command = run("lspci")
    output, err = command.communicate()
    if 'Fibre Channel' in output:
        check_file(['/root/rescan.sh'])
    if 'Fibre Channel: QLogic' in output:
        check_rpm(['scli'])
        check_file(['/root/ql-dynamic-tgt-lun-disc.sh'])

def check_noservices(services):
    """
        Check service disable
    """
    for service in services:
        ## Check chkconfig
        command = run('chkconfig --list '+service)
        output, err = command.communicate()
        if '0:off' in output and '1:off' in output and '2:off' in output and '3:off' in output and '4:off' in output and '5:off' in output and '6:off' in output:
            log_ok('service disable?', service, "Disabled in chkconfig")
        elif 'error reading information on service' in err and 'No such file or directory' in err:
            log_ok('service disable?', service, "Not exists with chkconfig")
        else:
            log_error('service disable?', service, "check service: chkconfig --list "+service)
        ## Check /etc/init.d/servicename
        if os.path.isfile('/etc/init.d/'+ service):
            command = run('/etc/init.d/'+ service + " status")
            output, err = command.communicate()
            status = command.wait()
            if status is not 0:
                log_ok('/etc/init.d/' + service, service, "Service " + service + "is stoped or not running")
            elif 'is stopped' in output or 'not running' in output:
                log_ok('/etc/init.d/' + service, service, "Service " + service + "is stoped or not running")
            else:
                ## services dont know real state
                if service in ['rawdevices', 'rhnsd']:
                    log_ok('/etc/init.d/' + service, service, "Service " + service + ": dont know real state")
                else:
                    log_error('service disable?', service, "check service: /etc/init.d/" + service + " status")
        else:
            log_ok('/etc/init.d/' + service, service, "Not exist service: " + service)

def check_passwd_root():
    command = run('grep root /etc/shadow')
    output, err = command.communicate()
    salt_and_hash = output.split(':')[1]
    if '$' in salt_and_hash:
        salt = salt_and_hash.split('$')[2]
    else:
        salt = salt_and_hash
    if OS_VERSION.split('.')[0] == '6':
        new_salt_and_hash = crypt.crypt('password','$6$%s' % salt)
    else:
    	new_salt_and_hash = crypt.crypt('password','$1$%s' % salt)
    if salt_and_hash == new_salt_and_hash:
        log_ok('Password', 'root', 'OK')
    else:
        log_error('Password', 'root', 'check password root')

def check_sysedge_up():
    command = run('ps -C sysedge')
    output, err = command.communicate()
    if 'sysedge' in output:
        log_ok('SysEdge', 'SysEdge runing', 'OK')
    else:
        log_error('SysEdge', 'SysEdge No runing', 'check SysEdge: ps -fea | grep sysedge')

def check_sysedge_location():
    if os.path.isfile('/etc/init.d/CA-SystemEDGE'):
        sysedgedir = ''
        sysedgeport = ''
        f = open('/etc/init.d/CA-SystemEDGE', 'r')
        for line in f:
            if not line == '\n':
                if 'SYSEDGEDIR=' in line:
                    sysedgedir = line.split('"')[1]
                if 'DEFAULT_PORT=' in line:
                    sysedgeport = line.split('"')[1]
        f.close()
        
        ## check port config
        if sysedgeport == '1691':
            log_ok('SysEdge', 'SysEdge port 1691', 'OK')
        else:
            log_error('SysEdge', 'SysEdge port 1691', 'check port in /etc/init.d/CA-SystemEDGE')

        ## path configs
        path1 = sysedgedir + '/config/sysedge.cf'
        path2 = sysedgedir + '/config/port' + sysedgeport + '/sysedge.cf'
        if os.path.isfile(path1):
            if "syslocation 'DEFAULT LOCATION'" not in open(path1, 'r').read():
                log_ok('SysEdge', 'Location Configure', 'OK')
            else:
                log_error('SysEdge', 'Location Configure', 'change ' + path1)
        else:
			log_error('SysEdge', 'No Config', 'check ' + path1)

        if os.path.isfile(path2):
            if "syslocation 'DEFAULT LOCATION'" not in open(path2, 'r').read():
                log_ok('SysEdge', 'Location Configure', 'OK')
            else:
                log_error('SysEdge', 'Location Configure', 'change ' + path2)
        else:
			log_error('SysEdge', 'No Config', 'check ' + path2)
    else:
        log_error('SysEdge', 'SysEdge not Installed', 'Please Install SysEdge')

# socket client
class Client( object ):
    rbufsize= -1
    wbufsize= 0
    def __init__( self, address=('10.1.1.249',443) ):
        self.server=socket.socket( socket.AF_INET, socket.SOCK_STREAM )
        self.server.settimeout(10)
        self.server.connect( address )
        self.rfile = self.server.makefile('rb', self.rbufsize)
        self.wfile = self.server.makefile('wb', self.wbufsize)
    def makeRequest( self, text ):
        """send a message and get a 1-line reply"""
        self.wfile.write( text + '\n' )
        data= self.rfile.read()
        self.server.close()
        return data

def check_users_update():
    global TYPE
    try:
        c = Client()
        response = c.makeRequest('users')
        users = repr(response).split('\'')[1].split('\\n')
        users_names_remote = []
        ## Buscar usuario faltanes
        for user in users:
            if ':' in user:
                name = user.split(':')[0]
                uid = user.split(':')[2]
                gid = user.split(':')[3]
                comment = user.split(':')[4]
                users_names_remote.append(name)
                groups = ['1000','4000','3000']
                if TYPE in ['APP']:
                    groups += ['1500']
                if gid in groups:
                    try:
                        pwd.getpwnam(name)
                        log_ok('Users list', 'User '+name+' exist', 'OK')
                    except:
                        log_error('Users list', 'User not exist', 'create user: '+name+' - '+comment)
        ## Buscar usuarios extras
        f = open('/etc/passwd', 'r')
        for line in f:
            if not line == '\n':
                s = line.split(':')
                ## if group: 1000, 1500, 4000, 3000
                if s[3] in ['1000','1500','4000','3000']:
                    user_name_local = s[0]
                    user_comment_local = s[4]
                    if not user_name_local in users_names_remote or TYPE in ['TDB','PDB'] and s[3] in ['1500']:
                        if user_comment_local == '':
                            log_error('Users list', 'Extra user', 'Delete User: '+user_name_local)
                        else:
                            log_error('Users list', 'Extra user', 'Delete User: '+user_name_local+' - '+ user_comment_local)
        f.close()
    except:
        log_error('Users list', 'Cannot update users list', 'check conection with server repolinux:443')

def check_users_dba():
    ## Buscar usuario faltanes dba
    names = ['oracle','admbd']
    for name in names :
        try:
            pwd.getpwnam(name)
            log_ok('Users list', 'User '+name+' exist', 'OK')
        except:
            log_error('Users list', 'User not exist', 'create user: '+name)

def check_chmod_user():
    f = open('/etc/passwd', 'r')
    for line in f:
        if not line == '\n':
            s = line.split(':')
            if s[3] in ['1000','1500','4000','3000','14000']:
                userShell = s[6].split('\n')[0]
                userId = s[2]
                userGroup = s[3]
                pathUser = s[5]
                if os.path.isdir(pathUser):
                    st = os.stat(pathUser)
                    uid = st.st_uid
                    gid = st.st_gid
                    if oct(stat.S_IMODE(st.st_mode)) == '0755':
                        log_ok('Permissions 755', pathUser, 'OK')
                    else:
                        log_error('Permissions 755', 'Permissions 755', 'check ' + pathUser)
                    if userId == str(uid) and userGroup == str(gid):
                        log_ok('Permissions Home Owner', s[0],'OK')
                    else:
                        log_error('Permissions Home Owner', 'Owner Path', 'check '+pathUser)
                else:
                    log_error('User Path', 'Not exists dir', 'check '+pathUser)
    f.close()

def check_java_version():
    command = run('java -version')
    output, err = command.communicate()
    if '1.6.0_43' in err:
        log_ok('Java', 'Version 1.6.0_43', 'OK')
    else:
        log_error('Java', 'Version 1.6.0_43', 'check: java -version')

def check_700():
    if oct(os.stat(sys.argv[0])[ST_MODE])[-3:] != '700':
        log_error('postinstall.py', 'Permissions not 700', 'chmod 700 postinstall.py')
        return True

def check_date_vs_hwclock():
    command = subprocess.Popen("hwclock --debug | grep Hw",shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, err = command.communicate()
    hwclock = output.split(':')[1].strip()
    date = time.strftime("%Y/%m/%d %H")
    if date == hwclock:
        log_ok('Date', 'hwclock vs date', 'OK')
    else:
        log_error('Date', 'hwclock not equal date', 'check date and hwclock')

def set_values():
    global RPMS_DB
    if OS_VERSION.split('.')[0] == '6':
        #OL6.X
        RPMS_DB = ['oracleasm-support', 'oracleasmlib', 'oracle-rdbms-server-11gR2-preinstall']
    else:
        #OL5.X
        RPMS_DB = ['oracleasmlib', 'oracle-validated', 'oracleasm-support', 'oracleasm-2.6.18-308.el5', 'kernel-uek-debug']

def check_postinstall_version():
    global program_version
    try:
        c = Client()
        response = c.makeRequest('version')
        version = repr(response).split('\'')[1]
        if version != program_version.split()[1]:
            log_error('postinstall.py', 'New Version '+version, 'Check last version of postinstall.py')
            return True
        else:
            log_ok('postinstall.py', 'Version '+program_version, 'OK')
    except:
        log_error('postinstall.py', 'Cannot check last version postinstall.py', 'check conection with server repolinux:443')


def check_network_usb0():
    command = subprocess.Popen("ifconfig | grep usb0",shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, err = command.communicate()
    if 'usb0' in output:
        log_error('Net usb0', 'Check device usb0', 'ifdown usb0')
    else:
        log_ok('Net usb0', 'Check device usb0', 'OK')
    if os.path.isfile('/etc/sysconfig/network-scripts/ifcfg-usb0'):
        f = open('/etc/sysconfig/network-scripts/ifcfg-usb0', 'r')
        for line in f:
            if not line == '\n':
                if 'ONBOOT' in line and 'yes' in line:
                    log_error('Net usb0', 'Check ONBOOT usb0', 'Configure ONBOOT=no')
                else:
                    log_ok('Net usb0', 'Check ONBOOT usb0', 'OK')
        f.close()

def check_password_sync():
    try:
        c = Client()
        HOSTNAME=socket.gethostname()
        response = c.makeRequest('password '+HOSTNAME)
        password_sync = repr(response).split('\'')[1]
        if HOSTNAME == password_sync:
            log_ok('Update password', 'chek list camry', 'OK')
        else:
            log_error('Update password', 'chek list camry', 'configure password in camry')
    except:
        log_error('postinstall.py', 'Cannot check last version postinstall.py', 'check conection with server repolinux:443')

#################

def principal():
    global TYPE
    if check_700():
        exit_gracefully(0)
    if check_postinstall_version():
        exit_gracefully(0)
    try:
        inital_info()
        set_values()
        check_network()
        check_ssh_root()
        check_ntp()
        check_ntp_rclocal()
        check_ntp_cron()
        check_zdump()
        check_date_vs_hwclock()
        check_perl()
        check_perl_modules(PERL_MODULES)
        check_perl_archname()
        check_selinux()
        check_kdump()
        check_ksh()
        check_shell_root()
        check_nrpm(RPMS_NOT)
        check_rpm(RPMS)
        if TYPE in ['PDB'] :
            check_rpm(RPMS_DB)
            check_mount(MOUNT_PDB)
            check_dir(DIR_PDB)
            check_link(LINK_PDB)
            check_execas_db()
            check_ssh_dba()
            check_file(FILE_DB)
            check_users_dba()
        elif TYPE in ['TDB'] :
            check_rpm(RPMS_DB)
            check_mount(MOUNT_TDB)
            check_dir(DIR_TDB)
            check_execas_db()
            check_ssh_dba()
            check_file(FILE_DB)
            check_users_dba()
        elif TYPE == 'APP':
            check_mount(MOUNT_APP)
            check_dir(DIR_APP)
        check_profile()
        check_fiber()
        check_noservices(NOSERVICES)
        check_passwd_root()
        check_sysedge_up()
        check_chmod_user()
        check_users_update()
        check_java_version()
        check_network_usb0()
        check_password_sync()
    except KeyboardInterrupt:
        print R+'\n (^C)'+O+' interrupted\n'+W
    except EOFError:
        print R+'\n (^D)'+O+' interrupted\n'+W
    exit_gracefully(0)


def usage():
    print ''
    print '  '+C+'APP'+W+' = '+O+'Aplication'+W
    print '  '+C+'PDB'+W+' = '+O+'Productive Data Base'+W
    print '  '+C+'TDB'+W+' = '+O+'Test Data Base'+W
    print ''

def main(argv):
    global TYPE, VERBOSE
    parser = optparse.OptionParser(usage="Usage: %prog -t (APP|TDB|PDB) [options]", version=program_version)
    parser.add_option('-t', '--type', help='select type (APP|TDB|PDB)', dest='type', type='choice', choices=['APP', 'TDB', 'PDB'])
    parser.add_option('-v', '--verbose', default=False, dest='verbose', action='store_true')

    (opts, args) = parser.parse_args()

    if opts.verbose:
        VERBOSE = True 

    if opts.type:
        TYPE = opts.type
        principal()
    else:
        parser.print_help()
        usage()
        sys.exit(-1)

if __name__ == "__main__":
   main(sys.argv[1:])
