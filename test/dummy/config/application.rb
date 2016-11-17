require File.expand_path('../boot', __FILE__)

require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

Kernel.silence_warnings do
  Bundler.require(*Rails.groups)
end

require 'kadmin'

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Europe/Berlin'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    config.autoload_paths += %W(#{config.root}/lib)

    config.watchable_dirs['lib'] = [:rb, :erb]
    config.watchable_dirs['../../app'] = [:rb, :erb]

    # Add all paths from the lib directory
    config.watchable_dirs['../../lib'] = [:rb, :erb]
    Dir['../../lib/**/*'].each do |file_or_dir|
      config.watchable_files << file_or_dir if File.file?(file_or_dir)
    end
  end
end
