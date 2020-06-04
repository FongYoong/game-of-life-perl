package GOLGrid;

use strict;
use warnings;

sub new {
   my $class = shift;
   my %args = @_;
   my $self = {
      _maxLength => $args{'maxLength'},
      _boxSize => $args{'boxSize'},
      _vicinity => $args{'vicinity'},
      _currentGrid => undef
   };
   bless $self, $class;
   $self->ResetCurrentGrid;
   return $self;
}
sub MakeNewGrid{
   my ($self) = @_;
   my @grid = ();
   foreach my $row(0..$self->{_maxLength} - 1){
      $grid[$row] = ([(0)x$self->{_maxLength}]);
   }
   \@grid;
}
sub ResetCurrentGrid{
   my ($self) = @_;
   $self->{_currentGrid} = $self->MakeNewGrid();
}
sub VerifyNeighbour{
   my($self, $row, $col) = @_;
   $row = 0 if $row == $self->{_maxLength};
   $col = 0 if $col == $self->{_maxLength};
   ($row, $col);
}
sub GetNeighbours{
   #undef is assigned to the middle position
   my($self, $row, $col) = @_;
   my @neighbours = ();
   foreach my $nRow ($row - $self->{_vicinity} .. $row + $self->{_vicinity}){
      foreach my $nCol ($col - 1 .. $col + 1){
         if($nRow != $row || $nCol != $col){
            my @verified = $self->VerifyNeighbour($nRow, $nCol);
            push @neighbours, [@verified];
         }
      }
   }
   @neighbours;
}
sub GetCurrentState{
   my ($self, $row, $col) = @_;
   $self->{_currentGrid}->[$row]->[$col];
}
sub GetNextState{
   my ($self, $currentState, @position) = @_;
   my @neighbours = $self->GetNeighbours(@position);
   my $liveNeighbours = 0;
   foreach my $n(@neighbours){
      $liveNeighbours += $self->GetCurrentState($n->[0], $n->[1]);
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
sub UpdateGridPoint{
   my ($self, $nextState, $row, $col, $nextGrid) = @_;
   $nextGrid->[$row]->[$col] = $nextState;
}
sub UpdateGrid{
   my ($self) = @_;
   my $nextGrid = $self->MakeNewGrid();
   foreach my $row (0 .. $self->{_maxLength} - 1){
      foreach my $col (0 .. $self->{_maxLength} - 1){
            my $currentState = $self->GetCurrentState($row, $col);
            my $nextState = $self->GetNextState($currentState, $row, $col);
            $self->UpdateGridPoint($nextState, $row, $col, $nextGrid);
      }
   }
   $self->{_currentGrid} = $nextGrid;
}

#Auxillary
sub CreateLine{
   my ($self, $row, $col, $length) = @_;
   foreach my $n($col..$col + $length - 1){
      $self->UpdateGridPoint(1, $row, $n, $self->{_currentGrid});
   }
}
sub CreateFlower{
   my ($self, $row, $col) = @_;
   $self->CreateLine($row - 1, $col, 6);
   $self->CreateLine($row, $col, 6);
   $self->CreateLine($row + 1, $col, 6);
}
sub CreateGlider{
   my ($self, $row, $col) = @_;
   $self->UpdateGridPoint(1, $row - 1, $col - 1, $self->{_currentGrid});
   $self->UpdateGridPoint(1, $row, $col, $self->{_currentGrid});
   $self->UpdateGridPoint(1, $row, $col + 1, $self->{_currentGrid});
   $self->UpdateGridPoint(1, $row + 1, $col - 1, $self->{_currentGrid});
   $self->UpdateGridPoint(1, $row + 1, $col, $self->{_currentGrid});
}

1;