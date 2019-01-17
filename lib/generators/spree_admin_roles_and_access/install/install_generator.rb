module SpreeAdminRolesAndAccess
  module Generators
    class InstallGenerator < Rails::Generators::Base

      class_option :auto_run_migrations, type: :boolean, default: false

      def add_javascripts
        frontend_path = 'vendor/assets/javascripts/spree/frontend/all.js'
        backend_path = 'vendor/assets/javascripts/spree/backend/all.js'
        append_file frontend_path, "\n//= require spree/frontend/spree_admin_roles_and_access\n" if File.exist?(frontend_path)
        append_file backend_path, "\n//= require spree/backend/spree_admin_roles_and_access\n" if File.exist?(backend_path)
      end

      def add_stylesheets
        frontend_path = 'vendor/assets/stylesheets/spree/frontend/all.css'
        backend_path = 'vendor/assets/stylesheets/spree/backend/all.css'
        inject_into_file frontend_path, " *= require spree/frontend/spree_admin_roles_and_access\n", before: /\*\//, verbose: true if File.exist?(frontend_path)
        inject_into_file backend_path, " *= require spree/backend/spree_admin_roles_and_access\n", before: /\*\//, verbose: true if File.exist?(backend_path)
      end

      def add_migrations
        run 'bundle exec rake railties:install:migrations FROM=spree_admin_roles_and_access'
      end

      def run_migrations
        run_migrations = options[:auto_run_migrations] || ['', 'y', 'Y'].include?(ask 'Would you like to run the migrations now? [Y/n]')
        if run_migrations
          run 'bundle exec rake db:migrate'
        else
          puts 'Skipping rake db:migrate, don\'t forget to run it!'
        end
      end
    end
  end
end
