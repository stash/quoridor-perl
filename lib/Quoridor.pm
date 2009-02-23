package Quoridor;
use Moose;
use Moose::Util::TypeConstraints;

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

use constant U => 0;
use constant V => 1;
use constant X => 0;
use constant Y => 1;

use constant MAX_UV => 8;
use constant NUM_UV => 9;
use constant MAX_XY => 9;
use constant NUM_XY => 10;

our %Starting_Coords = (
    A => [4,0],
    B => [4,8],
);
our $UNLIMITED_WALLS = 0;

subtype 'NaturalInt'
    => as 'Int'
    => where { $_ >= 0 }
    => message { "The number you provided, $_, was not a natural number" }
    ;

subtype 'Quoridor.point'
    => as 'ArrayRef[NaturalInt]'
    => where { @$_ == 2 }
    => message { "The array you provided was not a pair" }
    ;

has players => (
    is => 'ro', lazy => 1, init_arg => undef,
    isa => 'ArrayRef[Quoridor::Player]',
    builder => '_build_players',
);

has walls => (
    is => 'ro', lazy => 1, init_arg => undef,
    isa => 'ArrayRef[ArrayRef[Maybe[Quoridor::Wall]]]', # 2D array of Walls
    builder => '_build_walls'
);

sub _build_players {
    my $self = shift;
    my @players;

    my @symbols = sort keys %Starting_Coords;
    foreach my $symbol (@symbols) {
        my $coords = $Starting_Coords{$symbol};
        my $player = Quoridor::Player->new(
            name => "Player $symbol",
            symbol => $symbol,
            walls => 10,
            loc => [@$coords],
        );
        push @players, $player;
    }

    return \@players;
}

sub _build_walls {
    my @walls;
    for my $y (0 .. MAX_XY) {
        $walls[$y] = [(undef) x NUM_XY];
    }
    return \@walls;
}

sub player { return $_[0]->players->[0]; }

sub next_player {
    my $self = shift;
    my $p = $self->players;
    push @$p, shift @$p;
    return $self->player;
}

sub wall {
    my $self = shift;
    my $p = shift;
    my ($x, $y) = ref($p) ? (@$p) : ($p, shift);
    die "coordinate out of bounds\n"
        if ($x < 0 || $x > 8 || $y < 0 || $y > 8);
    return $self->_wall($x,$y);
}

sub _wall {
    my $self = shift;
    return $self->walls->[$_[Y]][$_[X]];
}

sub _wall_dir {
    my $self = shift;
    my $wall = $self->walls->[$_[Y]][$_[X]];
    return '' unless $wall;
    return $wall->dir;
}

sub place_wall {
    my $self = shift;
    my $dir = shift;
    my $p = shift;
    my ($x, $y) = ref($p) ? (@$p) : ($p, shift);

    die "can't place wall on edge of board\n"
        if ($x == 0 || $x == 9 || $y == 0 || $y == 9);

    my $wall = $self->wall($x,$y);
    die "already a ".$wall->dir." wall at ($x,$y)\n" if $wall;

    if ($dir eq 'row') {
        my $left  = $self->_wall($x-1,$y);
        my $right = $self->_wall($x+1,$y);
        die "wall overlaps" if ($left or $right);
    }
    else {
        my $up   = $self->_wall($x,$y-1);
        my $down = $self->_wall($x,$y+1);
        die "wall overlaps" if ($up or $down);
    }

    $wall = Quoridor::Wall->new(
        dir => $dir,
        loc => [$x,$y],
        placed_by => $self->player,
    );

    unless ($UNLIMITED_WALLS) {
        my $cur = $self->player->walls_remaining;
        die "no more walls" unless $cur;
        $self->player->dec_walls;
    }

    $self->walls->[$y][$x] = $wall;
    return $wall;
}

sub _place_player {
    my ($self, $u, $v) = @_;
    $self->player->loc([$u,$v]);
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

    my $loc = $self->player->loc;
    my ($u,$v) = @$loc;
    my ($d_u,$d_v) = _move_uv($move);
    my ($new_u,$new_v) = ($u+$d_u, $v+$d_v);

    if ($new_u < 0 || $new_u > 8 || $new_v < 0 || $new_v > 8) {
        die "cannot move $move; edge of board";
    }

    my $wall_ul = $self->_wall_dir($u  ,$v  );
    my $wall_ur = $self->_wall_dir($u+1,$v  );
    my $wall_dl = $self->_wall_dir($u  ,$v+1);
    my $wall_dr = $self->_wall_dir($u+1,$v+1);

    if (
        ($d_v < 0 && ($wall_ul eq 'row' || $wall_ur eq 'row')) ||
        ($d_v > 0 && ($wall_dl eq 'row' || $wall_dr eq 'row')) ||
        ($d_u < 0 && ($wall_ul eq 'col' || $wall_dl eq 'col')) ||
        ($d_u > 0 && ($wall_ur eq 'col' || $wall_dr eq 'col'))
    ) {
        die "cannot move $move; wall";
    }

    $self->player->loc([$new_u,$new_v]);
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
use Moose;
use MooseX::AttributeHelpers;

has name => (is => 'ro', isa => 'Str');
has symbol => (
    is => 'ro', isa => 'Str',
    default => sub { substr $_[0]->name,0,1 },
);
has walls_remaining => (
    metaclass => 'Counter',
    is => 'ro',
    isa => 'NaturalInt',
    default => sub { 10 },
    provides => {
        dec => 'dec_walls'
    },
);
has loc => (
    is => 'rw',
    isa => 'Quoridor.point',
    default => sub { [0,0] },
);

package Quoridor::Wall;
use Moose;
use Moose::Util::TypeConstraints;

has loc => (
    is => 'ro',
    isa => 'Quoridor.point',
    required => 1,
);
enum 'Quoridor.direction' => qw(row col);
has dir => (
    is => 'ro',
    isa => 'Quoridor.direction',
    required => 1,
);
has placed_by => (
    is => 'ro',
    isa => 'Quoridor::Player',
    weak_ref => 1,
);

1;
# vim: ft=perl,sts=4,sw=4,et
