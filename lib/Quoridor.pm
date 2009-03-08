package Quoridor;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::AttributeHelpers;
use Carp qw/carp croak/;

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

enum 'Quoridor.direction' => qw(row col);
enum 'Quoridor.move' => qw(up left down right);

has players => (
    is => 'ro', lazy => 1, init_arg => undef,
    isa => 'ArrayRef[Quoridor::Player]',
    builder => '_build_players',
);

has walls => (
    is => 'ro', lazy => 1, init_arg => undef,
    isa => 'ArrayRef[ArrayRef[Maybe[Quoridor::Wall]]]', # 2D array of Walls
    builder => '_build_walls',
);

has wall_list => (
    metaclass => 'Collection::Array',
    is => 'rw', isa => 'ArrayRef[Quoridor::Wall]', default => sub { [] },
    provides => {
        first => 'first_wall',
        last => 'last_wall',
        count => 'wall_count',
        push => '_add_wall',
    }
);

sub _build_players {
    my $self = shift;
    my @players;

    my %Starting_Coords = (
        A => [4,0],
        B => [4,MAX_UV],
    );
    my %Goal_Coords = (
        A => [ map { [$_,MAX_UV] } (0..MAX_UV) ],
        B => [ map { [$_,0]      } (0..MAX_UV) ],
    );
    # heuristic for making the 'can reach goal' case quicker when there's no
    # blocking walls.  Not strictly needed, but speeds things up a little in
    # general.
    my %DFS_Heuristic = (
        A => [reverse qw(down right left up)],
        B => [reverse qw(up left right down)],
    );

    my @symbols = sort keys %Starting_Coords;
    foreach my $symbol (@symbols) {
        my $coords = $Starting_Coords{$symbol};
        my $goals = $Goal_Coords{$symbol};
        my $player = Quoridor::Player->new(
            name => "Player $symbol",
            symbol => $symbol,
            walls => 10,
            loc => $Starting_Coords{$symbol},
            goals => $Goal_Coords{$symbol},
            dfs_heuristic => $DFS_Heuristic{$symbol},
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

sub Grid {
    my $class = shift;
    my $max = shift || MAX_UV;
    my @grid;
    for my $v (0 .. $max) {
        $grid[$v] = [(0) x ($max+1)];
    }
    return \@grid;
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
    croak "coordinate out of bounds\n"
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

    croak "can't place wall on edge of board\n"
        if ($x == 0 || $x == 9 || $y == 0 || $y == 9);

    my $wall = $self->wall($x,$y);
    croak "already a ".$wall->dir." wall at ($x,$y)\n" if $wall;

    if ($dir eq 'row') {
        my $left  = $self->_wall_dir($x-1,$y);
        my $right = $self->_wall_dir($x+1,$y);
        croak "row wall overlaps" if ($left eq 'row' or $right eq 'row');
    }
    else {
        my $up   = $self->_wall_dir($x,$y-1);
        my $down = $self->_wall_dir($x,$y+1);
        croak "col wall overlaps" if ($up eq 'col' or $down eq 'col');
    }

    $wall = Quoridor::Wall->new(
        dir => $dir,
        loc => [$x,$y],
        placed_by => $self->player,
    );

    croak "no more walls"
        unless $self->player->walls_remaining;

    $self->walls->[$y][$x] = $wall;
    unless ($self->can_all_players_reach_goal) {
        $self->walls->[$y][$x] = undef;
        croak "cannot cut off player with a wall ($dir => $x,$y)";
    }

    $self->player->dec_walls
        unless $UNLIMITED_WALLS;
    $self->_add_wall($wall);
    return $wall;
}

sub can_all_players_reach_goal {
    my $self = shift;
    foreach my $player (@{$self->players}) {
        return 0 unless $self->can_player_reach_goal($player);
    }
    return 1;
}

sub can_player_reach_goal {
    my $self = shift;
    my $player = shift;
    my $visited = $self->Grid();
    my $goal_grid = $player->goal_grid;
    my @dfs_heuristic = @{$player->dfs_heuristic};

    my @dfs_stack = ($player->loc);
    my $loops = 0;
    while (@dfs_stack) {
        $loops ++;
        my $loc = pop @dfs_stack;
        my ($u,$v) = @$loc;
        next if ($visited->[$v][$u]);
        $visited->[$v][$u] = 1;

        if ($goal_grid->[$v][$u]) {
            #Test::More::diag $player->name . " is ok, loops: $loops\n";
            #_dump_grid($visited);
            return 1;
        }

        for my $move (@dfs_heuristic) {
            my $result = $self->_check_invalid_move($loc, $move);
            push @dfs_stack, $result if ref($result);
        }
    }
    #Test::More::diag $player->name . " is cut-off, loops: $loops\n";
    #_dump_grid($visited);
    
    return 0;
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
    else { croak "illegal move"; }

    return ($d_u,$d_v);
}

sub _check_invalid_move {
    my $self = shift;
    my $loc = shift;
    my $move = shift;

    my ($u,$v) = @$loc;
    my ($d_u,$d_v) = _move_uv($move);
    my ($new_u,$new_v) = ($u+$d_u, $v+$d_v);

    if ($new_u < 0 || $new_u > 8 || $new_v < 0 || $new_v > 8) {
        return "cannot move $move; edge of board";
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
        return "cannot move $move; wall";
    }

    return [$new_u,$new_v];
}

sub move_player {
    my ($self, $move) = @_;

    my $loc = $self->player->loc;
    my $result = $self->_check_invalid_move($loc, $move);
    croak $result unless ref $result;
    $self->player->loc($result);

    my @other_players = grep { $_ != $self->player } @{$self->players};
    if (grep {$_->loc->[U] == $result->[U] && 
              $_->loc->[V] == $result->[V]    } @other_players)
    {
        # Jumping:
        # Move in a straight line unless blocked by wall or edge.
        # If blocked, move again.
        #
        # Rules are ambiguous as to how the edge of the board behaves (is
        # jumping over a pawn towards an edge an illegal move?).
        #
        # TODO: jumps are blocked by pawns in addition to walls and edges
        # when more than 2 players are playing.
        # Refactor to return legal moves, error if no legal moves (dead-end).
        my $jump = $self->_check_invalid_move($self->player->loc, $move);
        if (ref $jump) {
            $self->player->loc($jump);
        }
        else {
            return 'move again';
        }
    }
    return;
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

sub _dump_grid {
    my $grid = shift;
    Test::More::diag "[\n";
    for my $v (0 .. MAX_UV) {
        Test::More::diag "\t".join('',@{$grid->[$v]})."\n";
    }
    Test::More::diag "]\n";
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
        dec => 'dec_walls',
    },
);
has loc => (
    is => 'rw',
    isa => 'Quoridor.point',
    default => sub { [0,0] },
);
has goals => (
    is => 'ro',
    isa => 'ArrayRef[Quoridor.point]',
    required => 1,
);
has goal_grid => (
    is => 'ro',
    isa => 'ArrayRef[ArrayRef[Bool]]',
    init_arg => undef,
    lazy => 1,
    builder => '_build_goal_grid',
);
has dfs_heuristic => (
    is => 'ro',
    isa => 'ArrayRef[Quoridor.move]',
    required => 1,
);

sub _build_goal_grid {
    my $self = shift;
    my $grid = Quoridor->Grid();
    for my $goal (@{$self->goals}) {
        my ($u,$v) = @$goal;
        $grid->[$v][$u] = 1;
    }
    return $grid;
}

package Quoridor::Wall;
use Moose;
use Moose::Util::TypeConstraints;

has loc => (
    is => 'ro',
    isa => 'Quoridor.point',
    required => 1,
);
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
