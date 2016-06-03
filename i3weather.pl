#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use Geo::METAR;
use JSON;

# METAR data request URL
my $request = HTTP::Request->new(GET =>
'http://weather.noaa.gov/pub/data/observations/metar/stations/CYKZ.TXT');
my $ua = LWP::UserAgent->new;
my $m = Geo::METAR->new;
my $curtime = time();
# If using custom separator insert here:
my $separator = "";
# Output foreground color
my $color = "\#477ab3";

################################
# Update timer sub (default 30m)
################################

sub timing {
    if (shift > ($curtime+1800)) {
        $curtime = time();
        return 1;
    }
    else {
        return 0;
    }
}

##############
# HTTP request
##############

sub request {
    my $response = $ua->request($request);
    if ($response->is_success) {
        my $tango = $response->decoded_content;
        $tango =~ s/^[^\n]*\n//s;
        $m->metar($tango);
    }
    else {
        print STDERR $response->status_line, "\n";
    }
}

##################
# Blocks made here
##################

sub eskimo {
    my $text = shift;
    my $name = shift;
    my $block;
    if (@_) {
        my $width = shift;
        $block = {full_text => "$text", color => "$color", name => "$name", min_width => "$width"};
    }
    else {
        $block = {full_text => "$text", color => "$color", name => "$name"};
    }
    return \$block;
}

#####################
# Weather subroutines
#####################

sub temp {
    my $temp = $m->{TEMP_C};
    $temp =~ s/^0{1}//;
    $temp = join(" ", "$temp°C", $separator);
    return eskimo($temp, 'temp', '00°C');
}

sub atmo {
    # Converting inHg to mbar
    my $mbar = ($m->{ALT} * 33.8638815);
    $mbar =~ s/\.\d*//;
    $mbar = join(" ", $mbar, "mbar", $separator);
    return eskimo($mbar, 'atmo', '0000 mbar');
}

sub wind {
    my $wind;
    my $measure = "KPH";
    # KPH is default
    $wind = ($m->{WIND_MPH} * 1.60934);
    # Uncomment for MPH
    #$wind = $m->{WIND_MPH};
    $wind =~ s/\.\d*//;
    # ???????
    if($m->{WIND_DIR_ABB}) {
        $wind = join(" ", $wind, $measure, $m->{WIND_DIR_ABB}, $separator);
    }
    else {
        $wind = join(" ", $wind, $measure, $separator);
    }
    return eskimo($wind, 'wind', '000 KPH');
}

sub sky {
    # Selects only the uppermost layer of clouds in sky
    my $sky = pop(@{$m->{SKY}});
    # Uncomment next line to be shown cloud coverage at ALL altitudes
    #my $sky = join(', ', @{$m->{SKY}});
    $sky .= " $separator";
    return eskimo($sky, 'sky');
}

sub weather {
    my $weather = pop(@{$m->{WEATHER}});
    if ($weather =~ /\w/) {
        $weather .= " $separator";
    }
    return eskimo($weather, 'weather');
}

###############
# In & out JSON
###############

# Condition for initial request
my $flag;

#block vars
my $temp;
my $atmo;
my $wind;
my $sky;
my $weather;

# Unbuffered STDOUT
$| = 1;

# Skipping version header.
print scalar <STDIN>;

# Start of the infinite array.
print scalar <STDIN>;

while (my ($statusline) = (<STDIN> =~ /^,?(.*)/)) {

    if (!$flag || timing(time())) {
        request();
        $temp = temp();
        $atmo = atmo();
        $wind = wind();
        $sky = sky();
        $weather = weather();
        $flag = 1;
    }

    my @blocks = @{decode_json($statusline)};

    #############
    # Block order
    #############

    @blocks = ($$weather,$$sky,$$temp,$$wind,$$atmo,@blocks);

    # Output as JSON.
    print encode_json(\@blocks) . ",\n";
}

# To Do:
########
# Other types of wind directions
# Relative Humidity block
# Other pressure units
# Overhaul weather and sky
# Alerts?
