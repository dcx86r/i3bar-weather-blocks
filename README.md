# i3bar-weather-blocks
i3bar METAR Weather Extension

This is an i3bar extension that functions similar to how Conky gets weather.  
Configurable options are commented in the script, block order can also be changed.

To install: 
- Get dependencies from CPAN (JSON, LWP::UserAgent, Geo::METAR)
- In your ~/.i3status.conf file make sure this is in the general block:
output_format = "i3bar"
- In your ~/.i3/config find the bar block and add:
status_command i3status | \<path-to-weather.pl\>
- Comment out existing status_command i3status
- Replace the prepopulated METAR data URL with one relevant to your location
- Reload i3
