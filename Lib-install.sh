#!/bin/bash

set -e

CONTAINER_NAME=$1
Lib_URL=$2
Lib_name=$(ctx node properties lib_name)
Lib_path=$(ctx node properties lib_path)

# Start Timestamp
STARTTIME=`date +%s.%N`

sudo docker exec -it ${CONTAINER_NAME} test -f $Lib_path/$Lib_name || test -f $Lib_name && exit 0
        

sudo docker exec -it ${CONTAINER_NAME} test -d $Lib_path && sudo docker exec -it ${CONTAINER_NAME} rm -rf $Lib_path

file_name=$(basename "$Lib_URL")
ctx logger info "before downloading"
[ ! -f ~/.TDWF/libs/$file_name ] && wget -O ~/.TDWF/libs/$file_name ${Lib_URL}

flag=0

sudo docker exec -it ${CONTAINER_NAME} test ! -f $file_name && flag=1

if [[ $flag == 1 ]]; then
  ctx logger info "copy $file_name"
 cat ~/.TDWF/libs/$file_name | sudo docker exec -i ${CONTAINER_NAME} sh -c 'cat > '$file_name
fi

tar="tar.gz"
set +e
sudo docker exec -it ${CONTAINER_NAME} test "${file_name#*$tar}" != "$file_name" && sudo docker exec -it ${CONTAINER_NAME} tar -zxvf $file_name

sudo docker exec -it ${CONTAINER_NAME} chmod -R 777 $Lib_path/$Lib_name
set -e

 # End timestamp
ENDTIME=`date +%s.%N`

# Convert nanoseconds to milliseconds
# crudely by taking first 3 decimal places
TIMEDIFF=`echo "$ENDTIME - $STARTTIME" | bc | awk -F"." '{print $1"."substr($2,1,3)}'`
echo "install $Lib_name in $CONTAINER_NAME: $TIMEDIFF" | sed 's/[ \t]/, /g' >> ~/list.csv   
