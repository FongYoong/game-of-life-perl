#!/usr/bin/perl -w

use strict;
use warnings;
use Time::HiRes qw(sleep);

$| = 1;
package Game{

    our $maxLength = 30;
    our $vicinity = 1;
    our @currentGrid=();
    our $delay = 0.1;
}

package main{
    sub NewGrid{
        my @grid = ();
        foreach my $row(0..$Game::maxLength - 1){
            $grid[$row] = ([(0)x$Game::maxLength]);
        }
        @grid;
    }
    sub VerifyNeighbour{
        my($row,$col) = @_;
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
    sub RunConway{
        system("clear");
        @Game::currentGrid = NewGrid();
        CreateFlower(3, 20);
        CreateGlider(2,5);
        CreateGlider(10,5);
        for(;;){
            PrintTerminalGrid();
            sleep($Game::delay);
            system("clear");
            my @nextGrid = NewGrid();
            foreach my $row (0 .. $Game::maxLength - 1){
                foreach my $col (0 .. $Game::maxLength - 1){
                    my $currentState = GetCurrentState($row, $col);
                    my $nextState = GetNextState($currentState, $row, $col);
                    UpdateGrid($nextState, $row, $col, @nextGrid)
                }
            }
            @Game::currentGrid = @nextGrid;
        }
    }
    RunConway();
}