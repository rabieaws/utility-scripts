#!/bin/bash

# Get a list of all stack names
stacks=$(aws cloudformation describe-stacks --query "Stacks[*].StackName" --output text)

echo "Checking stacks for resources..."

# Loop through each stack name
for stack in $stacks; do
    # Get the number of resources in the stack
    resource_count=$(aws cloudformation list-stack-resources --stack-name "$stack" --query "length(StackResourceSummaries)")

    # If the stack has no resources, print its name
    if [ "$resource_count" -eq 0 ]; then
        echo "Stack with no resources: $stack"
    fi
done
