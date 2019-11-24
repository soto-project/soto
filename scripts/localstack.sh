#!/bin/sh

CONTAINER_ID=$(docker container ls | grep localstack/localstack | awk {'print $1'})
COMMAND=$1

usage()
{
    echo "Usage: localstack.sh [start] [stop] [status]"
    exit 2
}

get_container_id()
{
    return docker container ls | grep localstack/localstack | awk {'print $1'}
}

start()
{
    if [ -z "$CONTAINER_ID" ]; then
        docker run -d -p 4567-4597:4567-4597 -e SERVICES='apigateway,dynamodb,iam,s3,sns,sqs,ssm' localstack/localstack
    else
        echo "Localstack is already running"
    fi
}

stop()
{
    if [ -n "$CONTAINER_ID" ]; then
        echo "Stopping localstack"
        docker container stop "$CONTAINER_ID"
        docker rm "$CONTAINER_ID"
    else
        echo "Localstack is already stopped"
    fi
}

status()
{
    if [ -n "$CONTAINER_ID" ]; then
        echo "Local stack is running"
    else
        echo "Local stack is not running"
    fi
}

if [ "$COMMAND" == "start" ]; then
    start
elif [ "$COMMAND" == "stop" ]; then
    stop
elif [ "$COMMAND" == "status" ]; then
    status
else
    usage
    exit -1
fi

