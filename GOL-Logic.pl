#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(dirname abs_path $0) . '/GOL/modules';
use Tk;
use OpenGL;
use GOLGrid;

$| = 1;

my $windowTitle = "Game of Life - Intel Edition";
my $boxSize = 30;
my $maxLength = 10;
my $vicinity = 1;
my $destroyAtBorder = 1;
my $grid = new GOLGrid('maxLength'=>$maxLength, 'boxSize'=>$boxSize, 'vicinity'=>$vicinity, 'destroyAtBorder'=>$destroyAtBorder);
my $window;
my $canvas;
my $delay = 0.01 * 1000; #0.1 second is the minimum for 50 maxLength
my $isPlaying = 0;
my $playID;
my $presetType = "Dot";

sub PrintTerminalGrid{
    system("clear");
    print "\n";
    foreach my $row (0 .. $grid->{_maxLength} - 1){
        foreach my $col (0 .. $grid->{_maxLength} - 1){
            my $currentState = $grid->GetCurrentState($row, $col, $grid->{_currentGrid});
            $currentState? print "*" : print".";
        }
        print "\n";
    }
}
sub PrintCanvasGrid{
   foreach my $row (0 .. $grid->{_maxLength} - 1){
      foreach my $col (0 .. $grid->{_maxLength} - 1){
         my $currentState = $grid->GetCurrentState($row, $col, $grid->{_currentGrid});
         if($currentState){
            my @positionStart= ($col * $grid->{_boxSize}, $row * $grid->{_boxSize});
            my @positionEnd= (($col + 1) * $grid->{_boxSize}, ($row + 1) * $grid->{_boxSize});
            my $color = $currentState == $grid->GetCurrentState($row, $col, $grid->{_previousGrid}) ?'blue':'green';
            #$canvas->createOval(@positionStart, @positionEnd, -fill=> $color, -tags => "points");
         }
      }
   }
}
sub ErrorDialog{
    my ($title, $message) = @_;
    $window->messageBox(-title => $title, -message => $message, -type => 'Ok', -icon => 'error');
}
sub UpdateGame{
    $grid->UpdateCurrentGrid if $isPlaying;
    $canvas->delete('points');
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
    $grid->CreateLine(10, 10, 3);
    $grid->CreateFlower(3, 20);
    $grid->CreateGlider(2,5);
    $grid->CreateGlider(10,5);
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

    my $canvasSize = $grid->{_maxLength} * $grid->{_boxSize};
    $canvas = $mainFrame->Canvas(-width=>$canvasSize, -height=>$canvasSize, -borderwidth => 5, -relief => 'raised')->grid->pack(-side => 'right', -fill => 'x');
    $canvas->configure("-scrollregion" => [0,0, $canvasSize , $canvasSize]);
    $canvas->createGrid(0, 0, $grid->{_boxSize}, $grid->{_boxSize});
    
    #PrintCanvasGrid;
    MainLoop;
}
StartGame;