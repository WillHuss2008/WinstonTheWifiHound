#!/bin/bash

interface=$1

sudo airodump-ng $interface -w /winston/kenel/airodump-ng --output-format csv
