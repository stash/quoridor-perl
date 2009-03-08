#!perl
use Test::More tests => 59;
use Test::Exception;
use warnings FATAL => 'all';
use strict;

use_ok 'Quoridor';

=pod

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
      |                 B'                | 4
    5 +   +   +   +   +   +   +   +   +   +
      |               |   |               | 5
    6 +---a---+---a---a   a---a---+---a---+
      |               |   |               | 6
    7 +   +   +   +   +   +   +   +   +   +
      |                 A'                | 7
    8 +   +   +   +   +   +   +   +   +   +
      |                 B                 | 8
    9 +---+---+---+---+---+---+---+---+---+
      u=0 u=1   2   3   4   5   6   7   8

=cut

easy: {
    my $q = Quoridor->new();
    $q->place_wall(row => 1,6);
    $q->place_wall(row => 3,6);
    $q->place_wall(col => 4,6);
    $q->place_wall(col => 5,6);
    $q->place_wall(row => 6,6);
    $q->place_wall(row => 8,6);

    is $q->player->walls_remaining, 4, 'test test: walls remaining';
    is_deeply $q->player->loc, [4,0], 'player A is where we expect';

    throws_ok {
        $q->place_wall(row => 4,7);
    } qr/cannot cut off player/, 'cut-off';

    is $q->wall(4,7), undef;
    is $q->player->walls_remaining, 4, 'wall didn\'t get spent';

    $q->next_player;

    throws_ok {
        $q->place_wall(row => 4,7);
    } qr/cannot cut off player/, 'cut-off';

    is $q->wall(4,7), undef;
    is $q->player->walls_remaining, 10, 'wall didn\'t get spent';

    one_but_not_the_other: {
        is $q->player->symbol, 'B';
        $q->_place_player(4,4); # B' location above
        is_deeply $q->player->loc, [4,4], 'player B is where we expect';

        throws_ok {
            $q->place_wall(row => 4,7);
        } qr/cannot cut off player/, 'cut-off';
        $q->next_player;
        throws_ok {
            $q->place_wall(row => 4,7);
        } qr/cannot cut off player/, 'cut-off';
    }

    both_reachable: {
        is $q->player->symbol, 'A';
        $q->_place_player(4,7); # A' location above
        is_deeply $q->player->loc, [4,7], 'player A is where we expect';
        lives_ok {
            $q->place_wall(row => 4,7);
        } 'both players can reach goal';
    }
}

=pod

    x=0 x=1   2   3   4   5   6   7   8   9
  y=0 +---+---+---+---+---+---+---+---+---+
      |                 A                 | 0=v
  y=1 +   +   +   +   +   +   +   +   +   +
      |                                   | 1=v
    2 +   +   +   +   +   +   +   +   +   +
      |                                   | 2
    3 +   +   +   +   +---b---+   +   +   +
      |               |       |           | 3
    4 +   +   +   +   b   #   b   +---b---+
      |               |       |           | 4
    5 +   +   +   +   +   +   +---b---#   +
      |               |   |               | 5
    6 +---a---+---a---a   a---a---+---a---+
      |               |   |               | 6
    7 +   +   +   +   +   +   +   +   +   +
      |                                   | 7
    8 +   +   +   +   +   +   +   +   +   +
      |                 B                 | 8
    9 +---+---+---+---+---+---+---+---+---+
      u=0 u=1   2   3   4   5   6   7   8

=cut

round_the_bend: {
    my $q = Quoridor->new();
    $q->place_wall(row => 1,6);
    $q->place_wall(row => 3,6);
    $q->place_wall(col => 4,6);
    $q->place_wall(col => 5,6);
    $q->place_wall(row => 6,6);
    $q->place_wall(row => 8,6);

    $q->next_player;
    $q->place_wall(col => 4,4);
    $q->place_wall(row => 5,3);
    $q->place_wall(col => 6,4);
    $q->place_wall(row => 7,5);
    $q->place_wall(row => 8,4);

    throws_ok {
        $q->place_wall(col => 5,4);
    } qr/cannot cut off player/, 'cut-off';
    $q->next_player;
    throws_ok {
        $q->place_wall(col => 5,4);
    } qr/cannot cut off player/, 'cut-off';


    throws_ok {
        $q->place_wall(col => 8,5);
    } qr/cannot cut off player/, 'cut-off';
    $q->next_player;
    throws_ok {
        $q->place_wall(col => 8,5);
    } qr/cannot cut off player/, 'cut-off';

}

=pod

    x=0 x=1   2   3   4   5   6   7   8   9
  y=0 +---+---+---+---+---+---+---+---+---+
      |       |               |         A | 0=v
  y=1 +   +   o---o---+---o---o   +---o---+
      |       |               |           | 1=v
    2 +---o---+   +   +---o---+   #   #   +
      |       |       |       |           | 2
    3 +   +   o   +   o   +   o---o---+   +
      |   |   |   |   |   |   |           | 3
    4 +   o   +   o   +   o   +   +---o---+
      |   |   |   |   |   |   |           | 4
    5 +   +   o   +   o   #   o---o---+   +
      |   |   |   |   |   |   |           | 5
    6 +   o   +   o   +   o   +   +---o---+
      |   |   |   |       |   |           | 6
    7 +   +   o   +   +   +   o---o---+   +
      |   |   |   |   |   |   |           | 7
    8 +   o   +   o   o   o   +   #   #   +
      | B |       |   |   |               | 8
    9 +---+---+---+---+---+---+---+---+---+
      u=0 u=1   2   3   4   5   6   7   8

=cut

hairball: {
    local $Quoridor::UNLIMITED_WALLS = 1;
    my $q = Quoridor->new();
    $q->_place_player(8,0);
    is_deeply $q->player->loc, [8,0], 'A in top right';
    ok $q->can_player_reach_goal($q->player);
    $q->next_player;

    $q->_place_player(0,8);
    is_deeply $q->player->loc, [0,8], 'B in bottom left';
    ok $q->can_player_reach_goal($q->player);
    $q->next_player;

    my @wall_placements = qw(
        row 1 2  col 1 4  col 1 6  col 1 8
        col 2 1  col 2 3  col 2 5  col 2 7
        row 3 1  col 3 4  col 3 6  col 3 8
        col 4 3  col 4 5  col 4 8
        row 5 1  row 5 2  col 5 4  col 5 6  col 5 8
        col 6 1  col 6 3  col 6 5  col 6 7
        row 7 3  row 7 5  row 7 7
        row 8 1  row 8 4  row 8 6
    );
    while (my @p = splice(@wall_placements,0,3)) {
        lives_ok { $q->place_wall(@p) } "place ".join(' ',@p);
    }

    dies_ok {
        $q->place_wall(row => 5,5);
    } 'blocks B at 5,5';

    dies_ok {
        $q->place_wall(col => 7,8);
    } 'blocks B at 7,8';

    dies_ok {
        $q->place_wall(col => 8,8);
    } 'blocks B at 8,8';

    dies_ok {
        $q->place_wall(col => 7,2);
    } 'blocks A at 7,2';

    dies_ok {
        $q->place_wall(col => 8,2);
    } 'blocks A at 8,2';
}
