#!/usr/bin/env bash

$%trap SIGINT SIGTERM EXIT dostuff() {
    echo "Came out"
}
