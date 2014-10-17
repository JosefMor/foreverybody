#!/bin/bash

### BEGIN INIT INFO
# Provides:          foreverdaemon
# Default-Start:     2 3 4 5
# Required-Start:
# Required-Stop:
# Default-Stop:      0 1 6
# Short-Description: starts the forever daemon
# Description:       starts nodejs using nodejs forever
### END INIT INFO
LOGPATH=/var/log/node
PIDPATH=/var/run/node
MIN_UPTIME=1000
SPIN_SLEEP_TIME=2000
DEFAULT_DAEMON_USER=forever
INPATH=$PATH

fa=()

listnocontains() {
  for word in $1; do
    [[ $word = $2 ]] && return 1
  done
  return 0
}

while read line; do
    if [ -n "$line" ]; then
        if [[ $line != \#* ]]; then
        fa+=("$line");
    fi;
    fi;
done < /etc/foreverybody/processes

if [ -n "$2" ]; then ONLYPROC=$2; else unset ONLYPROC; fi;


case "$1" in
    start)
        echo  "Starting forever processes:"

       [ ! -d $PIDPATH ] && mkdir -m0777 $PIDPATH
       [ ! -d $LOGPATH ] && mkdir -m0777 $LOGPATH

        for line in "${fa[@]}"; do
            declare -a fargs=($line);
            PROCNAME=${fargs[0]};
	    # if process name is specified
	    if [ -n "$ONLYPROC" ]; then
	    	if [ "$ONLYPROC" != "$PROCNAME" ]; then
	             continue;
                fi;
            fi;
            PIDFILE=$PIDPATH/$PROCNAME".pid";
            LOGFILE=$LOGPATH/$PROCNAME".log";
            ERRORLOGFILE=$LOGPATH/"error-"$PROCNAME".log";
            APPLICATION_PATH=${fargs[1]};
            APPLICATION_EXE=${fargs[2]};
            PATH=$APPLICATION_PATH:$NODE_BIN_DIR:$INPATH

	    if [ -n "${fargs[3]}" ]; then
            	if (( ${fargs[3]} \> 1024 )); then
            		PORT=${fargs[3]};
			export PORT=$PORT;
		else
			unset PORT;
		fi;
	    else
		unset PORT;
	    fi;

	    DAEMONUSER=$DEFAULT_DAEMON_USER

            if [[ ${fargs[4]}  ]]; then
                DAEMONUSER=${fargs[4]}
            fi

            DEVPAR="";


            if [[ ${fargs[5]} == "DEV" ]]; then
                #DEVPAR=" -d -v -w --watchDirectory=$APPLICATION_PATH -o $LOGPATH/debug-$PROCNAME.log";
                DEVPAR=" -d -v -w --watchDirectory=$APPLICATION_PATH";
            fi

	    if [ -d "$APPLICATION_PATH" ]; then
		if [ -f "$APPLICATION_PATH/$APPLICATION_EXE" ]; then
			if [ -f "$APPLICATION_PATH/.foreverignore" ]; then
				#su $DAEMONUSER -c "echo " " >> $APPLICATION_PATH/.foreverignore";
				echo " " >> $APPLICATION_PATH/.foreverignore;
			fi;
      			ifsv=`su $DAEMONUSER -c "forever list | grep $PROCNAME | tr -d ' '"`;

			if [   ${#ifsv} == 0  ]; then
      			su $DAEMONUSER -c "

				cd $APPLICATION_PATH;
      				forever \
      				--pidFile $PIDFILE \
      				--uid $PROCNAME \
      				-a \
      				-l $LOGFILE \
      				-e $ERRORLOGFILE \
      				--minUptime $MIN_UPTIME \
      				--spinSleepTime $SPIN_SLEEP_TIME $DEVPAR \
      				start $APPLICATION_PATH/$APPLICATION_EXE;
			";
			else
				echo "$PROCNAME is alerady runing, not started"
			fi;

		else
		     echo "file $APPLICATION_PATH/$APPLICATION_EXE does not exits";
		fi;
		else
		     echo "directory $APPLICATION_PATH does not exits";
	     fi;

      done;
        # su forever -c "forever list";
        ;;
    stop)
        echo -n "Stopping forever: "
        for line in "${fa[@]}"; do
            declare -a fargs=($line);

            PROCNAME=${fargs[0]};

	    DAEMONUSER=$DEFAULT_DAEMON_USER

            if [[ ${fargs[4]}  ]]; then
                DAEMONUSER=${fargs[4]}
            fi

	    # if process name is specified
	    if [ -n "$ONLYPROC" ]; then
	    	if [ "$ONLYPROC" != "$PROCNAME" ]; then
	             continue;
                fi;
            fi;
            su $DAEMONUSER -c "forever stop $PROCNAME";
            echo "Stopped: " $PROCNAME;
        done;
        # su forever -c "forever list";
        ;;
    restart|force-reload)
        $0 stop $2
        sleep 3
        $0 start $2
        ;;
    status|list)

	daemonusers="forever "
	declare -A defprocs
        for line in "${fa[@]}"; do
	    foruser=$DEFAULT_DAEMON_USER
            declare -a fargs=($line);

            if [[ ${fargs[4]}  ]]; then
		foruser=${fargs[4]}
		if listnocontains "$daemonusers" ${fargs[4]}; then daemonusers="$daemonusers ${fargs[4]}"; fi;
            fi
	    defprocs[${foruser}]="${defprocs[$foruser]} ${fargs[0]}"

	done;

 	for daemonuser in $daemonusers; do
   		echo "daemonuser: $daemonuser";
		echo "configured processes:";
		echo ${defprocs[${daemonuser}]};
        	su $daemonuser -c "forever list";
		echo "=========================================================";
  	done

        ;;
     *)
        echo "Usage:  {start|stop|status|restart}"
        exit 1
        ;;
esac

exit 0
