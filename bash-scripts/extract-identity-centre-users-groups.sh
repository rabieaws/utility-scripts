#!/bin/bash

# Create CSV file and needed headers
echo "Username, DisplayName, Email, GroupName" > output.csv

account_id=""
instance_id=$(aws sso-admin list-instances --output text --query 'Instances[0].InstanceArn')
identity_id=$(aws sso-admin list-instances --output text --query 'Instances[0].IdentityStoreId')

# List all users and iterate over them
aws identitystore list-users --identity-store-id "$identity_id" | jq -r '.Users[].UserId' | while read -r userid; do
    # Get needed user info
    user_desc=$(aws identitystore describe-user --identity-store-id "$identity_id" --user-id "$userid")
    username=$(echo "$user_desc" | jq -r '.UserName')
    userdispalyname=$(echo "$user_desc" | jq -r '.DisplayName')
    useremail=$(echo "$user_desc" | jq -r '.Emails[].Value')
    #For each user, list all the groups
    aws identitystore list-group-memberships-for-member --identity-store-id "$identity_id" --member-id UserId="$userid" | jq -r '.GroupMemberships[].GroupId' | while read -r groupid; do
        # Get group info
        group_desc=$(aws identitystore describe-group --identity-store-id "$identity_id" --group-id "$groupid")
        groupdispalyname=$(echo "$group_desc" | jq -r '.DisplayName')
        # Write to the CSV file
        echo "$username,$userdispalyname,$useremail,$groupdispalyname" >> output.csv 
    done
done
