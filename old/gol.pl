#!/usr/bin/perl -w

use strict;
use warnings;
use Time::HiRes qw(sleep);
use Tk;
$| = 1;

package Game{
    our $maxLength = 30;
    our $vicinity = 1;
    our @currentGrid=();
    our $delay = 0.5 * 1000;
    our $boxSize = 20;
    our $window;
    our $canvas;
    our $mouseClicked = 0;
    our $keyXDown = 0;
    our $isPlaying = 0;
    our $playID;
}

package main{
    sub MakeNewGrid{
        my @grid = ();
        foreach my $row(0..$Game::maxLength - 1){
            $grid[$row] = ([(0)x$Game::maxLength]);
        }
        @grid;
    }
    sub VerifyNeighbour{
        my($row, $col) = @_;
        $row = 0 if $row == $Game::maxLength;
        $col = 0 if $col == $Game::maxLength;
        ($row, $col);
    }
    sub GetNeighbours{
        #undef is assigned to the middle position
        my($row,$col) = @_;
        my @neighbours = ();
        foreach my $nRow ($row - $Game::vicinity .. $row + $Game::vicinity){
            foreach my $nCol ($col - 1 .. $col + 1){
                if($nRow != $row || $nCol != $col){
                    my @verified = VerifyNeighbour($nRow, $nCol);
                    push @neighbours, [@verified];
                }
            }
        }
        @neighbours;
    }

    sub GetCurrentState{
        my ($row, $col) = @_;
        $Game::currentGrid[$row]->[$col];
    }
    sub GetNextState{
        my ($currentState, @position) = @_;
        my @neighbours = GetNeighbours(@position);
        my $liveNeighbours = 0;
        foreach my $n(@neighbours){
            $liveNeighbours += GetCurrentState($n->[0], $n->[1]);
        }
        if($currentState){
            if($liveNeighbours != 3 && $liveNeighbours != 2){
                0;
            }
            else{
                1;
            }
        }
        else{
            $liveNeighbours == 3;
        }
    }
    sub UpdateGrid{
        my ($nextState, $row, $col, @nextGrid) = @_;
        $nextGrid[$row]->[$col] = $nextState;
        @nextGrid;
    }
    sub PrintTerminalGrid{
        print "\n";
        foreach my $row (0 .. $Game::maxLength - 1){
            foreach my $col (0 .. $Game::maxLength - 1){
                    my $currentState = GetCurrentState($row, $col);
                    $currentState? print "*" : print" ";
            }
            print "\n";
        }
    }
    sub PrintCanvasGrid{
        foreach my $row (0 .. $Game::maxLength - 1){
            foreach my $col (0 .. $Game::maxLength - 1){
                    my $currentState = GetCurrentState($row, $col);
                    if($currentState){
                        my @positionStart= ($col * $Game::boxSize, $row * $Game::boxSize);
                        my @positionEnd= (($col + 1) * $Game::boxSize, ($row + 1) * $Game::boxSize);
                        $Game::canvas->createOval(@positionStart, @positionEnd, -fill=> 'blue', -tags => "points");
                    }
            }
        }
    }
    sub CreateLine{
        my ($row, $col, $length) = @_;
        foreach my $n($col..$col + $length - 1){
            UpdateGrid(1, $row, $n, @Game::currentGrid);
        }
    }
    sub CreateFlower{
        my ($row, $col) = @_;
        CreateLine($row - 1, $col, 6);
        CreateLine($row, $col, 6);
        CreateLine($row + 1, $col, 6);
    }
    sub CreateGlider{
        my ($row, $col) = @_;
        UpdateGrid(1, $row - 1, $col - 1, @Game::currentGrid);
        UpdateGrid(1, $row, $col, @Game::currentGrid);
        UpdateGrid(1, $row, $col + 1, @Game::currentGrid);
        UpdateGrid(1, $row + 1, $col - 1, @Game::currentGrid);
        UpdateGrid(1, $row + 1, $col, @Game::currentGrid);
    }
    sub UpdateGame{
        $Game::canvas->delete('points');
        PrintCanvasGrid;
        my @nextGrid = MakeNewGrid();
        foreach my $row (0 .. $Game::maxLength - 1){
            foreach my $col (0 .. $Game::maxLength - 1){
                my $currentState = GetCurrentState($row, $col);
                my $nextState = $Game::isPlaying ? GetNextState($currentState, $row, $col):$currentState;
                UpdateGrid($nextState, $row, $col, @nextGrid);
            }
        }
        @Game::currentGrid = @nextGrid;
    }
    sub RunGame{
        if($Game::isPlaying){
            $Game::isPlaying = 0;
            $Game::playID->cancel;
        }
        else{
            $Game::isPlaying = 1;
            $Game::playID = $Game::window->repeat($Game::delay, \&UpdateGame) if $Game::isPlaying;
        }
    }
    sub ClearGame{
        RunGame if $Game::isPlaying;
        @Game::currentGrid = MakeNewGrid();
        UpdateGame;
    }
    sub StartGame{
        system("clear");
        @Game::currentGrid = MakeNewGrid();
        
        CreateFlower(3, 20);
        CreateGlider(2,5);
        CreateGlider(10,5);
        
        $Game::window = MainWindow->new;
        $Game::window->title("Game of Life - Intel Edition");
        my $code_font = $Game::window->fontCreate('code', -family => 'courier', -size => 20);
        my $mainFrame = $Game::window->Frame()->pack(-side => 'top', -fill => 'x');
        my $topFrame = $mainFrame->Frame(-background => "red")->pack(-side => 'top', -fill => 'x');
        $topFrame->Label(-text => "User Input", -background => "red")->pack(-side => "top");
        my $leftFrame = $mainFrame->Frame(-background => "black")->pack(-side => 'left', -fill => 'y');
        $leftFrame->Label(-text => "Playground", -background => "green", -font => $code_font)->pack(-fill => 'x');
        my $playButton = $leftFrame->Checkbutton(-text => "Play", -font => $code_font)->pack(-fill => 'x');
        $playButton->configure(-command => sub {
            $playButton->configure(-text => $Game::isPlaying?"Resume":"Pause");
            RunGame;
        });
        my $resetButton = $leftFrame->Button(-text => "Reset", -font => $code_font, -command => sub {
            $playButton->deselect;
            $playButton->configure(-text => "Play");
            ClearGame;
        })->pack(-fill => 'x');
        my $canvasSize = $Game::maxLength * $Game::boxSize;
        $Game::canvas = $mainFrame->Canvas(-width=>$canvasSize, -height=>$canvasSize)->grid->pack(-side => "right");
        $Game::canvas->configure("-scrollregion" => [0,0, $canvasSize , $canvasSize]);
        $Game::canvas->createGrid(0, 0, $Game::boxSize, $Game::boxSize);
        $Game::canvas->focusFollowsMouse;
        my $pressedEvent = sub {
            my $state = shift @_;
            my ($c) = @_;
            my $event = $c->XEvent;
            my $x = int ($c->canvasx( $event->x ) / $Game::boxSize);
            my $y = int ($c->canvasy( $event->y ) / $Game::boxSize);
            UpdateGrid($state, $y, $x, @Game::currentGrid);
            RunGame if $Game::isPlaying;
            UpdateGame;
            $playButton->deselect;
            $playButton->configure(-text => "Resume");
        };
        $Game::canvas->CanvasBind('<ButtonPress>' => sub {
            $Game::mouseClicked = 1;
            $pressedEvent->(1, @_);
        });
        $Game::canvas->CanvasBind('<ButtonRelease>' => sub {
            $Game::mouseClicked = 0;
        });
        $Game::canvas->CanvasBind('<KeyPress-x>' => sub {
            $Game::keyXDown = 1;
            $pressedEvent->(0, @_);
        });
        $Game::canvas->CanvasBind('<KeyRelease-x>' => sub {
            $Game::keyXDown = 0;
        });
        $Game::canvas->CanvasBind('<Motion>' => sub {
            if($Game::mouseClicked){
                $pressedEvent->(1, @_);
            }
            elsif($Game::keyXDown){
                $pressedEvent->(0, @_);
            }
        });
        PrintCanvasGrid;
        MainLoop;
    }
    StartGame();

}