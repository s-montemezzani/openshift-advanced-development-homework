#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# Code to set up the SonarQube project.
# Ideally just calls a template
# oc new-app -f ../templates/sonarqube.yaml --param .....

# To be Implemented by Student

########################## start first setup with 'oc commands', then turning into .yaml templates
#comment#oc new-app --template=postgresql-persistent --param POSTGRESQL_USER=sonar --param POSTGRESQL_PASSWORD=sonar --param POSTGRESQL_DATABASE=sonar --param VOLUME_CAPACITY=4Gi --labels=app=sonarqube_db
#comment#oc export template postgresql-persistent -n openshift > postgresql-persistent.yaml


#comment#oc new-app --file=../templates/guid-sonarqube/postgresql-persistent.yaml --param POSTGRESQL_USER=sonar --param POSTGRESQL_PASSWORD=sonar --param POSTGRESQL_DATABASE=sonar --param VOLUME_CAPACITY=4Gi --labels=app=sonarqube_db


#comment#oc new-app --docker-image=wkulhanek/sonarqube:6.7.4 --env=SONARQUBE_JDBC_USERNAME=sonar --env=SONARQUBE_JDBC_PASSWORD=sonar --env=SONARQUBE_JDBC_URL=jdbc:postgresql://postgresql/sonar --labels=app=sonarqube
#comment#oc rollout pause dc sonarqube
#comment#echo "apiVersion: v1
#comment#kind: PersistentVolumeClaim
#comment#metadata:
  #comment#name: sonarqube-pvc
#comment#spec:
  #comment#accessModes:
  #comment#- ReadWriteOnce
  #comment#resources:
    #comment#requests:
      #comment#storage: 4Gi" | oc create -f -
#comment#oc set volume dc/sonarqube --add --overwrite --name=sonarqube-volume-1 --mount-path=/opt/sonarqube/data/ --type persistentVolumeClaim --claim-name=sonarqube-pvc
#comment#oc set resources dc/sonarqube --limits=memory=3Gi,cpu=2 --requests=memory=2Gi,cpu=1
#comment#oc patch dc sonarqube --patch='{ "spec": { "strategy": { "type": "Recreate" }}}'
#comment#oc set probe dc/sonarqube --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok
#comment#oc set probe dc/sonarqube --readiness --failure-threshold 3 --initial-delay-seconds 20 --get-url=http://:9000/about
#comment#oc rollout resume dc sonarqube

#comment#oc export dc,is,svc,pvc > sonar.yaml
#change mons-5c83 with %GUID%
#image stream will be trying to pull from docker-registry.default.svc:5000/mons-5c83-nexus/nexus3 , where the image is not available
#  => change spec/tags/from/name to the external registry docker.io/sonatype/nexus3

#for routes
#comment#oc expose service sonarqube

########################## end first setup with 'oc commands', then turning into .yaml templates

oc new-app --file=../templates/guid-sonarqube/postgresql-persistent/postgresql-persistent.yaml --param POSTGRESQL_USER=sonar --param POSTGRESQL_PASSWORD=sonar --param POSTGRESQL_DATABASE=sonar --param VOLUME_CAPACITY=4Gi --labels=app=sonarqube_db -n $GUID-sonarqube

while : ; do
   echo "Checking if postgresql is Ready... For Sonarqube"
   #oc get pod -n ${GUID}-sonarqube|grep '\-2\-'|grep -v deploy|grep "1/1"
   oc get pod -n ${GUID}-sonarqube | grep postgresql | grep -v deploy | grep "1/1" | grep Running
   [[ "$?" == "1" ]] || break
   echo "...no. Sleeping 10 seconds."
   sleep 10
done

sed "s/%GUID%/$GUID/g" ../templates/guid-sonarqube/sonar.yaml | oc create -n $GUID-sonarqube -f -
