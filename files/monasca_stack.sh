#!/bin/bash

MIRROR_FILE="/etc/monasca/monasca-persister-mirror.yml"
STORM_FILE="/opt/storm/current/conf/storm.yaml"
INFLUXDB_FILE="/etc/opt/influxdb/influxdb.conf"

#
# Get the list of monasca services in the order they should be
# started in.  Note that we intentionally don't stop/start
# verticad -- vertica doesn't like that.  Use adminTools
# for the entire cluster instead.
#
get_up_list() {

    if [ -e $INFLUXDB_FILE ]
    then
        echo "influxdb"
    fi

    echo "zookeeper kafka storm-supervisor"

    if grep nimbus.host $STORM_FILE | grep -e $(hostname) -e localhost > /dev/null
    then
        echo "storm-nimbus storm-ui monasca-thresh"
    fi

    if [ -e $MIRROR_FILE ]
    then
        echo "monasca-persister-mirror"
    fi

    echo "monasca-persister monasca-notification monasca-api"
}

#
# Get the list of monasca services in the order they should be
# stopped in.
#
get_down_list() {

    echo "monasca-api monasca-notification monasca-persister"

    if [ -e $MIRROR_FILE ]
    then
        echo "monasca-persister-mirror"
    fi

    if grep nimbus.host $STORM_FILE | grep -e $(hostname) -e localhost > /dev/null
    then
        echo "monasca-thresh storm-ui storm-nimbus"
    fi

    echo "storm-supervisor kafka zookeeper"

    if [ -e $INFLUXDB_FILE ]
    then
        echo "influxdb"
    fi
}

status() {
    for x in $(get_up_list)
    do
        service $x status
    done
}

start() {
    for x in $(get_up_list)
    do
        STATUS=$(service $x status 2>&1)
        #
        # Only start a service if it isn't currently running
        #
        if [ $? != 0 ] || [[ "$STATUS" == *"stop/waiting"* ]]
        then
            service $x start
            sleep 2
        fi
    done
}

stop() {
    for x in $(get_down_list)
    do
        service $x stop
        sleep 2
    done
}

tail_logs() {
    /usr/bin/tail -f /opt/storm/current/logs/*log \
                     /var/log/monasca/*log \
                     /var/log/influxdb/*log \
                     /opt/vertica/log/*log \
                     /var/log/kafka/*log \
                     /opt/kafka/logs/*log
}

tail_metrics() {
    /usr/bin/tail -f /tmp/kafka-logs/metr*/*log | /usr/bin/strings
}

lag() {
    #
    # Print the consumer lag -- ignore java log warnings
    #
    /opt/kafka/bin/kafka-run-class.sh  kafka.tools.ConsumerOffsetChecker \
                                       --zkconnect localhost:2181 \
                                       --topic metrics --group $1 2>&1 \
                                       | grep -v SLF4J
}

case "$1" in
  status)
    status
        ;;
  start)
    start
        ;;
  stop)
    stop
        ;;
  restart)
    stop
    sleep 2
    start
        ;;
  tail-logs)
    tail_logs
        ;;
  tail-metrics)
    tail_metrics
        ;;
  local-lag)
    lag '1_metrics'
        ;;
  mirror-lag)
    lag '2_metrics'
        ;;
  *)
        echo "Usage: "$1" {status|start|stop|restart|tail-logs|tail-metrics|local-lag|mirror-lag}"
        exit 1
esac
