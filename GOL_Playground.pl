#!/usr/bin/perl
use strict;
use warnings;
use Cwd qw(abs_path);
use FindBin;
use lib abs_path("$FindBin::Bin/modules");
use Getopt::Long;
use Tk;
use GOL_Grid;

$| = 1;

my $windowTitle = "Game of Life - Intel Edition";
my $xLength = 100;
my $yLength = 50;
my $boxSize = 10;
my $vicinity = 1;
my $destroyAtBorder = 0;
my $timeDelay = 50;
my $minTimeDelay = 10;

GetOptions(
    "xLength=i" => \$xLength,
    "yLength=i" => \$yLength,
    "boxSize=i" => \$boxSize,
    "vicinity=i" => \$vicinity,
    "destroyAtBorder=i" => \$destroyAtBorder,
    "timeDelay=i" => \$timeDelay
);
$timeDelay = $minTimeDelay if $timeDelay < $minTimeDelay;

my $grid = new GOL_Grid('xLength'=>$xLength, 'yLength'=>$yLength, 'boxSize'=>$boxSize, 'vicinity'=>$vicinity, 'destroyAtBorder'=>$destroyAtBorder);
my $window;
my $canvas;
my $isPlaying = 0;
my $mouseClicked = 0;
my $keyXDown = 0;
my $playID;
my $playButton;
my $presetType = "Dot";
my @presets = ("Dot", "Glider", "Dart", "SWGun", "SEGun", "Eater", "Spinner", "Ring Of Fire", "Bomb");
my $showRegion = 0;
my $displayType;
my @displayOptions = ("Both", "Canvas Only", "Terminal Only");
my $lightBlue= "#00e6ff";
my $lightOrange = "#ffae00";
my $lightRed = "#ff0008";

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
sub PrintCanvasGrid{
    foreach my $row (0 .. $yLength - 1){
        foreach my $col (0 .. $xLength - 1){
            my $currentState = $grid->GetCurrentState($row, $col, $grid->{_currentGrid});
            if($currentState){
                my @positionStart= ($col * $grid->{_boxSize}, $row * $grid->{_boxSize});
                my @positionEnd= (($col + 1) * $grid->{_boxSize}, ($row + 1) * $grid->{_boxSize});
                my $color = $currentState == $grid->GetCurrentState($row, $col, $grid->{_previousGrid}) ?'blue':'green';
                $canvas->createOval(@positionStart, @positionEnd, -fill=> $color, -tags => "points");
            }
        }
    }
    my @range = $grid->GetRange;
    if ($showRegion && defined $range[0]){
        foreach my $row ($range[2] .. $range[3]){
            my @positionStart= ($range[0] * $grid->{_boxSize}, $row * $grid->{_boxSize});
            my @positionEnd= (($range[0] + 1) * $grid->{_boxSize}, ($row + 1) * $grid->{_boxSize});
            $canvas->createOval(@positionStart, @positionEnd, -fill=> 'red', -tags => "points");
        }
        foreach my $row ($range[2] .. $range[3]){
            my @positionStart= ($range[1] * $grid->{_boxSize}, $row * $grid->{_boxSize});
            my @positionEnd= (($range[1] + 1) * $grid->{_boxSize}, ($row + 1) * $grid->{_boxSize});
            $canvas->createOval(@positionStart, @positionEnd, -fill=> 'red', -tags => "points");
        }
        foreach my $col ($range[0] .. $range[1]){
            my @positionStart= ($col * $grid->{_boxSize}, $range[2] * $grid->{_boxSize});
            my @positionEnd= (($col + 1) * $grid->{_boxSize}, ($range[2] + 1) * $grid->{_boxSize});
            $canvas->createOval(@positionStart, @positionEnd, -fill=> 'red', -tags => "points");
        }
        foreach my $col ($range[0] .. $range[1]){
            my @positionStart= ($col * $grid->{_boxSize}, $range[3] * $grid->{_boxSize});
            my @positionEnd= (($col + 1) * $grid->{_boxSize}, ($range[3] + 1) * $grid->{_boxSize});
            $canvas->createOval(@positionStart, @positionEnd, -fill=> 'red', -tags => "points");        }
    }
}
sub UpdateGame{
    if ($isPlaying){
        $grid->UpdateCurrentGrid;
    }
    else{
        $grid->AdaptRange;
    }
    $canvas->delete('points');
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
sub StartGame{
    $grid->ResetCurrentGrid();
    $grid->AdaptRange;
    $window = MainWindow->new(-title => $windowTitle);
    my $code_font = $window->fontCreate('code', -family => 'calibri', -size => 15);
    my $mainFrame = $window->Frame()->pack(-side => 'top', -fill => 'x');
    my $leftFrame = $mainFrame->Frame(-background => "black")->pack(-side => 'left', -fill => 'x');
    $leftFrame->Button(-text => "Back", -font => $code_font, -command => sub{
        exec("perl ./GOL.pl");
    })->pack(-fill => 'x', -pady => 10);
    $leftFrame->Label(-text => "Playground", -background => $lightBlue, -borderwidth => 5, -relief => 'raised', -font => $code_font)->pack(-fill => 'x');
    
    my $upperLeftFrame = $leftFrame->Frame(-background => $lightOrange, -borderwidth => 5, -relief => 'groove')->pack(-fill => 'x');
    $playButton = $upperLeftFrame->Checkbutton(-text => "Play", -font => $code_font)->pack(-fill => 'x', -pady => 5, -padx => 5);
    $playButton->configure(-command => sub {
        $playButton->configure(-text => $isPlaying?"Play":"Pause");
        RunGame;
        $playID = $window->repeat($timeDelay, \&UpdateGame) if $isPlaying;
    });
    my $resetButton = $upperLeftFrame->Button(-text => "Reset", -font => $code_font, -command => sub {
        ClearGame;
    })->pack(-fill => 'x', -pady => 5, -padx => 5);

    $upperLeftFrame->Label(-text => "Time Delay (ms)", -background => "white", -font => $code_font)->pack(-side => 'left', -expand=> 1, -padx => 5);
    my $timeFrame = $upperLeftFrame->Frame(-background => "white")->pack(-fill => 'x');
    my $downTimeButton = $timeFrame->Button(-text => "-", -font => $code_font, -command => sub {ChangeTime('-')})->pack(-side => 'left', -expand => 1, -padx => 3);
    my $timeLabel = $timeFrame->Label(-textvariable => \$timeDelay, -font => $code_font)->pack(-side => 'left', -expand=> 1, -padx => 5);
    my $upTimeButton = $timeFrame->Button(-text => "+", -font => $code_font, -command => sub {ChangeTime('+')})->pack(-side => 'left', -expand => 1, -padx => 3);

    my $midLeftFrame = $leftFrame->Frame(-background => "black", -borderwidth => 5, -relief => 'groove')->pack(-fill => 'x');
    my $presetBox = $midLeftFrame->Scrolled("Listbox", -scrollbars => "e", -selectmode => "single",
        -selectforeground => 'red', -selectbackground => 'green', -selectborderwidth => 5, -font => $code_font)->pack(-fill => 'x');
    $presetBox->insert('end', @presets);
    $presetBox->bind('<1>', sub {
        $presetType = $presetBox->get($presetBox->curselection());
    });
    $presetBox->selectionSet(0);

    my $lowerLeftFrame = $leftFrame->Frame(-background => $lightRed, -borderwidth => 5, -relief => 'groove')->pack(-fill => 'x');
    my $saveButton = $lowerLeftFrame->Button(-text => "Save", -font => $code_font, -command => sub {
        RunGame if $isPlaying;
        ResetPlayButton;
        my $filePath = $window->getSaveFile(-title => "Save current state", -initialfile => "state_file");
        if (defined $filePath){
            open(FH, '>', $filePath) or ErrorDialog('Error!', 'Failed to save file');
            print FH $xLength, $/, $yLength, $/;
            foreach my $row(0..$yLength - 1){
                foreach my $col(0..$xLength - 1){
                    print FH $grid->GetCurrentState($row, $col, $grid->{_currentGrid});
                }
                print FH $/;
            }
            close FH;
        }
    })->pack(-fill => 'x', -pady => 5, -padx => 5);
    
    my $loadButton = $lowerLeftFrame->Button(-text => "Load", -font => $code_font, -command => sub {
        RunGame if $isPlaying;
        ResetPlayButton;
        my $filePath = $window->getOpenFile(-title => "Load saved-state");
        if (defined $filePath){
            open(FH, '<', $filePath) or ErrorDialog('Error!', 'Failed to load file');
            my @lines=();
            while (my $line = <FH>) {
                push @lines, $line;
            }
            chomp @lines;
            ($xLength, $yLength) = (shift @lines, shift @lines);
            $grid = new GOL_Grid('xLength'=>$xLength, 'yLength'=>$yLength, 'boxSize'=>$boxSize, 'vicinity'=>$vicinity, 'destroyAtBorder'=>$destroyAtBorder);
            foreach my $line (0..$#lines){
                my @data = split(//, $lines[$line]);
                foreach my $col(0..$xLength - 1){
                    $grid->UpdateGridPoint($data[$col], $line, $col, $grid->{_currentGrid});
                }
            }
            UpdateGame;
            close FH;
        }
    })->pack(-fill => 'x', -pady => 5, -padx => 5);
    
    my $showRegionButton = $lowerLeftFrame->Checkbutton(-text => $showRegion?"Hide Region":"Show Region", -font => $code_font)->pack(-fill => 'x', -pady => 5, -padx => 5);
    $showRegionButton->configure(-command => sub {
        $showRegion = !$showRegion;
        $showRegionButton->configure(-text => $showRegion?"Hide Region":"Show Region");
        UpdateGame;
    });

    my $destroyBorderButton = $lowerLeftFrame->Optionmenu( -variable => \$destroyAtBorder, -font => $code_font, -command => sub {
        $grid->{_destroyAtBorder} = $destroyAtBorder;
    })->pack(-fill => 'x', -pady => 5, -padx => 5);
    my @optionName = ("Wrap Around", "Destroy At Border");
    my %first= ($optionName[!$destroyAtBorder] => !$destroyAtBorder);
    my %second= ($optionName[$destroyAtBorder] => $destroyAtBorder);
    $destroyBorderButton->addOptions([%first]);
    $destroyBorderButton->addOptions([%second]);
    
    my $displayTypeButton = $lowerLeftFrame->Optionmenu(-variable => \$displayType, -options => \@displayOptions, -font => $code_font)->pack(-fill=> 'x', -pady => 5, -padx => 5);

    my ($xSize, $ySize) = ($xLength * $boxSize, $yLength * $boxSize);
    $canvas = $mainFrame->Canvas(-width=>$xSize, -height=>$ySize, -borderwidth => 5, -relief => 'raised')->grid->pack(-side => 'right', -fill => 'x');
    $canvas->configure("-scrollregion" => [0,0, $xSize, $ySize]);
    $canvas->createGrid(0, 0, $boxSize, $boxSize);
    $canvas->focusFollowsMouse;
    my $pressedEvent = sub {
        my $clickType = shift @_;
        my ($c) = @_;
        my $event = $c->XEvent;
        my $x = int ($c->canvasx( $event->x ) / $grid->{_boxSize});
        my $y = int ($c->canvasy( $event->y ) / $grid->{_boxSize});
        if($clickType){
            $grid->SetPreset($y, $x, $presetType);
        }
        else{
            $grid->UpdateGridPoint(0, $y, $x, $grid->{_currentGrid});
        }
        RunGame if $isPlaying;
        ResetPlayButton;
        UpdateGame;
    };
    $canvas->CanvasBind('<ButtonPress>' => sub {
        $mouseClicked = 1;
        $pressedEvent->(1, @_);
    });
    $canvas->CanvasBind('<ButtonRelease>' => sub {
        $mouseClicked = 0;
    });
    $canvas->CanvasBind('<KeyPress-x>' => sub {
        $keyXDown = 1;
        $pressedEvent->(0, @_);
    });
    $canvas->CanvasBind('<KeyRelease-x>' => sub {
        $keyXDown= 0;
    });
    $canvas->CanvasBind('<Motion>' => sub {
        if($mouseClicked){
            $pressedEvent->(1, @_);
        }
        elsif($keyXDown){
            $pressedEvent->(0, @_);
        }
    });
    PrintCanvasGrid;
    MainLoop;
}
StartGame;