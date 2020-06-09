#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(dirname abs_path $0) . '/GOL/modules';
use Tk;
use OpenGL;
use GOL_Grid;

$| = 1;

my $windowTitle = "Game of Life - Intel Edition";
my $boxSize = 5;
my $xLength = 100;
my $yLength = 50;
my $vicinity = 1;
my $destroyAtBorder = 1;
my $showRegion = 0;
my $grid = new GOL_Grid('xLength'=>$xLength, 'yLength'=>$yLength, 'boxSize'=>$boxSize, 'vicinity'=>$vicinity, 'destroyAtBorder'=>$destroyAtBorder);
my $window;
my $canvas;
my $delay = 0.01 * 1000;
my $isPlaying = 0;
my $playID;

my @booleanList = ();
my $booleanText;

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
    PrintCanvasGrid;
    PrintTerminalGrid;
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
sub ClearGame{
   RunGame if $isPlaying;
   $grid->ResetCurrentGrid();
   UpdateGame;
}

sub ParseBoolean{
    #A,a and B,b are the 2 variables
    #The operators are !, &, |
    my ($text) = @_;
    
}
sub GenerateBoolean{
    @booleanList = ();
    #ErrorDialog("Error!", "Invalid expression") if !ParseBoolean($booleanText);
    print "\n";
    foreach my $i(0..$#booleanList){
        print "$booleanList[$i]\n";
    }

}
sub ErrorDialog{
    my ($title, $message) = @_;
    $window->messageBox(-title => $title, -message => $message, -type => 'Ok', -icon => 'error');
}
sub StartGame{
    $grid->ResetCurrentGrid();
    $grid->CreateSEGun(2, 1);
    $grid->CreateSWGun(1, 46);
    $grid->AdaptRange;
    $window = MainWindow->new(-title => $windowTitle);
    my $code_font = $window->fontCreate('code', -family => 'calibri', -size => 15);
    my $mainFrame = $window->Frame()->pack(-side => 'top', -fill => 'x');
    my $leftFrame = $mainFrame->Frame(-background => "black", -borderwidth => 5, -relief => 'raised')->pack(-side => 'left', -fill => 'x');
    $leftFrame->Label(-text => "Logic Gates", -background => "#00e6ff", -borderwidth => 5, -relief => 'raised', -font => $code_font)->pack(-fill => 'x');
    
    my $upperLeftFrame = $leftFrame->Frame(-background => "#00ffb3", -borderwidth => 5, -relief => 'raised')->pack(-fill => 'x');
    my $boolInput = $upperLeftFrame->Entry(-textvariable => \$booleanText, -background => 'white', -font => $code_font, -justify => 'center')->pack(-fill => 'x', -pady => 5);
    my $boolParseButton = $upperLeftFrame->Button(-text => "Parse", -font => $code_font, -command => \&GenerateBoolean)->pack(-fill => 'x', -pady => 5);

    my $midLeftFrame = $leftFrame->Frame(-background => "#ffae00", -borderwidth => 5, -relief => 'groove')->pack(-fill => 'x', -pady => 15);
    my $playButton = $midLeftFrame->Checkbutton(-text => "Play", -font => $code_font)->pack(-fill => 'x', -pady => 5, -padx => 5);
    $playButton->configure(-command => sub {
        $playButton->configure(-text => $isPlaying?"Resume":"Pause");
        RunGame;
        $playID = $window->repeat($delay, \&UpdateGame) if $isPlaying;
    });
    my $resetButton = $midLeftFrame->Button(-text => "Reset", -font => $code_font, -command => sub {
        $playButton->deselect;
        $playButton->configure(-text => "Play");
        ClearGame;
    })->pack(-fill => 'x', -pady => 5, -padx => 5);
    my $showRegionButton = $midLeftFrame->Checkbutton(-text => $showRegion?"Hide Region":"Show Region", -font => $code_font)->pack(-fill => 'x', -pady => 5, -padx => 5);
    $showRegionButton->configure(-command => sub {
        $showRegion = !$showRegion;
        $showRegionButton->configure(-text => $showRegion?"Hide Region":"Show Region");
        UpdateGame;
    });

    #my $lowerLeftFrame = $leftFrame->Frame(-background => "black", -borderwidth => 5, -relief => 'groove')->pack(-fill => 'x');
    
    my ($xSize, $ySize) = ($xLength * $boxSize, $yLength * $boxSize);
    $canvas = $mainFrame->Frame(-bg => "black",  -width => $xSize, -height => $ySize, -borderwidth => 5, -relief => 'raised')->pack(-side => 'right', -fill => "both");
    $canvas->waitVisibility;
    glpOpenWindow(parent=> hex($canvas->id), width => $xSize, height => $ySize);
    PrintCanvasGrid;
    MainLoop;
}

StartGame;