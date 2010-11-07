package MooseX::Role::FromClass::Internals;
use strict;
use warnings;
use true;
use Moose::Meta::Role;

use Moose::Util qw(does_role);
use Hash::Util::FieldHash qw(fieldhash);

use Sub::Exporter -setup => {
    exports => [qw/role_for create_role_for/],
};

# fieldhash so that when a class goes away, so does the role
fieldhash my %ROLE_FOR;

sub role_for {
    my $meta = shift;

    # return $meta->class_role if
    #     does_role($meta, 'MooseX::Role::FromClass::Meta::Class')
    #         && $meta->has_class_role;

    # return $meta->role_role if
    #     does_role($meta, 'MooseX::Role::FromClass::Meta::Role')
    #         && $meta->has_role_role;

    return $ROLE_FOR{$meta} if exists $ROLE_FOR{$meta};
    return;
}

sub _analyze_metaclass {
    my $meta = shift;

    my @methods = $meta->get_method_list;
    push @methods, $meta->get_required_method_list if $meta->isa('Moose::Meta::Role');

    my @roles = $meta->calculate_all_roles;

    # we do this for both classes and roles, but roles do not have superclasses
    my @superclasses = $meta->isa('Moose::Meta::Object') ? $meta->superclasses : ();

    return {
        methods      => [grep { $_ ne 'meta' } @methods],
        roles        => \@roles,
        superclasses => [grep { $_ ne 'Moose::Object' } @superclasses],
    };
}

sub _name_role_for {
    my $meta = shift;
    my $name = $meta->name;

    # this is so is_anon_role returns true.  hopefully it doesn't fuck
    # up destruction too much.
    return "Moose::Meta::Role::__ANON__::SERIAL::__AUTOGEN_FOR__::$name";
}

sub create_role_for {
    my ($meta, $name) = @_;

    # already cached?
    my $cached_role = role_for($meta);
    return $cached_role if $cached_role;

    # create and cache
    my $role = Moose::Meta::Role->create(
        $name || _name_role_for($meta),
    );
    $ROLE_FOR{$meta} = $role;

    # analyze the metaclass
    my $metainfo = _analyze_metaclass($meta);

    # any methods that this class/role requires, the new role requires
    $role->add_required_methods(@{$metainfo->{methods} || []});

    # role role role your boat, gently down the stream
    $_->apply($role) for map {
        create_role_for($_)
    } (@{$metainfo->{roles} || []}, @{$metainfo->{superclasses} || []});

    return $role;
}
