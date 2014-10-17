Foreverybody
============
# Forever for Everybody

Central script for daemonize run forever/node.js processes under specific accounts

init.d script /etc/init.d/foreverybody

common server configuration file /etc/foreverybody/processes


## Features

* each daemonized process can run under specific account
* common logs directory
* common pid files
* list for each users
* DEV settings for processes in active development
* process with specific names
* node.js servers can be managed separately

## Configuration in  /etc/foreverybody/processes

### short version:
processname path script
```
mynodeserver /path/to/nodescript nodescript.js
```
### extended version:
processname path script port daemonuser dev
```
mynodeserver /path/to/nodescript nodescript.js 12345 nodedaemonuser DEV
```
for skipping port in extended parameters, set it to 0

last opitonal parameter has only value "DEV" - this process will monitor filechanges for restarting and print extended logs

##Commands
```
sudo /etc/init.d/foreverybody.sh start | stop | restart | list(status)
```

### Commands for specific process
```
sudo /etc/init.d/foreverybody.sh start|stop|restart PROCESSNAME
```

foreverybody.sh runs commands as DOMAINUSER

default or configured, use it as root with sudo

# init.d/foreverybody.sh configuration

```
LOGPATH=/var/log/node
PIDPATH=/var/run/node
MIN_UPTIME=1000
SPIN_SLEEP_TIME=2000
DEFAULT_DAEMON_USER=forever
INPATH=$PATH
```

