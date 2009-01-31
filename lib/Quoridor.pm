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
field 'players' => {};

use constant U => 0;
use constant V => 1;

our %Starting_Coords = (
    A => [4,0],
    B => [4,8],
);

our $UNLIMITED_WALLS = 0;

sub new {
    my $self = bless {},__PACKAGE__;

    $self->{walls} = [];
    $self->{walls}[0] = [(undef) x 9];
    for my $y (1 .. 7) {
        $self->{walls}[$y] = [undef, (0) x 7, undef];
    }
    $self->{walls}[8] = [(undef) x 9];

    while (my ($label, $coords) = each %Starting_Coords) {
        my $player = Quoridor::Player->new($label);
        $player->pos([@$coords]);
        $self->players->{$label} = $player;
    }

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

sub cur_player {
    my $self = shift;
    return $self->players->{$self->active_player};
}

sub player_at {
    my ($self, $label) = @_;
    $label ||= $self->active_player;
    return $self->players->{$label}->pos;
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

    unless ($UNLIMITED_WALLS) {
        my $cur = $self->cur_player->walls;
        die "no more walls" unless $cur;
        $self->cur_player->walls($cur - 1);
    }

    $self->{walls}[$y][$x] = $dir;
}

sub _place_player {
    my ($self, $u, $v) = @_;
    $self->cur_player->pos($u,$v);
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

    my ($u,$v) = $self->cur_player->pos;
    my ($d_u,$d_v) = _move_uv($move);
    $u += $d_u;
    $v += $d_v;

    if ($u < 0 || $u > 8 ||
        $v < 0 || $v > 8)
    {
        die "cannot move $move; edge of board";
    }

    $self->cur_player->pos($u,$v);
}

package Quoridor::Player;
use warnings;
use strict;

use Class::Field qw/field/;

field 'label';
field 'walls' => 10;

use constant U => 0;
use constant V => 1;

sub new {
    my $class = shift;
    my $label = shift;

    my $self = bless {}, $class;

    $self->label($label);
    $self->{pos} = [];
    return $self;
}

sub pos {
    my $self = shift;
    if (@_) {
        if (ref($_[0]) eq 'ARRAY') {
            my $pos = shift;
            $self->{pos} = [@$pos[U,V]];
        }
        else {
            $self->{pos} = [@_[U,V]];
        }
    }

    return @{$self->{pos}};
}

1;
# vim: ft=perl,sts=4,sw=4,et
