#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(dirname abs_path $0) . '/GOL/modules';
use Tk;
use GOL_Grid;

$| = 1;

my $windowTitle = "Game of Life - Intel Edition";
my $boxSize = 10;
my $maxLength = 50;
my $vicinity = 1;
my $destroyAtBorder = 0;
my $grid = new GOL_Grid('maxLength'=>$maxLength, 'boxSize'=>$boxSize, 'vicinity'=>$vicinity, 'destroyAtBorder'=>$destroyAtBorder);
my $window;
my $canvas;
my $delay = 0.05 * 1000; #0.1 second is the minimum for 50 maxLength
my $isPlaying = 0;
my $mouseClicked = 0;
my $keyXDown = 0;
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
            $canvas->createOval(@positionStart, @positionEnd, -fill=> $color, -tags => "points");
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
    #my $topFrame = $mainFrame->Frame(-background => "red")->pack(-side => 'top', -fill => 'x');
    #my $topLabel = $topFrame->Label(-text => "Grid Input", -background => "red")->pack(-side => "top");
    my $leftFrame = $mainFrame->Frame(-background => "black")->pack(-side => 'left', -fill => 'x');
    $leftFrame->Label(-text => "Playground", -background => "green", -font => $code_font)->pack(-fill => 'x');
    
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
    my $presetBox = $midLeftFrame->Scrolled("Listbox", -scrollbars => "e", -selectmode => "single",
    -selectforeground => 'red', -selectbackground => 'green', -selectborderwidth => 5, -font => $code_font)->pack(-fill => 'x');
    $presetBox->insert('end', qw/Dot Glider Gun Eater Spinner Flower/);
    $presetBox->bind('<1>', sub {
        $presetType = $presetBox->get($presetBox->curselection());
    });
    $presetBox->selectionSet(0);

    my $lowerLeftFrame = $leftFrame->Frame(-background => "black", -borderwidth => 5, -relief => 'groove')->pack(-fill => 'x');
    my $saveButton = $lowerLeftFrame->Button(-text => "Save", -font => $code_font, -command => sub {
        RunGame if $isPlaying;
        my $filePath = $window->getSaveFile(-title => "Save current state", -initialfile => "state_file");
        if (defined $filePath){
            truncate $filePath, 0;
            open(FH, '>>', $filePath) or ErrorDialog('Error!', 'Failed to save file');
            foreach my $row(0..$maxLength - 1){
                foreach my $col(0..$maxLength - 1){
                    print FH $grid->GetCurrentState($row, $col, $grid->{_currentGrid});
                }
            }
            close FH;
        }
    })->pack(-fill => 'x');
    my $loadButton = $lowerLeftFrame->Button(-text => "Load", -font => $code_font, -command => sub {
        RunGame if $isPlaying;
        my $filePath = $window->getOpenFile(-title => "Load saved-state");
        if (defined $filePath){
            open(FH, '<', $filePath) or ErrorDialog('Error!', 'Failed to load file');
            my @data = split(//, <FH>);
            $maxLength = sqrt scalar @data;
            $grid = new GOL_Grid('maxLength'=>$maxLength, 'boxSize'=>$boxSize, 'vicinity'=>$vicinity, 'destroyAtBorder'=>$destroyAtBorder);
            foreach my $row(0..$maxLength - 1){
                foreach my $col(0..$maxLength - 1){
                    $grid->UpdateGridPoint($data[$row * $maxLength + $col], $row, $col, $grid->{_currentGrid});
                }
            }
            UpdateGame;
            close FH;
        }
    })->pack(-fill => 'x');

    my $canvasSize = $grid->{_maxLength} * $grid->{_boxSize};
    $canvas = $mainFrame->Canvas(-width=>$canvasSize, -height=>$canvasSize, -borderwidth => 5, -relief => 'raised')->grid->pack(-side => 'right', -fill => 'x');
    $canvas->configure("-scrollregion" => [0,0, $canvasSize , $canvasSize]);
    $canvas->createGrid(0, 0, $grid->{_boxSize}, $grid->{_boxSize});
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
        UpdateGame;
        $playButton->deselect;
        $playButton->configure(-text => "Resume");
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