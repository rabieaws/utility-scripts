#!/bin/bash

# Create CSV file and needed headers
echo "Username, DisplayName, Email, GroupName" > output.csv

account_id=$(aws sts get-caller-identity --query Account --output text)
instance_id=$(aws sso-admin list-instances --output text --query 'Instances[0].InstanceArn')
identity_id=$(aws sso-admin list-instances --output text --query 'Instances[0].IdentityStoreId')

# List all users and iterate over them
users=$(aws identitystore list-users --identity-store-id "$identity_id" | jq -r '.Users? | select(.!=null)[] .UserId')
echo "$users" | while read -r userid; do
    # Get needed user info
    user_desc=$(aws identitystore describe-user --identity-store-id "$identity_id" --user-id "$userid")
    username=$(echo "$user_desc" | jq -r '.UserName? // ""')
    userdisplayname=$(echo "$user_desc" | jq -r '.DisplayName? // ""')
    useremail=$(echo "$user_desc" | jq -r '.Emails? | select(.!=null)[] .Value // ""')

    # For each user, list all the groups
    group_ids=$(aws identitystore list-group-memberships-for-member --identity-store-id "$identity_id" --member-id UserId="$userid" | jq -r '.GroupMemberships? | select(.!=null)[] .GroupId')

    # Check if the user has any group memberships
    if [[ -z "$group_ids" ]]; then
        echo "$username,$userdisplayname,$useremail," >> output.csv
    else
        # If the user has group memberships, iterate over the groups and write to CSV
        echo "$group_ids" | while read -r groupid; do
            # Get group info
            group_desc=$(aws identitystore describe-group --identity-store-id "$identity_id" --group-id "$groupid")
            groupdisplayname=$(echo "$group_desc" | jq -r '.DisplayName? // ""')
            # Write to the CSV file
            echo "$username,$userdisplayname,$useremail,$groupdisplayname" >> output.csv 
        done
    fi
done
