#!/bin/bash

nova flavor-delete m1.tiny
nova flavor-create m1.tiny 1 1024 20 1
