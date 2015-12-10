for SUBDIR in *
do 
  if [ -d "${SUBDIR}" ] && [ -e "${SUBDIR}/build.gradle" ]
  then
    cd $SUBDIR
    ../gradlew cleanEclipse eclipse
    cd ..
  fi
done
