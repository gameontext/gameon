for SUBDIR in *
do 
  if [ -d "${SUBDIR}" ]
  then
    cd $SUBDIR
    gradle build
    cd ..
  fi
done
