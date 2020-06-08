package GOL_Grid;

use strict;
use warnings;

sub new {
   my $class = shift;
   my %args = @_;
   my $self = {
      _maxLength => $args{'maxLength'},
      _boxSize => $args{'boxSize'},
      _vicinity => $args{'vicinity'},
      _destroyAtBorder => $args{'destroyAtBorder'},
      _currentGrid => undef,
      _previousGrid => undef
   };
   bless $self, $class;
   $self->{_currentGrid} = $self->MakeNewGrid;
   $self->{_previousGrid} = $self->MakeNewGrid;
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
sub RectifyPoint{
   my($self, $row, $col) = @_;
   $row = $row % $self->{_maxLength} if $row >= $self->{_maxLength};
   $col = $col % $self->{_maxLength} if $col >= $self->{_maxLength};
   ($row, $col);
}
sub GetNeighbours{
   my($self, $row, $col) = @_;
   my @neighbours = ();
   foreach my $nRow ($row - $self->{_vicinity} .. $row + $self->{_vicinity}){
      foreach my $nCol ($col - $self->{_vicinity} .. $col + $self->{_vicinity}){
         if($nRow != $row || $nCol != $col){
            my @verified = $self->RectifyPoint($nRow, $nCol);
            if ($self->{_destroyAtBorder} && ($nCol >= $self->{_maxLength} || $nCol < 0 || $nRow >= $self->{_maxLength} || $nRow < 0)){
               $verified[2] = 1;
            }
            push @neighbours, [@verified];
         }
      }
   }
   @neighbours;
}
sub GetCurrentState{
   my ($self, $row, $col, $grid) = @_;
   $grid->[$row]->[$col];
}
sub GetNextState{
   my ($self, $currentState, $row, $col, $grid) = @_;
   my @neighbours = $self->GetNeighbours($row, $col);
   my $liveNeighbours = 0;
   foreach my $n(@neighbours){
      $liveNeighbours += $self->GetCurrentState($n->[0], $n->[1], $grid) if !defined $n->[2];
   }
   if($currentState){
      !($liveNeighbours != 2 && $liveNeighbours != 3);
   }
   else{
      $liveNeighbours == 3;
   }
}
sub UpdateGridPoint{
   my ($self, $nextState, $row, $col, $grid) = @_;
   $grid->[$row]->[$col] = $nextState;
}
sub UpdateGrid{
   my ($self, $grid) = @_;
   my $nextGrid = $self->MakeNewGrid;
   foreach my $row (0 .. $self->{_maxLength} - 1){
      foreach my $col (0 .. $self->{_maxLength} - 1){
         my $currentState = $self->GetCurrentState($row, $col, $grid);
         my $nextState = $self->GetNextState($currentState, $row, $col, $grid);
         $self->UpdateGridPoint($nextState, $row, $col, $nextGrid);
      }
   }
   $nextGrid;
}
sub UpdateCurrentGrid{
   my ($self) = @_;
   $self->{_previousGrid} = $self->{_currentGrid};
   $self->{_currentGrid} = $self->UpdateGrid($self->{_currentGrid});
}

sub CreateDot{
   my ($self, $row, $col) = @_;
   $self->CreateMatrix($row, $col, ([1]));
}
sub CreateLine{
   my ($self, $row, $col, $length) = @_;
   foreach my $n($col..$col + $length - 1){
      $self->CreateDot($row, $n);
   }
}
sub CreateGlider{
   my ($self, $row, $col) = @_;
   $self->CreateMatrix($row, $col,
   ([0, 1],
   [0, 0, 1],  
   [1, 1, 1]));
}
sub CreateGun{
   my ($self, $row, $col) = @_;
   $self->CreateMatrix($row, $col,
   ([0,0,0,0,0,0,0,0,0,0,0,0,0,1],
   [0,0,0,0,0,0,0,0,0,0,0,0,1,0,1],
   [1,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,1,0,0,0,0,0,0,1,1],
   [1,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,1,0,0,0,0,1,0,1],
   [0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,1,1,0,0,0,0,1,1,1,0,0,0,0,0,0,0,1,1],
   [0,0,0,0,0,0,0,0,0,0,0,0,1,0,1,0,1,1,0,0,1,0,0,0,0,1,1,1,0,0,0,0,0,0,1,1],
   [0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,1,1,0,0,0,0,1,1,1],
   [(0)x23,1,0,1],
   [(0)x23,1,1]));
}
sub CreateEater{
   my ($self, $row, $col) = @_;
   $self->CreateMatrix($row, $col,
   ([1, 1],
   [1, 0, 1],
   [0, 0, 1],
   [0, 0, 1, 1]));
}
sub CreateSpinner{
   my ($self, $row, $col) = @_;
   $self->CreateMatrix($row, $col, ([1,1,1]));
}
sub CreateFlower{
   my ($self, $row, $col) = @_;
   $self->CreateLine($row - 1, $col, 6);
   $self->CreateLine($row, $col, 6);
   $self->CreateLine($row + 1, $col, 6);
}

sub CreateMatrix{
   my ($self, $row, $col, @matrix) = @_;
   foreach my $nRow(0..$#matrix){
      foreach my $nCol(0..scalar @{$matrix[$nRow]} - 1){
         my ($y, $x) = $self->RectifyPoint($row + $nRow, $col + $nCol);
         my $state = $matrix[$nRow]->[$nCol];
         $self->UpdateGridPoint($state, $y, $x, $self->{_currentGrid});
         $self->UpdateGridPoint($state, $y, $x, $self->{_previousGrid});
      }
   }
}

sub SetPreset{
   my ($self, $row, $col, $type) = @_;
   my $presets = {
      'Dot' => \&GOL_Grid::CreateDot,
      'Glider' => \&GOL_Grid::CreateGlider,
      'Gun' => \&GOL_Grid::CreateGun,
      'Eater' => \&GOL_Grid::CreateEater,
      'Spinner' => \&GOL_Grid::CreateSpinner,
      'Flower' => \&GOL_Grid::CreateFlower,
      'default' => sub { print "\nPreset not found.\t:(\n"; exit; }
   };
   $presets->{$type} ? $presets->{$type}->($self, $row, $col) : $presets->{'default'}->();
}

1;