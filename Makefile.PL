use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;

name 'App-pacoon';
all_from 'lib/App/pacoon.pm';

test_requires 'Test::More' => '0.98';

requires 'ExtUtils::Installed';
requires 'Class::Inspector';

install_script 'bin/pacoon';

author_tests('xt');
auto_set_repository();
WriteAll;
