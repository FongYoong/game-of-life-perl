#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Tk;

my $windowTitle = "Game of Life - Intel Edition";
my $helpOption = 0;
my $repoOption = 0;
my $xLength = 100;
my $yLength = 50;
my $boxSize = 10;
my $vicinity = 1;
my $destroyAtBorder = 0;
my $timeDelay = 50;

GetOptions(
    "help" => \$helpOption,
    "repo" => \$repoOption,
    "xLength=i" => \$xLength,
    "yLength=i" => \$yLength,
    "boxSize=i" => \$boxSize,
    "vicinity=i" => \$vicinity,
    "destroyAtBorder=i" => \$destroyAtBorder,
    "timeDelay=i" => \$timeDelay
) or die("Error in command line arguments\n");
if ($helpOption){
    my %options = (
        "-r, --repo" => "View Github repository",
        "-x, --xLength" => "Horizontal grid length",
        "-y, --yLength" => "Vertical grid length",
        "-b, --boxSize" => "Size of each grid point",
        "-v, --vicinity" => "Range to detect neighbours (Experimental)",
        "-d, --destroyAtBorder" => "A value of 1 prevents wrap-round at grid borders",
        "-t, --timeDelay" => "Grid refresh rate in milliseconds"
    );
    my $maxLength = 0;
    foreach my $key (keys %options) {
        my $keyLength = length $key;
        $maxLength = $keyLength if $keyLength > $maxLength;
    }
    print "\n";
    foreach my $key (sort keys %options) {
        my $gap = $maxLength - length($key);
        print "\t$key", " "x$gap, "\t$options{$key}\n";
    }
    print "\n";
    exit;
}
exec("xdg-open https://github.com/FongYoong/game-of-life-perl") if $repoOption;

my $window = MainWindow->new(-title => $windowTitle);
if($xLength < 0 || $yLength < 0 || $boxSize < 0 || $vicinity < 0 || $timeDelay < 0){
    $window->messageBox(-title => "Error!", -message => "Negative values are not allowed!", -type => 'Oops', -icon => 'error');
    exit;
}

my $code_font = $window->fontCreate('code', -family => 'calibri', -size => 15);
my $mainFrame = $window->Frame()->pack(-side => 'top', -fill => 'x');
my $playgroundButton = $mainFrame->Button(-text => "Playground", -font => $code_font, -command => sub{
    exec("perl ./GOL_Playground.pl -x=$xLength -y=$yLength -b=$boxSize -v=$vicinity -d=$destroyAtBorder -t=$timeDelay");
})->pack(-fill => 'x', -pady => 5);
my $logicGatesButton = $mainFrame->Button(-text => "Logic Gates", -font => $code_font, -command => sub{
    exec("perl ./GOL_Logic_Gates.pl -t=$timeDelay");
})->pack(-fill => 'x', -pady => 5);

MainLoop;