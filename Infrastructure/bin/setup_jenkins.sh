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




########################## start jenkins persistent
#oc new-app jenkins-persistent --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi
oc process -f ../templates/guid-jenkins/jenkins-persistent/jenkins-persistent-template.yaml --param ENABLE_OAUTH=true --param MEMORY_LIMIT=2Gi --param VOLUME_CAPACITY=4Gi --param CPU_LIMIT=2000m | oc create -n $GUID-jenkins -f -
########################## end jenkins persistent

########################## start maven slave pod with skopeo
#we probably cannot switch to root user => cannot use these commands
#docker build ../templates/docker___jenkins_slave_pod \
#-t docker-registry-default.apps.$GUID.example.opentlc.com/xyz-jenkins/jenkins-slave-maven-appdev:v3.9

cat ../templates/docker___jenkins_slave_pod/Dockerfile | oc new-build --name=jenkins-slave-appdev -n $GUID-jenkins -D -
##creates
#build config
#oc export buildconfigs/jenkins-slave-maven-centos7 > jenkins_slave_pod/buildconfig.yaml
#imagestream imagestreams/jenkins-slave-maven-centos7 pointing to docker-registry.default.svc:5000/mons-xxx/jenkins-slave-maven-centos7
#oc export imagestreams/jenkins-slave-maven-centos7 > jenkins_slave_pod/imagestream.yaml

#verify
oc export bc,is -l name=jenkins-slave-appdev

#should we oc start-build buildconfigs/jenkins-slave-appdev
### here
###   => only once, creates "latest" tag in imagestream
### other possibilities? if we don't run it here, then when will the latest tag be built? when we try to instantiate a pod with the relevant name? (No, looks like it just waits for the pod template to be available)

#sed "s/%GUID%/$GUID/g;s/%REPO%/$REPO/g;s/%CLUSTER%/$CLUSTER/g" ../templates/file.yaml | oc create -n $GUID-jenkins -f -
########################## end maven slave pod with skopeo



########################## start build for each microservice
#MLBParks
oc new-build --name=$GUID-mlbparks $REPO --context-dir=MLBParks
#NationalParks
oc new-build --name=$GUID-nationalparks $REPO --context-dir=Nationalparks
#ParksMap
oc new-build --name=$GUID-parksmap $REPO --context-dir=ParksMap

#########start environment variables
oc set env bc/$GUID-mlbparks GUID=$GUID CLUSTER=$CLUSTER
oc set env bc/$GUID-nationalparks GUID=$GUID CLUSTER=$CLUSTER
oc set env bc/$GUID-parksmap GUID=$GUID CLUSTER=$CLUSTER
#note: none of these seem to create the environment variabiles
#oc new-build --name=$GUID-mlbparks $REPO --context-dir=MLBParks --env=GUID=$GUID --env=CLUSTER=$CLUSTER
#oc new-build --name=$GUID-mlbparks $REPO --context-dir=MLBParks -e GUID=$GUID
#oc new-build --name=$GUID-mlbparks $REPO --context-dir=MLBParks -e GUID=$GUID
#########END environment variables

############################end build for each microservice
