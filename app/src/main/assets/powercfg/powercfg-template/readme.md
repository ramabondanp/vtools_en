Here, you can configure two sets of pattern files with different styles for your device. When the packaged apk is running, you can switch the mode file in the performance configuration interface.

# Conservative style pattern file
-conservative-base.sh
-conservative.sh

# Schedule active mode files
-active-base.sh
-active.sh

# Specific instructions
-active-base.sh and conservative-base.sh are not frequently used, they will only be executed once at the very beginning to restore some changes that have been made by the user, and they can be left blank if not necessary.
-active.sh and conservative.sh are the main configuration scripts, which need to define the script codes to be executed in 4 modes.

-If you don't want to create the configuration by modifying the apk, you can also directly copy the written powercfg.sh to the data directory [the path of the final configuration script is /data/powercfg.sh], and modify the permissions to 0644.
-Pay attention to the encoding format of the configuration script, which should be unix, otherwise it cannot be recognized by the command line, and the mode switch cannot be performed.

# Single application adaptation
-In addition to the most basic 4 performance adjustment modes, Scene 4.3 adds [strict mode] (need to be manually turned on in the performance configuration interface)
-After turning on [strict mode], as long as the foreground application changes, Scene will trigger the scheduling switch
-* If you do not enable [strict mode] or use a version earlier than Scene 4.3, the scheduling switch will only be triggered when the mode needs to be changed
-How do I know that the app was opened just now? You can get it in the script through the `top_app` variable saved in Scene, example:

```sh
if [[ "$top_app" != "" ]]; then
  echo "App switch to the foreground [$top_app]"
fi
```

## Special circumstances
-After turning on the [strict mode] mode, you may still get a blank `$top_app`
-This is because the scheduling switch is not triggered by the dynamic response function
-For example: the scheduling switch triggered by the user's active click, timed task, screen on and off, etc., and when init is executed, you will get a blank `top_app`
