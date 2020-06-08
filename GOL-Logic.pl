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
my $grid = new GOL_Grid('xLength'=>$xLength, 'yLength'=>$yLength, 'boxSize'=>$boxSize, 'vicinity'=>$vicinity, 'destroyAtBorder'=>$destroyAtBorder);
my $window;
my $canvas;
my $delay = 0.01 * 1000;
my $isPlaying = 0;
my $playID;

sub PrintTerminalGrid{
    system("clear");
    print "\n";
    foreach my $row (0 .. $yLength - 1){
        foreach my $col (0 .. $xLength - 1){
            my $currentState = $grid->GetCurrentState($row, $col, $grid->{_currentGrid});
            $currentState? print "*" : print".";
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
    glEnd;
    glFlush;
}
sub ErrorDialog{
    my ($title, $message) = @_;
    $window->messageBox(-title => $title, -message => $message, -type => 'Ok', -icon => 'error');
}
sub UpdateGame{
    $grid->UpdateCurrentGrid if $isPlaying;
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
sub StartGame{
    $grid->ResetCurrentGrid();
    #$grid->CreateLine(10, 10, 3);
    #$grid->CreateFlower(3, 20);
    #$grid->CreateGlider(2,5);
    #$grid->CreateGlider(10,5);
    $grid->CreateGun(10, 10);
    $window = MainWindow->new(-title => $windowTitle);
    my $code_font = $window->fontCreate('code', -family => 'courier', -size => 20);
    my $mainFrame = $window->Frame()->pack(-side => 'top', -fill => 'x');
    my $leftFrame = $mainFrame->Frame(-background => "black")->pack(-side => 'left', -fill => 'x');
    $leftFrame->Label(-text => "Logic Gates", -background => "green", -font => $code_font)->pack(-fill => 'x');
    
    my $upperLeftFrame = $leftFrame->Frame(-background => "black", -borderwidth => 5, -relief => 'groove')->pack(-fill => 'x');
    my $playButton = $upperLeftFrame->Checkbutton(-text => "Play", -font => $code_font)->pack(-fill => 'x');
    $playButton->configure(-command => sub {
        $playButton->configure(-text => $isPlaying?"Resume":"Pause");
        RunGame;
        $playID = $window->repeat($delay, \&UpdateGame) if $isPlaying;
    });
    my $resetButton = $upperLeftFrame->Button(-text => "Reset", -font => $code_font, -command => sub {
        $playButton->deselect;
        $playButton->configure(-text => "Play");
        ClearGame;
    })->pack(-fill => 'x');

    my $midLeftFrame = $leftFrame->Frame(-background => "black", -borderwidth => 5, -relief => 'groove')->pack(-fill => 'x');

    my $lowerLeftFrame = $leftFrame->Frame(-background => "black", -borderwidth => 5, -relief => 'groove')->pack(-fill => 'x');
    
    my ($xSize, $ySize) = ($xLength * $boxSize, $yLength * $boxSize);
    $canvas = $mainFrame->Frame(-bg => "black",  -width => $xSize, -height => $ySize, -borderwidth => 5, -relief => 'raised')->pack(-side => 'right', -fill => "both");
    $canvas->waitVisibility;
    glpOpenWindow(parent=> hex($canvas->id), width => $xSize, height => $ySize);
    PrintCanvasGrid;
    MainLoop;
}

StartGame;