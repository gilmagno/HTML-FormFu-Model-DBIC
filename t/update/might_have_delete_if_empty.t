use strict;
use warnings;
use Test::More tests => 2;

use HTML::FormFu;
use lib 't/lib';
use DBICTestLib 'new_schema';
use MySchema;

my $form = HTML::FormFu->new;

$form->load_config_file('t/update/might_have_delete_if_empty.yml');

my $schema = new_schema();

my $rs      = $schema->resultset('Master');
my $note_rs = $schema->resultset('Note');

# Fake submitted form
$form->process( {
        "id"        => 3,
        "text_col"  => 'a',
        "note.note" => '',
    } );

{

    # insert some entries we'll ignore, so our rels don't have same ids
    # test id 1
    my $t1 = $rs->new_result( { text_col => 'xxx' } );
    $t1->insert;

    # test id 2
    my $t2 = $rs->new_result( { text_col => 'yyy' } );
    $t2->insert;

    # note id 1
    my $n1 = $t2->new_related( 'note', { note => 'zzz' } );
    $n1->insert;

    # should get master id 3
    my $master = $rs->new( { text_col => 'b' } );

    $master->insert;

    # should get note id 2
    my $note = $master->new_related( 'note', { note => 'abc' } );

    $note->insert;

    $form->model->update($master);
}

{
    my $row = $rs->find(3);

    is( $row->text_col, 'a' );

    my $note = $row->note;

    ok( !defined $note );
}

