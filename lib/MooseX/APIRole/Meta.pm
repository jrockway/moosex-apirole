package MooseX::APIRole::Meta;
use Moose::Role;
use MooseX::Aliases;

use true;
use namespace::autoclean;

use MooseX::APIRole::Internals qw(create_role_for);

has 'api_role_name' => (
    reader    => 'api_role_name',
    writer    => 'set_api_role_name',
    predicate => 'has_api_role_name',
    lazy      => 1,
    builder   => '_build_api_role_name',
);

sub _build_api_role_name {
    my ($self) = @_;
    return $self->api_role->name;
}

has 'api_role' => (
    reader    => 'get_api_role',
    predicate => 'has_api_role',
    lazy      => 1,
    builder   => '_build_api_role',
);

sub api_role { goto($_[0]->can('get_api_role')) }

sub _build_api_role {
    my ($self) = @_;
    my $has_name = $self->has_api_role_name;
    my $role = $has_name ? create_role_for($self, $self->api_role_name)
                         : create_role_for($self);
    return $role;
}
