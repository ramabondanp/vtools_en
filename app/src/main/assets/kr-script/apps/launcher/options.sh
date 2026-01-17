#!/system/bin/sh

# pm query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME

# launchers=$(pm query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME | grep '/' | sed 's/\ //g')

# Get all installed home/launcher apps
launchers=$(pm query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME | grep '/')

for launcher in $launchers ; do
    packageName=`echo $launcher | cut -f1 -d '/'`
    echo "$launcher|$packageName"
done
