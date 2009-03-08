#!perl
use Test::More tests => 9;
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
      |                                   | 4
    5 +   +   +   +   +   +   +   +   +   +
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
    5 +   +   +   +   +   +   +---b---+   +
      |               |   |               | 5
    6 +---a---+---a---a   a---a---+---a---+
      |               |   |               | 6
    7 +   +   +   +   #   #   +   +   +   +
      |                                   | 7
    8 +   +   +   +   +   +   +   +   +   +
      |                 B                 | 8
    9 +---+---+---+---+---+---+---+---+---+
      u=0 u=1   2   3   4   5   6   7   8

=cut

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
