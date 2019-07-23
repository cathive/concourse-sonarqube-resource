#!/bin/bash

source assets/common.sh

project_status="test/mocks/qualitygates_project_status.json"
metadata=$(metadata_from_conditions $project_status)
echo $metadata

