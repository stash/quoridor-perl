package Quoridor;
use warnings;
use strict;

use Class::Field qw/field/;

=head2 Coordinates

The x/y coordinate system denotes the points (between which walls can be
placed)

The u/v coordinate system is for addressing cells (where pawns can be
placed).

A,B,C,D are the starting positions

    x=0 x=1   2   3   4   5   6   7   8   9
  y=0 +---+---+---+---+---+---+---+---+---+
      |                 A                 | 0=v
  y=1 +   +   +   +   +   +   +   +   +   +
      |                                   | 1=v
    2 +   +   +   +   +   +   +   +   +   +
      |                                   | 2
    3 +   +   +   +   +   +   +   +   +   +
      |                                   | 3
    4 +   +   +   +   +   +   +   +   +   +
      | C                               D | 4
    5 +   +   +   +   +   +   +   +   +   +
      |                                   | 5
    6 +   +   +   +   +   +   +   +   +   +
      |                                   | 6
    7 +   +   +   +   +   +   +   +   +   +
      |                                   | 7
    8 +   +   +   +   +   +   +   +   +   +
      |                 B                 | 8
    9 +---+---+---+---+---+---+---+---+---+
      u=0 u=1   2   3   4   5   6   7   8

=cut

field 'active_player' => 'A';
field 'players' => {};

use constant U => 0;
use constant V => 1;

use constant MAX_UV => 8;
use constant NUM_UV => 9;
use constant MAX_XY => 9;
use constant NUM_XY => 10;

our %Starting_Coords = (
    A => [4,0],
    B => [4,8],
);

our $UNLIMITED_WALLS = 0;

sub new {
    my $self = bless {},__PACKAGE__;

    my @walls;
    for my $y (0 .. MAX_XY) {
        $walls[$y] = [('') x NUM_XY];
    }
    $self->{walls} = \@walls;

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
    my ($d_u,$d_v) = (0,0);

    if    ($move eq 'up')    { $d_v--; }
    elsif ($move eq 'down')  { $d_v++; }
    elsif ($move eq 'left')  { $d_u--; }
    elsif ($move eq 'right') { $d_u++; }
    else { die "illegal move"; }

    return ($d_u,$d_v);
}

sub move_player {
    my ($self, $move) = @_;

    my ($u,$v) = $self->cur_player->pos;
    my ($d_u,$d_v) = _move_uv($move);
    my $new_u = $u + $d_u;
    my $new_v = $v + $d_v;

    if ($new_u < 0 || $new_u > 8 || $new_v < 0 || $new_v > 8) {
        die "cannot move $move; edge of board";
    }

    my $wall_ul = $self->{walls}[$v  ][$u  ];
    my $wall_ur = $self->{walls}[$v  ][$u+1];
    my $wall_dl = $self->{walls}[$v+1][$u  ];
    my $wall_dr = $self->{walls}[$v+1][$u+1];

    if (
        ($d_v < 0 && ($wall_ul eq 'row' || $wall_ur eq 'row')) ||
        ($d_v > 0 && ($wall_dl eq 'row' || $wall_dr eq 'row')) ||
        ($d_u < 0 && ($wall_ul eq 'col' || $wall_dl eq 'col')) ||
        ($d_u > 0 && ($wall_ur eq 'col' || $wall_dr eq 'col'))
    ) {
        die "cannot move $move; wall";
    }

    $self->cur_player->pos($new_u,$new_v);
}

sub _dump_walls {
    my $self = shift;
    for my $y (0 .. MAX_XY) {
        for my $x (0 .. MAX_XY) {
            printf '[%3s]',$self->{walls}[$y][$x];
        }
        print "\n";
    }
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
