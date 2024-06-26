#!/bin/bash

# Get a list of all stack names
stacks=$(aws cloudformation describe-stacks --query "Stacks[*].StackName" --output text)

echo "Checking stacks for resources and drift status..."

# Loop through each stack name
for stack in $stacks; do
    # Start drift detection
    drift_detection_id=$(aws cloudformation detect-stack-drift --stack-name "$stack" --query "StackDriftDetectionId" --output text)
   
    # Wait for drift detection to complete
    status="DETECTION_IN_PROGRESS"
    while [ "$status" == "DETECTION_IN_PROGRESS" ]; do
        status=$(aws cloudformation describe-stack-drift-detection-status --stack-drift-detection-id "$drift_detection_id" --query "DetectionStatus" --output text)
        sleep 5
    done

    # Get the drift status
    drift_status=$(aws cloudformation describe-stack-drift-detection-status --stack-drift-detection-id "$drift_detection_id" --query "StackDriftStatus" --output text)

    # Check for drift
    if [ "$drift_status" == "DRIFTED" ]; then
        echo "Stack with drifted resources: $stack"
    else
        # Get the number of resources in the stack
        resource_count=$(aws cloudformation list-stack-resources --stack-name "$stack" --query "length(StackResourceSummaries)")

        # If the stack has no resources, print its name
        if [ "$resource_count" -eq 0 ]; then
            echo "Stack with no resources: $stack"
        fi
    fi
done
