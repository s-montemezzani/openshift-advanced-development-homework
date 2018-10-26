#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Nexus in project $GUID-nexus"

# Code to set up the Nexus. It will need to
# * Create Nexus
# * Set the right options for the Nexus Deployment Config
# * Load Nexus with the right repos
# * Configure Nexus as a docker registry
# Hint: Make sure to wait until Nexus if fully up and running
#       before configuring nexus with repositories.
#       You could use the following code:
# while : ; do
#   echo "Checking if Nexus is Ready..."
#   oc get pod -n ${GUID}-nexus|grep '\-2\-'|grep -v deploy|grep "1/1"
#   [[ "$?" == "1" ]] || break
#   echo "...no. Sleeping 10 seconds."
#   sleep 10
# done

# Ideally just calls a template
# oc new-app -f ../templates/nexus.yaml --param .....

# To be Implemented by Student


########################## start first setup with 'oc commands', then turning into .yaml templates
#comment#oc new-app docker.io/sonatype/nexus3:latest
#comment#oc rollout pause dc nexus3
#comment#oc patch dc nexus3 --patch='{ "spec": { "strategy": { "type": "Recreate" }}}'
#comment#oc set resources dc nexus3 --limits=memory=2Gi,cpu=2 --requests=memory=1Gi,cpu=500m
#comment#echo "apiVersion: v1
#comment#kind: PersistentVolumeClaim
#comment#metadata:
  #comment#name: nexus-pvc
#comment#spec:
  #comment#accessModes:
  #comment#- ReadWriteOnce
  #comment#resources:
    #comment#requests:
      #comment#storage: 4Gi" | oc create -f -

#comment#oc set volume dc/nexus3 --add --overwrite --name=nexus3-volume-1 --mount-path=/nexus-data/ --type persistentVolumeClaim --claim-name=nexus-pvc
#comment#oc set probe dc/nexus3 --liveness --failure-threshold 3 --initial-delay-seconds 60 -- echo ok
#comment#oc set probe dc/nexus3 --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8081/repository/maven-public/

#comment#oc rollout resume dc nexus3

#comment#oc expose dc nexus3 --port=5000 --name=nexus-registry

#comment#oc export dc,is,svc,pvc > nexus.yaml
#change mons-5c83 with %GUID%
#image stream will be trying to pull from docker-registry.default.svc:5000/mons-5c83-nexus/nexus3 , where the image is not available
#  => change spec/tags/from/name to the external registry docker.io/sonatype/nexus3
#pvc as exported will contain tags you have to remove (see yaml above)
##metadata/anotations
##metadata/creationTimestamp
##spec/volumeName
##status
#

#for routes
#comment#oc expose svc nexus3
#comment#oc create route edge nexus-registry --service=nexus-registry --port=5000
#comment#oc export route > nexus_routes.yaml
#change mons-5c83 with %GUID%

########################## end first setup with 'oc commands', then turning into .yaml templates

sed "s/%GUID%/$GUID/g" ../templates/guid-nexus/nexus.yaml | oc create -n $GUID-nexus -f -

#wait for nexus to start up
sleep 120

#check if the slave pod created by the grading jenkins can curl, write files to current directory, remove at the end, ......
#cd /tmp
curl -o setup_nexus3.sh -s https://raw.githubusercontent.com/wkulhanek/ocp_advanced_development_resources/master/nexus/setup_nexus3.sh
chmod +x setup_nexus3.sh
./setup_nexus3.sh admin admin123 nexus3.$GUID-nexus.svc.cluster.local:8081
rm setup_nexus3.sh





