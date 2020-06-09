#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Tk;

$| = 1;

my $windowTitle = "Game of Life - Intel Edition";
my $boxSize = 5;
my $xLength = 180;
my $yLength = 80;
my $vicinity = 1;
my $destroyAtBorder = 1;
my $delay = 0.01 * 1000;

my $window = MainWindow->new(-title => $windowTitle);
my $code_font = $window->fontCreate('code', -family => 'calibri', -size => 15);
my $mainFrame = $window->Frame()->pack(-side => 'top', -fill => 'x');
my $playgroundButton = $mainFrame->Button(-text => "Playground", -font => $code_font, -command => sub{
    exec("perl ./GOL_Playground.pl --help");
})->pack(-fill => 'x', -pady => 5);
my $logicGatesButton = $mainFrame->Button(-text => "Logic Gates", -font => $code_font, -command => sub{
    exec("perl ./GOL_Logic_Gates.pl --help");
})->pack(-fill => 'x', -pady => 5);

MainLoop;