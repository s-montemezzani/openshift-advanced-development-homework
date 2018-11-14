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
 ######## https://docs.openshift.com/container-platform/3.4/dev_guide/deployments/deployment_strategies.html#lifecycle-hooks
 #Set up liveness and readiness probes
 #Expose and label the services properly (parksmap-backend)


: <<'COMMENT_DELIMITER'
###reference only, sometimes towards the end some things were changed directly in the .yaml file

oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n $GUID-parks-dev

#oc new-app registry.access.redhat.com/rhscl/mongodb-34-rhel7:latest --name="mongodb"
oc new-app registry.access.redhat.com/rhscl/mongodb-34-rhel7:latest --name="mongodb" \
--env=MONGODB_DATABASE=parks \
--env=MONGODB_USER=mongodb \
--env=MONGODB_PASSWORD=mongodb \
--env=MONGODB_ADMIN_PASSWORD=admin \
--env=MONGODB_KEYFILE_VALUE=12345678901234567890 \
--env=MONGODB_SERVICE_NAME=admin

#is this only for replicated? i.e. when pod is started with run-mongod-replication
#oc set probe dc/mongodb --liveness --failure-threshold 3 --initial-delay-seconds -- stat /tmp/initialized
#oc set probe dc/mongodb --readiness --failure-threshold 3 --initial-delay-seconds -- stat /tmp/initialized
#oc export svc,dc,is > mongodb.yaml

sed "s/%GUID%/$GUID/g" ../templates/guid-parks-dev/mongodb_dev.yaml | oc create -n $GUID-parks-dev -f -


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

oc new-app $GUID-parks-dev/mlbparks-dev:0.0-0 --name=mlbparks-dev --allow-missing-imagestream-tags=true -n $GUID-parks-dev
oc set triggers dc/mlbparks-dev --remove-all -n $GUID-parks-dev

oc new-app $GUID-parks-dev/nationalparks-dev:0.0-0 --name=nationalparks-dev --allow-missing-imagestream-tags=true -n $GUID-parks-dev
oc set triggers dc/nationalparks-dev --remove-all -n $GUID-parks-dev

#let's skip the oc expose for now
oc expose dc mlbparks-dev --port=8080 -n $GUID-parks-dev
oc label svc mlbparks-dev type=parksmap-backend -n $GUID-parks-dev
oc expose dc nationalparks-dev --port=8080 -n $GUID-parks-dev
oc label svc nationalparks-dev type=parksmap-backend -n $GUID-parks-dev

oc create configmap parksmap-dev-configmap \
--from-literal="DB_HOST=mongodb" \
--from-literal="DB_PORT=27017" \
--from-literal="DB_USERNAME=mongodb" \
--from-literal="DB_PASSWORD=mongodb" \
--from-literal="DB_NAME=parks" \
--from-literal="APPNAME=ParksMap (Dev)" \
-n $GUID-parks-dev

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

oc set env dc/parksmap-dev --from=configmap/parksmap-dev-configmap -n $GUID-parks-dev
oc set env dc/mlbparks-dev --from=configmap/mlbparks-dev-configmap -n $GUID-parks-dev
oc set env dc/nationalparks-dev --from=configmap/nationalparks-dev-configmap -n $GUID-parks-dev

oc set probe dc/parksmap-dev --liveness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n $GUID-parks-dev
oc set probe dc/parksmap-dev --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n $GUID-parks-dev

oc set probe dc/mlbparks-dev --liveness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz -n $GUID-parks-dev
oc set probe dc/mlbparks-dev --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz -n $GUID-parks-dev

oc set probe dc/nationalparks-dev --liveness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n $GUID-parks-dev
oc set probe dc/nationalparks-dev --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n $GUID-parks-dev

#deployment hook only for nationalparks, mlbparks, according to README.adoc
#test
oc set deployment-hook --post dc/nationalparks-dev --failure-policy="abort" -n $GUID-parks-dev \
-- curl nationalparks-dev.$GUID-parks-dev.svc.cluster.local:8080/ws/data/load/
oc set deployment-hook --post dc/mlbparks-dev --failure-policy="abort" -n $GUID-parks-dev \
-- curl mlbparks-dev.$GUID-parks-dev.svc.cluster.local:8080/ws/data/load/


oc export dc,bc,is,cm,svc > 3apps_dev_binary_builds.yaml


COMMENT_DELIMITER


oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n $GUID-parks-dev
oc policy add-role-to-user view --serviceaccount=default -n $GUID-parks-dev
sed "s/%GUID%/$GUID/g" ../templates/guid-parks-dev/mongodb_dev.yaml | oc create -n $GUID-parks-dev -f -

sed "s/%GUID%/$GUID/g" ../templates/guid-parks-dev/3apps_dev_binary_builds.yaml | oc create -n $GUID-parks-dev -f -

