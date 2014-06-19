#!/bin/bash

nova quota-class-update --instances 5 default
nova quota-class-update --ram 16384 default
nova quota-class-update --cores 8 default
nova quota-class-show default
