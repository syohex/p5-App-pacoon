use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;

name 'App-pacoon';
all_from 'lib/App/pacoon.pm';

author_tests('xt');
auto_set_repository();
WriteAll;
