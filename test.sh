#!/bin/bash

# Test script for my local machine...

cat ./test/out_cli_project.json | ./assets/out ./test/workspace/

mvn -f ./test/workspace/maven_project/pom.xml clean package
cat ./test/out_maven_project.json | ./assets/out ./test/workspace/