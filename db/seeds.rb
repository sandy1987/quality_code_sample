# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Create user role
%w(admin celebrity regular).each{ |role| Role.where(name: role).first_or_create! }

# Create interest categories
['Books & Literature', 'Entertainment', 'Entrepreneur', 'Fashion', 'Health & Medicine', 'Movie', 'Music', 'Politics', 'Science', 'Sport', 'Television', 'Other'].each{ |ctg| Category.where(name: ctg).first_or_create! }