#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(abs_path);
use FindBin;
use lib abs_path("$FindBin::Bin/modules");
use Getopt::Long;
use Tk;
use OpenGL qw(:old);
use GOL_Grid;

my $windowTitle = "Game of Life - Intel Edition";
my $xLength = 200;
my $yLength = 90;
my $boxSize = 5;
my $vicinity = 1;
my $destroyAtBorder = 1;
my $timeDelay = 10;
my $minTimeDelay = 10;

GetOptions(
    "timeDelay=i" => \$timeDelay
);
$timeDelay = $minTimeDelay if $timeDelay < $minTimeDelay;

my $grid = new GOL_Grid('xLength'=>$xLength, 'yLength'=>$yLength, 'boxSize'=>$boxSize, 'vicinity'=>$vicinity, 'destroyAtBorder'=>$destroyAtBorder);
my $window;
my $canvas;
my $isPlaying = 0;
my $playID;
my $playButton;
my $showRegion = 0;
my $displayType;
my @displayOptions = ("Both", "Canvas Only", "Terminal Only");
my $lightBlue= "#00e6ff";
my $lightGreen = "#00ffb3";
my $lightOrange = "#ffae00";
my $code_font;

my $boolA = '';
my $boolB = '';
my $boolOperator;

sub PrintTerminalGrid{
    system("clear");
    print "\n";
    my %rangePoints = ();
    my @range = $grid->GetRange;
    if ($showRegion && defined $range[0]){
        foreach my $row ($range[2] .. $range[3]){
            $rangePoints{"$row $range[0]"} = 1;
        }
        foreach my $row ($range[2] .. $range[3]){
            $rangePoints{"$row $range[1]"} = 1;
        }
        foreach my $col ($range[0] .. $range[1]){
            $rangePoints{"$range[2] $col"} = 1;
        }
        foreach my $col ($range[0] .. $range[1]){
            $rangePoints{"$range[3] $col"} = 1;
        }
    }
    foreach my $row (0 .. $yLength - 1){
        foreach my $col (0 .. $xLength - 1){
            if ($showRegion && exists($rangePoints{"$row $col"})){
                print $row == $range[2] || $row == $range[3] ? '=' : '|';
            }
            else{
                my $currentState = $grid->GetCurrentState($row, $col, $grid->{_currentGrid});
                $currentState? print "*" : print".";
            }
        }
        print "\n";
    }
}
sub NormaliseCanvasPosition{
    my($x, $y, $xNorm, $yNorm) = (@_, ($xLength - 1) / 2, ($yLength - 1) / 2);
    my @rectified = (($x - $xNorm)/$xNorm, -($y - $yNorm)/$yNorm);
    @rectified;
}
sub PrintCanvasGrid{
    glClearColor(0, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glOrtho(-1, 1, -1, 1, -1, 1);
    glPointSize($boxSize);
    glBegin(GL_POINTS);
    glColor3f(0, 1, 0);
    foreach my $row (0 .. $yLength - 1){
        foreach my $col (0 .. $xLength - 1){
            my $currentState = $grid->GetCurrentState($row, $col, $grid->{_currentGrid});
            if($currentState){
                my @position = NormaliseCanvasPosition($col, $row);
                my $color = $currentState == $grid->GetCurrentState($row, $col, $grid->{_previousGrid}) ?1:0;
                glColor3f(0, !$color, $color);
                glVertex2f(@position);
            }
        }
    }
    my @range = $grid->GetRange;
    if ($showRegion && defined $range[0]){
        glColor3f(1, 0, 0);
        foreach my $row ($range[2] .. $range[3]){
            glVertex2f(NormaliseCanvasPosition($range[0], $row));
        }
        foreach my $row ($range[2] .. $range[3]){
            glVertex2f(NormaliseCanvasPosition($range[1], $row));
        }
        foreach my $col ($range[0] .. $range[1]){
            glVertex2f(NormaliseCanvasPosition($col, $range[2]));
        }
        foreach my $col ($range[0] .. $range[1]){
            glVertex2f(NormaliseCanvasPosition($col, $range[3]));
        }
    }
    glEnd;
    glFlush;
}
sub UpdateGame{
    if ($isPlaying){
        $grid->UpdateCurrentGrid;
    }
    else{
        $grid->AdaptRange;
    }
    PrintCanvasGrid if $displayType eq $displayOptions[1] || $displayType eq $displayOptions[0];
    PrintTerminalGrid if $displayType eq $displayOptions[2] || $displayType eq $displayOptions[0];
}
sub RunGame{
   if($isPlaying){
      $isPlaying = 0;
      $playID->cancel;
   }
   else{
      $isPlaying = 1;
   }
}
sub ResetPlayButton{
    $playButton->deselect;
    $playButton->configure(-text => "Play");
}
sub ClearGame{
    $canvas->delete('texts');
    ResetPlayButton;
    RunGame if $isPlaying;
    $grid->ResetCurrentGrid();
    UpdateGame;
}
sub ErrorDialog{
    my ($title, $message) = @_;
    $window->messageBox(-title => $title, -message => $message, -type => 'Ok', -icon => 'error');
}
sub ChangeTime{
    my ($operator) = @_;
    RunGame if $isPlaying;
    ResetPlayButton;
    my $newTime = eval "$timeDelay $operator 50";
    $timeDelay = $newTime >= $minTimeDelay ? $newTime : $minTimeDelay;
}
sub CreateText{
    my ($y, $x, $text) = @_;
    my $label = $canvas->Label(-text => $text, -background => 'black', -foreground => "white", -font => $code_font, -relief => 'raised');
    $canvas->createWindow($x * $boxSize, $y *  $boxSize, -window => $label, -tags => "texts");
}
sub ParseBoolean{
    ClearGame;
    if($boolOperator eq 'OR'){
        $grid->CreateSEGun(8, 1);
        $grid->CreateSEGun(9, 43) if $boolA;
        $grid->CreateSEGun(8, 97) if $boolB;
        $grid->CreateSWGun(7, 142);
        CreateText(4, 65, "A");
        CreateText(4, 120, "B");
        CreateText($yLength, 87, "Output");
    }
    elsif ($boolOperator eq 'AND'){
        $grid->CreateSEGun(10, 1) if $boolA;
        $grid->CreateSEGun(9, 55) if $boolB;
        $grid->CreateSWGun(8, 100);
        CreateText(4, 25, "A");
        CreateText(4, 80, "B");
        CreateText($yLength - 20, 80, "Output");
    }
    elsif ($boolOperator eq 'NOT'){
        $grid->CreateSEGun(10, 1);
        $grid->CreateSWGun(9, 46) if $boolB;
        CreateText(4, 70, "B");
        CreateText(70, 70, "Output");
    }
    UpdateGame;
}
sub StartGame{
    $grid->ResetCurrentGrid();
    $grid->AdaptRange;
    $window = MainWindow->new(-title => $windowTitle);
    $window->resizable(0,0);
    $code_font = $window->fontCreate('code', -family => 'calibri', -size => 15);
    my $mainFrame = $window->Frame()->pack(-side => 'top', -fill => 'x');
    my $leftFrame = $mainFrame->Frame(-background => "black", -borderwidth => 5, -relief => 'raised')->pack(-side => 'left', -fill => 'both');
    $leftFrame->Button(-text => "Back", -font => $code_font, -command => sub{
        exec("perl ./GOL.pl");
    })->pack(-fill => 'x', -pady => 10);
    $leftFrame->Label(-text => "Logic Gates", -background => $lightBlue, -borderwidth => 5, -relief => 'raised', -font => $code_font)->pack(-fill => 'x');
    
    my $upperFrame = $leftFrame->Frame(-background => $lightGreen, -borderwidth => 5, -relief => 'raised')->pack(-fill => 'x');
    my $boolFrame = $upperFrame->Frame(-background => $lightGreen, )->pack(-fill => 'x');
    my $validateBoolInput = sub {
        my $a = shift @_;
        return 1 if $a eq '';
        $a =~ /^[01]$/;
    };
    my $inputA = $boolFrame->Entry(-textvariable => \$boolA, -background => 'white', -width => 1, -font => $code_font, -justify => 'center',
        -validate => 'key', -validatecommand => sub {$validateBoolInput->($_[0])})->pack(-side => 'left', -expand => 1, -padx => 3);
    my $boolOption = $boolFrame->Optionmenu(-variable => \$boolOperator, -options => [qw/OR AND NOT/], -font => $code_font, -command => sub{
        $inputA->configure(-state => $boolOperator eq 'NOT' ? 'disabled':'normal');
    })->pack(-side => 'left', -expand=> 1, -padx => 5);
    my $inputB = $boolFrame->Entry(-textvariable => \$boolB, -background => 'white', -width => 1, -font => $code_font, -justify => 'center',
        -validate => 'key', -validatecommand => sub {$validateBoolInput->($_[0])})->pack(-side => 'left', -expand => 1, -padx => 3);
    
    my $lowerFrame = $leftFrame->Frame(-background => $lightOrange, -borderwidth => 5, -relief => 'groove')->pack(-fill => 'x', -pady => 15);
    $playButton = $lowerFrame->Checkbutton(-text => "Play", -font => $code_font)->pack(-fill => 'x', -pady => 5, -padx => 5);
    $playButton->configure(-command => sub {
        $playButton->configure(-text => $isPlaying?"Play":"Pause");
        RunGame;
        $playID = $window->repeat($timeDelay, \&UpdateGame) if $isPlaying;
    });
    my $boolParseButton = $upperFrame->Button(-text => "Parse", -font => $code_font, -command => sub{
        ParseBoolean;
    })->pack(-fill => 'x', -pady => 5);

    my $resetButton = $lowerFrame->Button(-text => "Reset", -font => $code_font, -command => sub {
        ClearGame;
    })->pack(-fill => 'x', -pady => 5, -padx => 5);

    $lowerFrame->Label(-text => "Time Delay (ms)", -background => "white", -font => $code_font)->pack(-expand=> 1, -padx => 5);
    my $timeFrame = $lowerFrame->Frame(-background => "white")->pack(-fill => 'x');
    my $downTimeButton = $timeFrame->Button(-text => "-", -font => $code_font, -command => sub {ChangeTime('-')})->pack(-side => 'left', -expand => 1, -padx => 3);
    my $timeLabel = $timeFrame->Label(-textvariable => \$timeDelay, -font => $code_font)->pack(-side => 'left', -expand=> 1, -padx => 5);
    my $upTimeButton = $timeFrame->Button(-text => "+", -font => $code_font, -command => sub {ChangeTime('+')})->pack(-side => 'left', -expand => 1, -padx => 3);

    my $showRegionButton = $lowerFrame->Checkbutton(-text => $showRegion?"Hide Region":"Show Region", -font => $code_font)->pack(-fill => 'x', -pady => 5, -padx => 5);
    $showRegionButton->configure(-command => sub {
        $showRegion = !$showRegion;
        $showRegionButton->configure(-text => $showRegion?"Hide Region":"Show Region");
        UpdateGame;
    });

    my $displayTypeButton = $lowerFrame->Optionmenu(-variable => \$displayType, -options => \@displayOptions, -font => $code_font)->pack(-fill=> 'x', -pady => 5, -padx => 5);
    
    my ($xSize, $ySize) = ($xLength * $boxSize, $yLength * $boxSize);
    $canvas = $mainFrame->Canvas(-bg => "black",  -width => $xSize, -height => $ySize)->pack(-side => 'right', -pady => 10, -padx => 10, -fill => "both");
    $canvas->waitVisibility;
    glpOpenWindow(parent=> hex($canvas->id), width => $xSize, height => $ySize);
    PrintCanvasGrid;
    MainLoop;
}

StartGame;