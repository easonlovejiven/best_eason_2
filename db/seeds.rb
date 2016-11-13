# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

a = Core::Account.create :email => 'yuyuan1987.hu@gmail.com', :password => '123456', :password_confirmation => '123456', :user => (Core::User.create :name => '胡钰源', :sex => 'male', :birthday => '1987-2-08')
a = Core::Account.create :id => 88, :email => 'osister@owhat.cn', :password => 'Owhat0805!', :password_confirmation => 'Owhat0805!', :user => (Core::User.create :id => 88, :name => 'O妹', :sex => 'male', :birthday => '1988-5-28')
r = Manage::Role.create :creator_id => a.id, :name => '管理员', :manage_role => 127, :manage_editor => 127
Manage::Editor.create  :role_id => r.id, :creator_id => a.id, :name => '胡钰源'
