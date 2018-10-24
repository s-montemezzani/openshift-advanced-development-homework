#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student

#Grant the correct permissions to the Jenkins service account
 #Create a MongoDB database
 #Create binary build configurations for the pipelines to use for each microservice
 #Create ConfigMaps for configuration of the applications
 #Set APPNAME to the following values—the grading pipeline checks for these exact strings:
 #MLB Parks (Dev)
 #National Parks (Dev)
 #ParksMap (Dev)
 #Set up placeholder deployment configurations for the three microservices
 #Configure the deployment configurations using the ConfigMaps
 ###### configmapKeyRef... goes in Pod configuration
 ##### Pod is autocreated by Replication controller, which is autocreated by Deployment config
 ##### => configure configmap in deploymentconfig
 #Set deployment hooks to populate the database for the back end services
 ######## MLBParks/README.adoc
 ######## The endpoint `/ws/data/load/` creates the data in the MongoDB database and will need to be called (preferably with a post-deployment-hook) once the Pod is running.

 #Set up liveness and readiness probes
 #Expose and label the services properly (parksmap-backend)

oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n $GUID-parks-dev

oc new-app registry.access.redhat.com/rhscl/mongodb-34-rhel7:latest --name="mongodb"



oc export svc,is,dc > mongodb.yaml

#let's make for each application a .yaml file with
### buildconfig
### deploymentconfig
### configMap
### imagestream
### exposed service ?

oc new-build --binary=true --name="parksmap-dev" redhat-openjdk18-openshift:1.2 -n $GUID-parks-dev
oc new-build --binary=true --name="mlbparks-dev" jboss-eap70-openshift:1.7 -n $GUID-parks-dev
oc new-build --binary=true --name="nationalparks-dev" redhat-openjdk18-openshift:1.2 -n $GUID-parks-dev

#needs imagestream => after new-build
oc new-app $GUID-parks-dev/parksmap-dev:0.0-0 --name=parksmap-dev --allow-missing-imagestream-tags=true -n $GUID-parks-dev
oc set triggers dc/parksmap-dev --remove-all -n $GUID-parks-dev
#let's skip the oc expose for now

oc create configmap parksmap-dev-configmap \
--from-literal="DB_HOST=mongodb" \
--from-literal="DB_PORT=27017" \
--from-literal="DB_USERNAME=mongodb" \
--from-literal="DB_PASSWORD=mongodb" \
--from-literal="DB_NAME=parks" \
--from-literal="APPNAME=ParksMap (Dev)" \
-n $GUID-parks-dev

oc set env dc/parksmap-dev --from=configmap/parksmap-dev-configmap -n $GUID-parks-dev

oc set probe dc/parksmap-dev --liveness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:????-------BOH------????/ws/healthz -n $GUID-parks-dev
oc set probe dc/parksmap-dev --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:????-------BOH------????/ws/healthz -n $GUID-parks-dev


oc create configmap mlbparks-dev-configmap \
--from-literal="DB_HOST=mongodb" \
--from-literal="DB_PORT=27017" \
--from-literal="DB_USERNAME=mongodb" \
--from-literal="DB_PASSWORD=mongodb" \
--from-literal="DB_NAME=parks" \
--from-literal="APPNAME=MLB Parks (Dev)" \
-n $GUID-parks-dev

oc create configmap nationalparks-dev-configmap \
--from-literal="DB_HOST=mongodb" \
--from-literal="DB_PORT=27017" \
--from-literal="DB_USERNAME=mongodb" \
--from-literal="DB_PASSWORD=mongodb" \
--from-literal="DB_NAME=parks" \
--from-literal="APPNAME=National Parks (Dev)" \
-n $GUID-parks-dev

/*
MLBParks expects the MongoDB connection information in the following environment variables:

* DB_HOST=mongodb (Name of the MongoDB Service)
* DB_PORT=27017 (Port the MongoDB Service is running under)
* DB_USERNAME=mongodb (Username for the MongoDB database)
* DB_PASSWORD=mongodb (Password for the user)
* DB_NAME=parks (Database Name)
* DB_REPLICASET=rs0 (Name of the Replicaset if MongoDB is deployed as a Stateful Service. Not set for standalone database)

MLBParks also expects an environment variable  (which can be set in the Config Map as well if desired) to set the displayed name of the backend. It is *mandatory* for this variable to be set for the automatic grading to succeed.

Valid values are:

* APPNAME="MLB Parks (Green)"
* APPNAME="MLB Parks (Blue)"

*/