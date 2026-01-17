echo 'Disable auto-rotate'
# content insert --uri content://settings/system --bind name:s:accelerometer_rotation --bind value:i:0
settings put system accelerometer_rotation 0

echo 'Set screen rotation'
# content insert --uri content://settings/system --bind name:s:user_rotation --bind value:i:$state
settings put system user_rotation $state
