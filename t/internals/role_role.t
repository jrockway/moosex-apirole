use strict;
use warnings;

use Test::More;
use Test::Exception;

use Scalar::Util qw(refaddr);
use MooseX::Role::FromClass::Internals qw(role_for create_role_for);

{ package Role;
  use Moose::Role;
  requires 'coffee';

  sub oh_nice_a_sub {}
}

my $rolemeta = Role->meta;

ok !role_for($rolemeta), 'no role yet';

my $role = create_role_for($rolemeta);
ok $role, 'got new role';
is refaddr $role, refaddr role_for($rolemeta), 'cache works';

is_deeply [sort $role->get_required_method_list], [sort qw/coffee oh_nice_a_sub/],
    'role role does the methods that we think it should';

ok $role->is_anon_role, 'is anon role';

lives_ok {
    $role->apply($rolemeta);
} 'applying the role role to the original role works';

lives_ok {
  package Class;
  use Moose;
  with 'Role', $role;

  sub coffee {}
} 'making a class that does Role and $role works';

my $class;
lives_ok {
    $class = Role->new
}

done_testing;
