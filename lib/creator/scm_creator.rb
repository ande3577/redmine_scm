class SCMCreator

    class << self

        # returns config id used in scm.yml and ScmConfig
        def scm_id
            if self.name =~ %r{^(.+)Creator$}
                $1.downcase
            else
                nil
            end
        end

        # returns true if SCM is enabled
        def enabled?
            false
        end

        # returns configuration from scm.yml
        def options
            @options ||= ScmConfig[scm_id]
        end

        # returns local path used to access repository locally (with optional /.git/ etc)
        def access_url(path)
            if options['append']
                if Redmine::Platform.mswin?
                    "#{access_root_url(path)}\\#{options['append']}"
                else
                    "#{access_root_url(path)}/#{options['append']}"
                end
            else
                access_root_url(path)
            end
        end

        # returns local path used to access repository locally
        def access_root_url(path)
            path
        end

        # returns local path
        def path(identifier, repository_id = nil)
            if Redmine::Platform.mswin?
                # Assuming path is in Windows style (contains \'s)
                p = "#{options['path']}\\#{identifier}"
            else
                p = "#{options['path']}/#{identifier}"
            end
            p += "." + repository_id unless repository_id.nil? or repository_id.empty?
            p
        end

        # returns url which can used to access the repository externally
        def external_url(name, regexp = %r{^https?://})
            if options['url'] =~ regexp
                url = "#{options['url']}/#{name}"
            else
                url = "#{Setting.protocol}://#{Setting.host_name}/#{options['url']}/#{name}"
            end
        end

        # constructs default path using project identifier
        def default_path(identifier, repository_id = nil)
            path(identifier, repository_id)
        end
        
        def fetch_url(path)
          if(options['path'] && options['url'])
            base_path = options['path']
            if !base_path.end_with?("/")
              base_path += "/"
            end
            fetch_url = path.sub!(base_path, options['url'] + "/")
          end
        end

        # extracts repository name from path
        def repository_name(path)
            base = Redmine::Platform.mswin? ? options['path'].gsub(%r{\\}, "/") : options['path']
            matches = Regexp.new("^#{Regexp.escape(base)}/([^/]+)/?$").match(path)
            matches ? matches[1] : nil
        end

        # compares repository names (was created for multiple repositories support)
        def belongs_to_project?(name, identifier)
            name =~ %r{^#{Regexp.escape(identifier)}(\..+)?$}
        end

        # returns format of repository path which is displayed in the form as a default value
        def repository_format(label)
            path = Redmine::Platform.mswin? ? options['path'].gsub(%r{\\}, "/") : options['path']
            "#{path}/<#{label}>/"
        end

        # checks if repository already exists (was created for Git which can add .git extension)
        def repository_exists?(identifier)
            File.directory?(default_path(identifier))
        end

        # creates repository
        def create_repository(path)
            false
        end

        # copies hooks (obsolete)
        def copy_hooks(path)
            if options['hooks']
                Rails.logger.error "Option 'hooks' is obsolete - use 'post_create' instead. See: http://projects.andriylesyuk.com/issues/1886."
                #if File.directory?(options['hooks'])
                #    args = [ '/bin/cp', '-aR' ]
                #    args += Dir.glob("#{options['hooks']}/*")
                #    args << "#{path}/hooks/"
                #    system(*args)
                #else
                #    Rails.logger.error "Hooks directory #{options['hooks']} does not exist."
                    false
                #end
            else
                true
            end
        end

        # executes custom scripts
        def execute(script, path, project)
            if File.executable?(script)
                project.custom_field_values.each do |custom_value|
                    name = custom_value.custom_field.name.gsub(%r{[^a-z0-9]+}i, '_').upcase
                    ENV["SCM_CUSTOM_FIELD_#{name}"] = custom_value.value unless name.empty?
                end
                system(script, path, scm_id, project.identifier)
            else
                Rails.logger.warn "cannot find/execute: #{script}"
            end
        end

        # initializes required properties of repository (used for Bazaar which requires log_encoding)
        def init_repository(repository)
        end

    private

        def append_options(args)
            if options['options']
                if options['options'].is_a?(Array)
                    args += options['options']
                else
                    args << options['options']
                end
            end
	    return args
        end

    end

end
