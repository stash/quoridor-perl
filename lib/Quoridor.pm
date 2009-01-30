package Quoridor;
use warnings;
use strict;

use Class::Field qw/field/;

=head2 Coordinates

=head3 Wall Coordinates

Each point will have either a "row" or "column" wall placed there.

      y=0 --> +-+-+-+-+-+-+-+-+-+
              |                 |
      y=1 --> + + + + + + + + + +
          x=1 --^             ^-- x=8
      y=2 --> + + + + + + + + + +
              |                 |
    ...
      y=8 --> + + + + + + + + + +
              |                 |
      y=9 --> +-+-+-+-+-+-+-+-+-+


=head3 Cell Coordinates

Cells are where player pawns are placed.

              +-+-+-+-+-+-+-+-+-+
      v=0 --> |                 |
              + + + + + + + + + +
      v=1 --> |                 |
              + + + + + + + + + +
         u=0 --^              |^-- u=8
              +-+-+-+-+-+-+-+-+-+
      ...
              +-+-+-+-+-+-+-+-+-+
      v=7 --> |                 |
              + + + + + + + + + +
      v=8 --> |                 |
              + + + + + + + + + +

=cut

field 'active_player' => 'A';

use constant U => 0;
use constant V => 1;

sub new {
    my $self = bless {},__PACKAGE__;

    $self->{walls} = [];
    $self->{walls}[0] = [(undef) x 9];
    for my $y (1 .. 7) {
        $self->{walls}[$y] = [undef, (0) x 7, undef];
    }
    $self->{walls}[8] = [(undef) x 9];

    $self->{player}{A} = {coord => [4,0], walls => 10 };
    $self->{player}{B} = {coord => [4,8], walls => 10 };

    return $self;
}

sub next_player {
    my $self = shift;
    my $active = $self->active_player();
    if (!$active) {
        $self->active_player('A');
    }
    elsif ($active eq 'A') {
        $self->active_player('B');
    }
    else {
        $self->active_player('A');
    }

    return $self->active_player;
}

sub player_at {
    my ($self, $player) = @_;
    $player ||= $self->active_player;
    return @{$self->{player}{$player}{coord}}
}

sub wall {
    my ($self, $x,$y) = @_;
    die "coordinate out of bounds\n"
        if ($x < 0 || $x > 8 || $y < 0 || $y > 8);
    return $self->{walls}[$y][$x];
}

sub place_wall {
    my ($self, $dir, $x,$y) = @_;

    die "can't place wall on edge of board\n"
        if ($x == 0 || $x == 9 || $y == 0 || $y == 9);

    my $wall = $self->wall($x,$y);
    die "already a $wall wall at ($x,$y)\n" if $wall;

    if ($dir eq 'row') {
        my $left = $self->{walls}[$y][$x-1];
        my $right = $self->{walls}[$y][$x+1];
        die "wall overlaps" if ($left or $right);
    }
    else {
        my $up = $self->{walls}[$y-1][$x];
        my $down = $self->{walls}[$y+1][$x];
        die "wall overlaps" if ($up or $down);
    }

    $self->{walls}[$y][$x] = $dir;
}

sub _place_player {
    my ($self, $u, $v) = @_;
    $self->{player}{$self->active_player}{coord} = [$u,$v];
}

sub _move_uv {
    my $move = shift;
    my ($d_u, $d_v) = (0,0);

    if ($move eq 'up')       { $d_v--; }
    elsif ($move eq 'down')  { $d_v++; }
    elsif ($move eq 'left')  { $d_u--; }
    elsif ($move eq 'right') { $d_u++; }
    else {
        die "illegal move";
    }
    return ($d_u,$d_v);
}

sub move_player {
    my ($self, $move) = @_;
    my $cur_uv = $self->{player}{$self->active_player}{coord};

    my ($d_u,$d_v) = _move_uv($move);
    my @new_uv = ($cur_uv->[U] + $d_u, $cur_uv->[V] + $d_v);

    if ($new_uv[U] < 0 || $new_uv[U] > 8 ||
        $new_uv[V] < 0 || $new_uv[V] > 8)
    {
        die "cannot move $move; edge of board";
    }
}

1;
# vim: ft=perl,sts=4,sw=4,et
