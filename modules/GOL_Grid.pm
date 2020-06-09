package GOL_Grid;

use strict;
use warnings;

sub new {
   my $class = shift;
   my %args = @_;
   my $self = {
      _xLength => $args{'xLength'},
      _yLength => $args{'yLength'},
      _boxSize => $args{'boxSize'},
      _vicinity => $args{'vicinity'},
      _destroyAtBorder => $args{'destroyAtBorder'},
      _currentGrid => undef,
      _previousGrid => undef,
      _iXPos => undef,
      _fXPos => undef,
      _iYPos => undef,
      _fYPos => undef
   };
   bless $self, $class;
   $self->{_currentGrid} = $self->MakeNewGrid;
   $self->{_previousGrid} = $self->MakeNewGrid;
   return $self;
}

sub MakeNewGrid{
   my ($self) = @_;
   my @grid = ();
   foreach my $row(0..$self->{_yLength} - 1){
      $grid[$row] = ([(0)x$self->{_xLength}]);
   }
   \@grid;
}
sub ResetCurrentGrid{
   my ($self) = @_;
   $self->{_currentGrid} = $self->MakeNewGrid();
}
sub RectifyPoint{
   my($self, $row, $col) = @_;
   $row = $row % $self->{_yLength} if $row >= $self->{_yLength};
   $col = $col % $self->{_xLength} if $col >= $self->{_xLength};
   ($row, $col);
}
sub ExceededBorder{
   my ($self, $row, $col) = @_;
   $col >= $self->{_xLength} || $col < 0 || $row >= $self->{_yLength} || $row < 0;
}
sub GetNeighbours{
   my($self, $row, $col) = @_;
   my @neighbours = ();
   foreach my $nRow ($row - $self->{_vicinity} .. $row + $self->{_vicinity}){
      foreach my $nCol ($col - $self->{_vicinity} .. $col + $self->{_vicinity}){
         if($nRow != $row || $nCol != $col){
            my @verified = $self->RectifyPoint($nRow, $nCol);
            if ($self->{_destroyAtBorder} && $self->ExceededBorder($nRow, $nCol)){
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
   $grid->[$row]->[$col] ? 1:0;
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
   if($self->GetRange){
      foreach my $row ($self->{_iYPos} .. $self->{_fYPos}){
         foreach my $col ($self->{_iXPos} .. $self->{_fXPos}){
            my $currentState = $self->GetCurrentState($row, $col, $grid);
            my $nextState = $self->GetNextState($currentState, $row, $col, $grid);
            $self->UpdateGridPoint($nextState, $row, $col, $nextGrid);
         }
      }
   }
   $nextGrid;
}
sub GetRange{
   my ($self) = @_;
   if(defined $self->{_iXPos} && defined $self->{_fXPos} && defined $self->{_iYPos} && defined $self->{_fYPos}){
      ($self->{_iXPos}, $self->{_fXPos}, $self->{_iYPos}, $self->{_fYPos});
   }
   else{
      (undef);
   }
}
sub AdaptRange{
   my ($self) = @_;
   my @rows = ();
   my @cols = ();
   foreach my $row (0 .. $self->{_yLength} - 1){
      foreach my $col (0 .. $self->{_xLength} - 1){
         if($self->GetCurrentState($row, $col, $self->{_currentGrid})){
            foreach my $i(-1..1){
               if ($self->{_destroyAtBorder} && $self->ExceededBorder($row + $i, $col)){
                  push @rows, $row + $i >= $self->{_yLength} ? $row : 0;
               }
               else{
                  my @r = $self->RectifyPoint($row + $i, $col);
                  push @rows, $r[0];
               }
            }
            foreach my $i(-1..1){
               if ($self->{_destroyAtBorder} && $self->ExceededBorder($row, $col + $i)){
                  push @cols, $col + $i >= $self->{_xLength} ? $col : 0;
               }
               else{
                  my @c = $self->RectifyPoint($row, $col + $i);
                  push @cols, $c[1];
               }
            }
         }
      }
   }
   ($self->{_iYPos}, $self->{_fYPos}) = (sort {$a <=> $b} @rows)[0,-1];
   ($self->{_iXPos}, $self->{_fXPos}) = (sort {$a <=> $b} @cols)[0,-1];
   print "\n$self->{_iXPos} $self->{_fXPos}";
}
sub UpdateCurrentGrid{
   my ($self) = @_;
   $self->AdaptRange;
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
sub CreateSWGun{
   #length = 36
   #place 1 up, 9 right, relative to SEGun to make gliders vanish
   my ($self, $row, $col) = @_;
   $self->CreateMatrix($row, $col,
   ([(0)x13,1],
   [(0)x12,1,0,1],
   [1,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,1,0,0,0,0,0,0,1,1],
   [1,1,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,1,0,0,0,0,1,0,1],
   [(0)x11,1,0,0,0,1,0,1,1,1,0,0,0,0,1,1,1,0,0,0,0,0,0,0,1,1],
   [(0)x12,1,0,1,0,1,1,0,0,1,0,0,0,0,1,1,1,0,0,0,0,0,0,1,1],
   [(0)x13,1,0,0,0,0,1,1,0,0,0,0,1,1,1],
   [(0)x23,1,0,1],
   [(0)x23,1,1]));
}
sub CreateSEGun{
   #length = 36
   my ($self, $row, $col) = @_;
   $self->CreateMatrix($row, $col,
   ([(0)x22, 1],
   [(0)x21,1,0,1],
   [(0)x11,1,1,(0)x6,1,1,0,0,0,1,(0)x9,1,1],
   [(0)x10,1,0,1,0,0,0,0,1,1,0,1,0,0,0,1,(0)x9,1,1],
   [1,1,(0)x7,1,1,1,0,0,0,0,1,1,1,0,1,0,0,0,1],
   [1,1,(0)x6,1,1,1,0,0,0,0,1,0,0,1,1,0,1,0,1],
   [(0)x9,1,1,1,0,0,0,0,1,1,0,0,0,0,1],
   [(0)x10,1,0,1],
   [(0)x11,1,1]));
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
      'SWGun' => \&GOL_Grid::CreateSWGun,
      'SEGun' => \&GOL_Grid::CreateSEGun,
      'Eater' => \&GOL_Grid::CreateEater,
      'Spinner' => \&GOL_Grid::CreateSpinner,
      'Flower' => \&GOL_Grid::CreateFlower,
      'default' => sub { print "\nPreset not found.\t:(\n"; exit; }
   };
   $presets->{$type} ? $presets->{$type}->($self, $row, $col) : $presets->{'default'}->();
}

1;