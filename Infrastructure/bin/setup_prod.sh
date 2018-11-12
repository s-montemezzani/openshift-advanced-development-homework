#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Production Environment in project ${GUID}-parks-prod"

# Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Student

oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n $GUID-parks-prod
oc policy add-role-to-group system:image-puller system:serviceaccounts:$GUID-parks-prod -n $GUID-parks-dev

oc policy add-role-to-user view --serviceaccount=default -n $GUID-parks-dev

sed "s/%GUID%/$GUID/g" ../templates/guid-parks-prod/mongodb_prod.yaml | oc create -n $GUID-parks-prod -f -

sed "s/%GUID%/$GUID/g" ../templates/guid-parks-prod/3apps_prod_binary_builds.yaml | oc create -n $GUID-parks-prod -f -

oc expose svc/mlbparks-green --name mlbparks-route -n $GUID-parks-prod
oc expose svc/nationalparks-green --name nationalparks-route -n $GUID-parks-prod
