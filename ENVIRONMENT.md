# Environment settings for Game On!

The game's environment is configured in a few different ways:

* When running locally, `gameon.env` (or `gameon.${DOCKER_MACHINE_NAME}.env`) contains
  environment variables provided to the core game containers at startup.

* Some of these environment variables might instead come from etcd or other
  config provider if that is present

There are also two different toggles that change game behavior:

* `GAMEON_MODE` -- the value can be either `development` or `production`
   * `development` is used to enable experimental features, or to allow behaviors
      that facilitate testing

    * `production` is used in the hardened production environment

* `TARGET_PLATFORM` -- the value is either `local` or `bluemix`, more will likely
   arrive over time. This acts as a feature toggle to allow environment-specific
   configurations to be checked in alongside other code, but enabled only when
   on the target platform. For example:

   * Liberty has features that optimize
     collecting and forwarding logs when running on Bluemix. Setting
     `TARGET_PLATFORM=bluemix` will enable this feature and supporting config
     only in that environment.

    * When running locally, we enable application and config file monitoring.
      We otherwise disable this, as it is extraneous behavior for remote
      images.
      
