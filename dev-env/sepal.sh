#!/bin/bash
set -e 

SEPAL_CONFIG=/etc/sepal/module.d
SEPAL=/usr/local/lib/sepal
SEPAL_MODULES=(user sepal-server api-gateway task gee gui ceo mongo)
SEPAL_GROUPS=(all dev test)
SEPAL_DEFAULT_GROUP=dev
LOG_DIR=/var/log/sepal

is_module () {
    local NAME=$1
    printf '%s\n' ${SEPAL_MODULES[@]} | grep -qP "^$NAME$"
}

is_group () {
    local NAME=$1
    printf '%s\n' ${SEPAL_GROUPS[@]} | grep -qP "^$NAME$"
}

group () {
    local GROUP=$1
    case $GROUP in
    all)
        echo "${SEPAL_MODULES[@]}"
        ;;
    dev)
        echo "user sepal-server ( -DskipSceneMetaDataUpdate ) api-gateway task gee gui ceo mongo"
        ;;
    test)
        echo "user gee"
        ;;
    *)
        return 1
        ;;
    esac
}

pidof () {
    local MODULE=$1
    # ps -ef | grep bash | egrep "sepal run ${MODULE}[$\s]" | awk '{ print $2 }'
    ps -ef | grep bash | grep "sepal run ${MODULE}" | awk '{ print $2 }'
}

is_running () {
    local MODULE=$1
    local PID=$(pidof ${MODULE})
    [ ! -z "$PID" ]
}

logfile () {
    local MODULE=$1
    echo "$LOG_DIR/$MODULE.log"
}

message () {
    local MESSAGE=$1
    local MODULE=$2
    local COLOR_NAME=$3
    local NO_COLOR='\033[0m'
    case "$COLOR_NAME" in
    RED)
        COLOR='\033[0;31m'
        ;;
    LIGHT_RED)
        COLOR='\033[1;31m'
        ;;
    GREEN)
        COLOR='\033[0;32m'
        ;;
    LIGHT_GREEN)
        COLOR='\033[1;32m'
        ;;
    YELLOW)
        COLOR='\033[0;33m'
        ;;
    *)
        COLOR=$NO_COLOR # No Color
        ;;
    esac
    printf "${COLOR}%10s${NO_COLOR} ${MODULE}\n" "${MESSAGE}"
}

module_status () {
    local MODULE=$1    
    if is_running $MODULE; then
        message "STARTED" $MODULE GREEN
    else
        message "STOPPED" $MODULE RED
    fi
}

module_start () {
    local MODULE=$1
    shift
    local ARGS=$@
    local PID=$(pidof ${MODULE})
    if [[ -z "$PID" ]]; then
        local LOG=$(logfile $MODULE)
        message "STARTING" "$MODULE $ARGS" LIGHT_GREEN
        setsid nohup /bin/bash $0 run $MODULE $ARGS >$LOG 2>&1 &
    else
        message "STARTED" $MODULE GREEN
    fi
}

group_processes_terminated () {
    local PID=$1
    local TIMEOUT=10
    until [[ -z "$(pgrep -g $PID)" || "$((TIMEOUT--))" -eq 0 ]] ; do
        sleep 1
    done
    [[ -z "$(pgrep -g $PID)" ]]
}

module_stop () {
    local MODULE=$1    
    local PID=$(pidof $MODULE)
    if [[ -z "$PID" ]]; then
        message "STOPPED" $MODULE RED
    else
        message "STOPPING" $MODULE LIGHT_RED
        pkill -TERM -g $PID
        group_processes_terminated $PID || pkill -KILL -g $PID
    fi
}

module_kill () {
    local MODULE=$1    
    local PID=$(pidof $MODULE)
    if [[ -z "$PID" ]]; then
        message "STOPPED" $MODULE RED
    else
        message "KILLING" $MODULE LIGHT_RED
        pkill -KILL -g $PID
    fi
}

module_log () {
    local MODULE=$1
    less -r +F $(logfile $MODULE)
}

module_clean () {
    local MODULE=$1
    message "CLEANING" $MODULE YELLOW
    case $MODULE in
    api-gateway)
        $SEPAL/gradlew \
        -p $SEPAL \
        --no-daemon \
        :sepal-api-gateway:clean &>/dev/null
        ;;
    mongo)
        ;;
    ceo)
        ;;
    gee)
        cd $SEPAL/lib/js/shared
        rm -rf node_modules package-lock.json
        cd $SEPAL/modules/gee/docker
        rm -rf node_modules package-lock.json
        ;;
    gui)
        cd $SEPAL/modules/gui/frontend
        rm -rf node_modules package-lock.json
        ;;
    sepal-server)
        $SEPAL/gradlew \
        -p $SEPAL \
        --no-daemon \
        :sepal-server:clean &>/dev/null
        ;;
    task)
        cd $SEPAL/lib/js/shared
        rm -rf node_modules package-lock.json
        cd $SEPAL/modules/task/docker
        rm -rf node_modules package-lock.json
        ;;
    user)
        $SEPAL/gradlew \
        -p $SEPAL \
        --no-daemon \
        :sepal-user:clean &>/dev/null
        ;;
    *)
        return 1
        ;;
    esac
}

do_with_modules () {
    local COMMANDS=$1
    shift
    local NAMES=$@

    local ARGS_START="("
    local ARGS_STOP=")"
    local CURRENT_NAME
    local IS_ARG=false
    local ARGS

    NAMES+=" -"
    for NAME in $NAMES; do
        if [[ $NAME == $ARGS_START ]]; then 
            IS_ARG=true
        elif [[ $NAME == $ARGS_STOP ]]; then
            IS_ARG=false
        else
            if ($IS_ARG); then
                ARGS+=($NAME)
            else
                if [[ $NAME != $CURRENT_NAME ]]; then
                    if [[ $CURRENT_NAME != "" ]]; then
                        if is_group $CURRENT_NAME; then
                            local GROUP=$CURRENT_NAME
                            local MODULES="$(group $GROUP)"
                            do_with_modules "$COMMANDS" $MODULES
                        elif is_module $CURRENT_NAME; then
                            local MODULE=$CURRENT_NAME
                            for COMMAND in $COMMANDS; do
                                $COMMAND $MODULE "${ARGS[@]}"
                            done
                        else
                            message "IGNORED" $NAME YELLOW
                        fi
                    fi
                    CURRENT_NAME=$NAME
                    ARGS=()
                fi
            fi
        fi
    done
}

status () {
    do_with_modules "module_status" ${@:-all}
}

start () {
    do_with_modules "module_start" ${@:-$SEPAL_DEFAULT_GROUP}
}

stop () {
    do_with_modules "module_stop" ${@:-all}
}

force_stop () {
    do_with_modules "module_kill" ${@:-all}
}

restart () {
    do_with_modules "module_stop" ${@:-all}
    do_with_modules "module_start" ${@:-SEPAL_DEFAULT_GROUP}
}

clean () {
  do_with_modules "module_stop" ${@:-all}
  do_with_modules "module_clean" ${@:-all}
}

build () {
    stop
    $SEPAL/gradlew build -x test -x :sepal-gui:build -p $SEPAL
}

build-debug () {
    stop
    $SEPAL/gradlew build -x test -x :sepal-gui:build -p $SEPAL --stacktrace --debug
}

log() {
    local MODULE=$1
    do_with_modules "module_log" $MODULE 
}

startlog () {
    local MODULE=$1
    do_with_modules "module_start module_log" $MODULE 
}

restartlog () {
    local MODULE=$1
    do_with_modules "module_stop module_start module_log" $MODULE 
}

run () {
    local MODULE=$1
    shift
    local ARGS=$@
    case $MODULE in 
    api-gateway)
        $SEPAL/gradlew \
        -p $SEPAL \
        --no-daemon \
        --stacktrace \
        :sepal-api-gateway:runDev \
        -DconfigDir="$SEPAL_CONFIG/api-gateway" \
        $ARGS
        ;;
    mongo)
        mkdir -p /var/sepal/ceo/db
        mongod --dbpath /var/sepal/ceo/db
        ;;
    ceo)
        eval $(parse-yaml /etc/sepal/conf.d/secret.yml)
        export sepal_host="`dig +short myip.opendns.com @resolver1.opendns.com`:3000"
        export private_key_path=${HOME}/.ssh/google-earth-engine.key
        mkdir -p ${HOME}/.ssh/
        echo -e $google_earth_engine_private_key > $private_key_path
        pip3 install -r $SEPAL/modules/ceo/docker/requirements.txt
        sudo mkdir -p /data/cep
        sudo chmod a+rwx /data/cep
        cd $SEPAL/modules/ceo/docker/src/ceo/static
        yarn install
        gunicorn \
            --pythonpath $SEPAL/modules/ceo/docker/src/ceo \
            --bind 0.0.0.0:7766 \
            --workers 5 \
            --timeout 3600 \
            --threads 16 \
            --backlog 64 \
            --error-logfile - \
            --log-file - \
            --access-logfile - \
            --log-level debug \
            --capture-output "wsgi:build_app( \
                gmaps_api_key='$google_maps_api_key', \
                digital_globe_api_key='$digital_globe_api_key', \
                dgcs_connect_id='$digital_globe_connect_id', \
                planet_api_key='$planet_api_key', \
                sepal_host='${sepal_host:-localhost}', \
                ee_account='$google_earth_engine_account', \
                ee_key_path='$private_key_path')" \
            $ARGS
        ;;
    gee)
        cd $SEPAL/lib/js/shared
        npm install
        cd $SEPAL/modules/gee/docker
        npm install
        SEPAL_CONFIG=$SEPAL_CONFIG npm run dev
        ;;
    gui)
        cd $SEPAL/modules/gui/frontend
        npm install
        npm start
        ;;
    sepal-server)
        $SEPAL/gradlew \
        -p $SEPAL \
        --no-daemon \
        --stacktrace \
        :sepal-server:runDev \
        -DconfigDir="$SEPAL_CONFIG/sepal-server" \
        $ARGS
        ;;
    task)
        cd $SEPAL/lib/js/shared
        npm install
        cd $SEPAL/modules/task/docker
        npm i
        SEPAL_CONFIG=$SEPAL_CONFIG source ./dev.sh
        ;;
    user)
        $SEPAL/gradlew \
        -p $SEPAL \
        --no-daemon \
        --stacktrace \
        :sepal-user:runDev \
        -DconfigDir="$SEPAL_CONFIG/user" \
        $ARGS
        ;;
    *)
        return 1
        ;;
    esac
}

usage () {
    if [ ! -z "$1" ]; then
        echo ""
        echo "Error: $1"
    fi
    echo ""
    echo "Usage: $0 <command> [<arguments>]"
    echo ""
    echo "Commands:"
    echo "   build                        build SEPAL"
    echo "   build-debug                  build SEPAL w/debug enabled"
    echo "   clean       [<module>...]    clean module(s)/group(s)"
    echo "   status      [<module>...]    check module(s)/group(s)"
    echo "   start       [<module>...]    start module(s)/group(s)"
    echo "   stop        [<module>...]    stop module(s)/group(s)"
    echo "   restart     [<module>...]    restart module(s)/group(s)"
    echo "   run         <module>         run module interactively"
    echo "   log         <module>         show module log tail"
    echo "   startlog    <module>         start a module and show log tail"
    echo "   restartlog  <module>         restart a module and show log tail"
    echo ""
    echo "Definitions:"
    echo "   <module>: <module_name> [<module_args>]"
    echo "   <module_args>: ( <module_arg>... )"
    echo ""
    echo "Modules: ${SEPAL_MODULES[@]}"
    echo "Groups: ${SEPAL_GROUPS[@]}"
    echo ""
    exit 1
}

no_one_argument () {
    usage "Too many arguments"
}

[ -z "$1" ] && usage

case "$1" in
    clean)
        shift
        clean $@
        ;;
    build)
        shift
        build
        ;;
    build-debug)
        shift
        build-debug
        ;;
    status)
        shift
        status $@
        ;;
    start)
        shift
        start $@
        ;;
    restart)
        shift
        restart $@
        ;;
    stop)
        shift
        stop $@
        ;;
    run)
        shift
        run $@
        ;;
    log)
        shift
        if [[ $# -ne 1 ]]; then
            no_one_argument
        else
            log $1
        fi
        ;;
    startlog)
        shift
        if [[ $# -ne 1 ]]; then
            no_one_argument
        else
            startlog $1
        fi
        ;;
    restartlog)
        shift
        if [[ $# -ne 1 ]]; then
            no_one_argument
        else
            restartlog $1
        fi
        ;;
    *)
        usage
        ;;
esac
