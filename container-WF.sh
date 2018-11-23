#!/bin/bash

set -e
blueprint=$1
CONTAINER_NAME=$(ctx node properties container_ID)
IMAGE_NAME=$(ctx node properties image_name)


# Start Timestamp
STARTTIME=`date +%s.%N`
 
#-----------------------------------------#
#----------- pull the image --------------#
set +e
   Image=''
   base=${IMAGE_NAME//['/:']/_}
   tag=$(git describe --exact-match --tags $(git log -n1 --pretty='%h'))
   branch=$(git rev-parse --abbrev-ref HEAD)         
   wf=$1                #${PWD##*/}    # get WF name
   if [[ -z $tag ]]; then
     image=$base-$wf-$branch
   else 
     image=$base-$wf-$branch:$tag
   fi 
   image=${image,,}
ctx logger info "image is ${image}"
set -e

if [[ "$(sudo docker images -q dtdwd/${image} 2> /dev/null)" != "" ]]; then
 ctx logger info "local workflow image"
 Image=dtdwd/${image}
else 
   #ssh cache@192.168.56.103 test -f "DTDWD/${image}.tar.gz" && flag=1
   #ctx logger info "$flag"
   #if [[  $flag = 1  ]]; then
   #   ctx logger info "cached task image"
   #   set +e           
   #       scp -P 22 cache@192.168.56.103:DTDWD/${image}.tar.gz ${image}.tar.gz
   #       zcat --fast ${image}.tar.gz | docker load
   #       rm ${image}.tar.gz
   #   set -e    
   #   Image=dtdwd/${image}
  #else
      dock=$(sudo docker search dtdwd/${image})     #WF image from public hub
      set +e
        found=`echo $dock | grep -c dtdwd/${image}`                   
      set -e
      if [[ $found = 1 ]]; then
         ctx logger info "task image from public hub"
         sudo docker pull dtdwd/${image} &>/dev/null
         Image=dtdwd/${image}
      else
          if [[ "$(sudo docker images -q ${IMAGE_NAME} 2> /dev/null)" != "" ]]; then
             ctx logger info "local specified image"
             Image=${IMAGE_NAME}
          #else
          #    b=$(basename $IMAGE_NAME)
          #    if ssh cache@192.168.56.103 stat DTDWD/$b.tar.gz \> /dev/null 2\>\&1    #cached specified image
          #    then
          #      set +e
          #        #echo "from local repo."
          #        scp -P 22 cache@192.168.56.103:DTDWD/$b.tar.gz $b.tar.gz
          #        zcat --fast $b.tar.gz | docker load
          #        Image=${IMAGE_NAME}
          #        rm $b.tar.gz
          #      set -e
              else
                dock=$(sudo docker search ${IMAGE_NAME})
                set +e
                 found=`echo $dock | grep -c ${IMAGE_NAME}`
                set -e
                if [[ $found = 1 ]]; then
                  ctx logger info "specified image from public hub"
                  sudo docker pull ${IMAGE_NAME} &>/dev/null
                  Image=${IMAGE_NAME} 
                else
                 #default image
                 sudo docker pull ubuntu:14.04 &>/dev/null
                 Image=ubuntu:14.04
                fi
             fi
          fi
      #fi
  #fi
fi
#----------- pull the image --------------#
#-----------------------------------------#

# End timestamp
ENDTIME=`date +%s.%N`

# Convert nanoseconds to milliseconds crudely by taking first 3 decimal places
TIMEDIFF=`echo "$ENDTIME - $STARTTIME" | bc | awk -F"." '{print $1"."substr($2,1,3)}'`
echo "downloading ${Image} image : $TIMEDIFF" | sed 's/[ \t]/, /g' >> ~/list.csv
#------------------------------------------------------------------------------------------------------#
# Start Timestamp
STARTTIME=`date +%s.%N`

#-----------------------------------------#
#---------- creat the container ----------#

sudo docker run -P --name ${CONTAINER_NAME} -v ~/${blueprint}:/root/${blueprint} -it -d ${Image} bin/bash

#---------- creat the container ----------#
#-----------------------------------------#

# End timestamp
ENDTIME=`date +%s.%N`

# Convert nanoseconds to milliseconds crudely by taking first 3 decimal places
TIMEDIFF=`echo "$ENDTIME - $STARTTIME" | bc | awk -F"." '{print $1"."substr($2,1,3)}'`
echo "Creating container ${CONTAINER_NAME} : $TIMEDIFF" | sed 's/[ \t]/, /g' >> ~/list.csv
