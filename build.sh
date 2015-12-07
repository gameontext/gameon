for SUBDIR in *
do 
  if [ -d "${SUBDIR}" ]
  then
    cd $SUBDIR
    ../gradlew build
    cd ..
  fi
done
