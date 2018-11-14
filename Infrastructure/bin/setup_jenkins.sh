#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student


: <<'COMMENT_DELIMITER'
###reference only, sometimes towards the end some things were changed directly in the .yaml file


########################## start jenkins persistent
#oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi
oc process -f ./Infrastructure/templates/guid-jenkins/jenkins-persistent/jenkins-persistent-template.yaml --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi --param CPU_LIMIT=2000m | oc create -n $GUID-jenkins -f -
########################## end jenkins persistent

########################## start maven slave pod with skopeo
#we probably cannot switch to root user => cannot use these commands
docker build ./Infrastructure/templates/docker___jenkins_slave_pod \
-t docker-registry-default.apps.$GUID.example.opentlc.com/xyz-jenkins/jenkins-slave-maven-appdev:v3.9

cat ./Infrastructure/templates/guid-jenkins/docker___jenkins_slave_pod/Dockerfile | oc new-build --name=jenkins-slave-appdev -n $GUID-jenkins -D -
oc export bc,is -l build=jenkins-slave-appdev > jenkins_slave_pod.yaml

sed "s/%GUID%/$GUID/g" ./Infrastructure/templates/guid-jenkins/jenkins_slave_pod/jenkins_slave_pod.yaml | oc create -n $GUID-jenkins -f -

#build already started with above oc create
oc start-build bc/jenkins-slave-appdev
########################## end maven slave pod with skopeo



########################## start build for each microservice
#MLBParks
oc new-build --name=mlbparks-pipeline $REPO --context-dir=MLBParks -n $GUID-jenkins
#NationalParks
oc new-build --name=nationalparks-pipeline $REPO --context-dir=Nationalparks -n $GUID-jenkins
#ParksMap
oc new-build --name=parksmap-pipeline $REPO --context-dir=ParksMap -n $GUID-jenkins

#########start environment variables
oc set env bc/mlbparks-pipeline GUID=$GUID CLUSTER=$CLUSTER REPO=$REPO -n $GUID-jenkins
oc set env bc/nationalparks-pipeline GUID=$GUID CLUSTER=$CLUSTER REPO=$REPO -n $GUID-jenkins
oc set env bc/parksmap-pipeline GUID=$GUID CLUSTER=$CLUSTER REPO=$REPO -n $GUID-jenkins
#########END environment variables

#remove the skopeo bc before running this
oc export bc > 3apps_buildconfig_jenkins_pipeline.yaml


############################end build for each microservice





COMMENT_DELIMITER

oc process -f ./Infrastructure/templates/guid-jenkins/jenkins-persistent/jenkins-persistent-template.yaml --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi --param CPU_LIMIT=2000m | oc create -n $GUID-jenkins -f -

sed "s/%GUID%/$GUID/g" ./Infrastructure/templates/guid-jenkins/jenkins_slave_pod/jenkins_slave_pod.yaml | oc create -n $GUID-jenkins -f -

sed "s/%GUID%/$GUID/g;s/%CLUSTER%/$CLUSTER/g;s~%REPO%~$REPO~g" ./Infrastructure/templates/guid-jenkins/3apps_buildconfig_jenkins_pipeline.yaml | oc create -n $GUID-jenkins -f -
