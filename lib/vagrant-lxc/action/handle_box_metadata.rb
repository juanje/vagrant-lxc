module Vagrant
  module LXC
    module Action
      # Prepare arguments to be used for lxc-create
      class HandleBoxMetadata
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::lxc::action::handle_box_metadata")
        end

        def call(env)
          @env = env
          @box = @env[:machine].box

          @env[:ui].info I18n.t("vagrant.actions.vm.import.importing",
                                :name => @env[:machine].box.name)

          @logger.debug 'Validating box contents'
          validate_box

          @logger.debug 'Setting box options on environment'
          @env[:lxc_template_opts] = template_opts
          @env[:lxc_template_src]  = template_src

          @app.call env
        end

        def template_src
          @template_src ||= @box.directory.join('lxc-template').to_s
        end

        def template_opts
          @template_opts ||= @box.metadata.fetch('template-opts', {}).dup.merge!(
            '--tarball'  => rootfs_tarball,
            '--auth-key' => Vagrant.source_root.join('keys', 'vagrant.pub').expand_path.to_s
          )
        end

        def rootfs_tarball
          @rootfs_tarball ||= @box.directory.join('rootfs.tar.gz').to_s
        end

        def validate_box
          if @box.metadata.fetch('version').to_i != 2
            raise Errors::InvalidBoxVersion.new name: @box.name
          end

          unless File.exists?(template_src)
            raise Errors::TemplateFileMissing.new name: @box.name
          end

          unless File.exists?(rootfs_tarball)
            raise Errors::RootFSTarballMissing.new name: @box.name
          end
        end
      end
    end
  end
end
