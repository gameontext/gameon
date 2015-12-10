# gameon
The Root Repository

GameOn quick start developers guide.. 

Obtain the source
```
git clone --recursive git@github.com:gameontext/gameon.git
cd gameon
```

Build the projects with gradle. (Note this just runs gradle build against each subdir, until we write some gradle in the root project for a cleaner solution)
```
./build.sh
```
Now we build the docker containers with docker-compose.

#Run from containers.. 

If you just want to run gameon locally, and don't mind rebuilding the docker containers each time, then rename docker-compose.override.yml to docker-compose.override.yml.backup  and then run.. 

```
docker-compose build
docker-compose up
```

Gameon is now running locally, you can acccess it at http://127.0.0.1/

If you make code changes, just rerun the build.sh, and the docker-compose build steps to have the changes be reflected in the application.

#Run from eclipse (with jee).. 

This route requires considerable extra setup.. but offers the advantage that code changes can be immediately reflected in the running containers, eliminating many gradle build, docker-compose build, docker-compose up cycles.. It's not exactly how the eclipse tooling is supposed to be used, but for now, it's the only way to cause eclipse to author us the application xml file that we can use to allow us to run with our code live in the workspace.

Make sure the docker-compose.override.yml file is there (if you renamed it because you ran locally the other way, rename it back now). 

To import the projects into eclipse, run the eclipse.sh (it just runs gradle eclipse eclipsewtp against each subdir, again, when we write the gradle for the root project this will be a bit cleaner). This generates the eclipse project files, allowing the projects to be imported.

Fire up eclipse, and go File->Import->General->Import Existing Projects into Workspace
Select the gameon directory created by the git clone operation.
Tick the 'search for nested projects' button.

This should result in a collection of projects being imported to the workspace.

For the full 'run in eclipse' support we need to have eclipse believe we're deploying the applications to servers it manages.. maybe one day there'll be a better way to manage this, but for now we'll play along with eclipse.

On the servers tab, right click and select new-server, select ibm-websphere application server liberty profile, on the next tab, verify you have a java 8 jre selected, and select install from repository. Select download from IBM Websphere Liberty Repository, and select the WAS Liberty with Java EE7 Full Platform option. In the Install Additional Content panel, type mongo in the search box and select the MongoDB Integration 2.0 feature. Agree to the licenses, do not deploy any of the applications suggested to the server, and allow eclipse to download liberty.

Go make a cup of tea, or coffee.. 

Once thats all done.. we now need to tell eclipse the wlpcfg projects are servers for that runtime..

Window->Preferences->Server->Runtime Environment

Select the Liberty server, and hit edit, Select the 'advanced options' underlined text to arrive at a dialog where you can add User Directories for the server. Hit the 'New...' button, and add a -wlpcfg project, and hit finish, repeat until you have added all the -wlpcfg projects (4 of them at the moment) Finally hit ok, then finish. 

Now right click the servers tab, and select 'new->Server' and then make sure your new downloaded liberty is set as the 'server runtime environment' Give the server a name, we're going to create 1 server for each wlpcfg project ... eg "eclipse concierge wlpcfg" and hit next.. then from the drop down, select the corresponding project for the server you are creating (it should have options like 'gameon concierge' etc.. if not, maybe you skipped the previous section where we added them via advanced options) Repeat this until you have all the -wlpcfg projects represented as servers in the servers tab.

Now we deploy the projects to the servers.. right click each server in the server tab and select 'add/remove...' In the dialog that opens, remove the app on the right thats configured and greyed out.. and add back the same app (not greyed out) from the left panel. Hit finish, then repeat for each server.

Now goto each server, right click, and say 'publish'. Verify that in the servers/gameon-*/apps folder there is now an *-app.war.xml file (you may need refresh the folder if you have already opened it). Ignore messages about Publishing failed.

(If you have troubles.. you may need to delete the war files the build.sh created)

Congratulations.. you should now have all the wlpcfg projects with a *-app.war.xml file ready to run. 

Now.. with the override file in place, you can do 

```
docker-compose up
```

And all the servers will spin up, and load the apps from the eclipse workspace directly. If you edit the java code.. the app will reflect the change without requiring a restart via docker-compose.

(Note: obviously this can only go so far, if you make changes that alter the links between the containers, or add other external dependencies that eclipse is unaware of, then a restart will still be needed.)













