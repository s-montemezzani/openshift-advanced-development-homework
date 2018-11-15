#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Resetting Parks Production Environment in project ${GUID}-parks-prod to Green Services"

# Code to reset the parks production environment to make
# all the green services/routes active.
# This script will be called in the grading pipeline
# if the pipeline is executed without setting
# up the whole infrastructure to guarantee a Blue
# rollout followed by a Green rollout.

# To be Implemented by Student


#delete mlbparks, nationalparks services
#oc get svc existing_service returns 0. oc get svc NOT_existing_service returns 1

oc get svc mlbparks-green -n ${GUID}-parks-prod
if [[ "$?" == "0" ]]; then
oc delete svc mlbparks-green -n ${GUID}-parks-prod
fi
oc get svc mlbparks-blue -n ${GUID}-parks-prod
if [[ "$?" == "0" ]]; then
oc delete svc mlbparks-blue -n ${GUID}-parks-prod
fi

oc get svc nationalparks-green -n ${GUID}-parks-prod
if [[ "$?" == "0" ]]; then
oc delete svc nationalparks-green -n ${GUID}-parks-prod
fi
oc get svc nationalparks-blue -n ${GUID}-parks-prod
if [[ "$?" == "0" ]]; then
oc delete svc nationalparks-blue -n ${GUID}-parks-prod
fi

#patch route parksmap to point to "placeholder". returns 1 if it already pointed to placeholder
if [[ "$(oc get route parksmap -n $GUID-parks-prod -o jsonpath='{ .spec.to.name }')" != "placeholder" ]]; then
oc patch route parksmap -n $GUID-parks-prod -p '{"spec":{"to":{"name":"placeholder"}}}'
fi
