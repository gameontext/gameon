#!/usr/bin/python
import sys
import ruamel.yaml
import io

if ( len(sys.argv) != 4 ) :
  print 'Error, Usage: submodule.sh modulename build|image live|docker'
  sys.exit(1)

module = sys.argv[1]
action = sys.argv[2]
live = sys.argv[3]

if( not (action == 'build' or action == 'image') ) :
  print 'Error, Action must be build or image. Found: '+action
  sys.exit(2)

if( not (live == 'live' or live == 'docker') ) :
  print 'Error, Build type must be live or docker. Found: '+live
  sys.exit(3)

print 'Configured for module: '+module+' '+action+' '+live

with io.open('docker-compose.yml', 'r') as stream:
   data = ruamel.yaml.load(stream, ruamel.yaml.RoundTripLoader)

if( module in data['services'] ):
  print "Module "+module+" found in yaml"
else:
  print "Module "+module+" unknown"
  sys.exit(4)

target = './'+module+'/'+module+'-wlpcfg/servers/gameon-'+module+':/opt/ibm/wlp/usr/servers/defaultServer'
context = module+'/'+module+'-wlpcfg'

if( module == 'proxy' ):
  target = './proxy:/etc/haproxy'
  context = 'proxy'

if( module == 'webapp' ):
  target = './webapp/src:/opt/www'
  context = 'webapp'

if( action == 'build' ):
  data['services'][module].pop('image', None)
  data['services'][module].pop('build', None)
  contextblock = dict( context = context )
  data['services'][module]['build'] = contextblock

if( action == 'image' ):
  data['services'][module].pop('image', None)
  data['services'][module].pop('build', None)
  data['services'][module]['image'] = 'gameontext/gameon-'+module

if( live == 'docker' ):
  if( 'volumes' in data['services'][module] ):
    clean = []
    for v in data['services'][module]['volumes'] :
      if( not target == v ):
        clean.append(v)
    if( len(clean) > 0 ):
      data['services'][module]['volumes'] = clean
    else:
      print('removing empty volumes block')
      data['services'][module].pop('volumes',None)

if( live == 'live' ): 
  if( not 'volumes' in data['services'][module] ):
     data['services'][module]['volumes'] = []
  found = False
  for v in data['services'][module]['volumes'] :
     if( target == v ):
        found=True
  if( not found ):
    data['services'][module]['volumes'].append(target)

#print(ruamel.yaml.dump(data, Dumper=ruamel.yaml.RoundTripDumper))

with open('docker-compose.yml', 'w') as outfile:
    ruamel.yaml.dump(data, outfile, Dumper=ruamel.yaml.RoundTripDumper)
