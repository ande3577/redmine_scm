require 'redmine'

require_dependency 'creator/scm_creator'
require_dependency 'creator/subversion_creator'
require_dependency 'creator/mercurial_creator'
require_dependency 'creator/git_creator'
require_dependency 'creator/bazaar_creator'

require_dependency 'scm_config'
require_dependency 'scm_hook'
require_dependency 'scm_view_hook'

require_dependency File.expand_path(File.join(File.dirname(__FILE__), 'app/models/repository_observer'))

Rails.logger.info 'Starting SCM Creator Plugin for Redmine'

ActiveRecord::Base.observers << RepositoryObserver

Rails.configuration.to_prepare do
    unless Project.included_modules.include?(ScmProjectPatch)
        Project.send(:include, ScmProjectPatch)
    end
    unless RepositoriesHelper.included_modules.include?(ScmRepositoriesHelperPatch)
        RepositoriesHelper.send(:include, ScmRepositoriesHelperPatch)
    end
    unless RepositoriesController.included_modules.include?(ScmRepositoriesControllerPatch)
        RepositoriesController.send(:include, ScmRepositoriesControllerPatch)
    end
end

Redmine::Plugin.register :redmine_scm do
    project_module :repository do
      permission :delete_local_repository, :repository => :delete_local
    end
  
    name 'SCM Creator'
    author 'Andriy Lesyuk'
    author_url 'http://www.andriylesyuk.com/'
    description 'Allows creating Subversion, Git, Mercurial and Bazaar repositories using Redmine.'
    url 'http://projects.andriylesyuk.com/projects/scm-creator'
    version '0.4.2'
end
