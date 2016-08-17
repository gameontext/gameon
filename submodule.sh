#!/bin/bash
MODULE=$1
ACTION=$2
LIVE=$3

if [ -z $MODULE ]
then
  echo "Bad Usage. Pass ModuleName (eg, auth, webapp), then (build|image) then (live|docker)"
  exit 3
fi

case "$ACTION" in
  build)
  ;;
  image)
  ;;
  *)
    echo "Unknown use type $ACTION requested for module $MODULE"
    exit 1;
  ;;
esac

case "$LIVE" in
  live)
  ;;
  docker)
  ;;
  *)
    echo "Unknown build type of $LIVE requested for module $MODULE, supported values are (live|docker)"
    exit 2;
  ;;
esac

case "$MODULE" in
  proxy)
    TARGET='./proxy:/etc/haproxy'
  ;;
  webapp)
    TARGET='./webapp/src:/opt/www'
  ;;
  *)
    TARGET='./'$MODULE'/'$MODULE'-wlpcfg/servers/gameon-'$MODULE':/opt/ibm/wlp/usr/servers/defaultServer'
  ;;
esac


gawk '\
BEGIN { FOUND=0; INBLOCK=0; FOUNDVOLUMES=0;}\
{\
  if( !INBLOCK && $1=="'$MODULE':" ) { \
    INBLOCK=1; \
    FOUND=1; \
    VOLUMES=0; \
    FOUNDVOLUMES=0; \
    print $0; \
  } else if( INBLOCK && /^[a-z]*:$/ ) { \
    INBLOCK=0; \
    if( !FOUNDVOLUMES && "'$LIVE'"=="live") { \
      FOUNDVOLUMES=1;\
      print " volumes:"; \
      print "  - '\'$TARGET\''";\
    } \
    print $0 \
  } else if( INBLOCK && /[ #]build:.*/ ) { \
    idx=match($0, "[ #]build:(.*)",matches);\
    if ( "'$ACTION'" == "build" ){ \
      print " build:",matches[1]; \
    } else { \
      print " #build:",matches[1]; \
    } \
  } else if( INBLOCK && /[ #]image:.*/ ) { \
    idx=match($0, "[ #]image:(.*)",matches);\
    if ( "'$ACTION'" == "build" ){ \
      print " #image:",matches[1]; \
    } else { \
      print " image:",matches[1]; \
    } \
  } else if( INBLOCK && !VOLUMES && /[ #]volumes:.*/ ) { \
    VOLUMES=1; \
    FOUNDVOLUMES=1; \
    FOUNDTARGET=0; \
    print $0;\
  } else if( INBLOCK && VOLUMES ) { \
    if( /(^[ ]*$|[ ]*#.*|[ ]*-[ ]*.*)/ ) { \
      if( /[ #]-[ ]*.*/ ) { \
        idx=match($0,"([ #]*-[ ]*)(.*)",matches); \
        if( "'\'$TARGET\''"==matches[2] ){ \
          FOUNDTARGET=1; \
          if( "'$LIVE'" == "live" ){ \
             print "  - '$TARGET'";\
          } else { \
             print "#  - '$TARGET'";\
          } \
        } else { \
          print $0; \
        } \
      } else { \
        print $0;
      }
    } else { \
      if( !FOUNDTARGET ) { \
          if( "'$LIVE'" == "live" ){ \
             print "  - '$TARGET'";\
          } else { \
             print "#  - '$TARGET'";\
          } \
       } \
      VOLUMES=0; \
      print $0;\
    } \
  } \
  else print $0; \
}\
END { if ( FOUND && !FOUNDVOLUMES && "'$LIVE'"=="live") { \
      print " volumes:"; \
      print "  - '\'$TARGET\''";\
} } \
' docker-compose.yml > docker-compose2.yml

if [ $? == 0 ]; then
  rm docker-compose.yml ; mv docker-compose2.yml docker-compose.yml
else
  echo "Error during yml processing, please report with log via github"
fi

