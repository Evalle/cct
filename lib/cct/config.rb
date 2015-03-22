require 'erb'
require 'yaml'

module Cct
  class Config
    DIR = 'config'
    EXT = '.yml'
    DEFAULT_FILE = 'default.yml'
    DEVELOPMENT_FILE = 'development.yml'

    attr_reader :content

    attr_reader :files

    attr_reader :dir

    def initialize
      @dir = Cct.root.join(DIR)
      @files = []
      @content = load_default_config
      load_devel_config
    end

    def [](config_value)
      return content[config_value] if content[config_value]

      abort "Your current config does not include root element '#{config_value}'"
    end

    def merge! filename
      filename << EXT unless filename.to_s.match(/.#{EXT}$/)
      config_file = dir.join(filename)
      files << config_file
      @content = content.deep_merge!(load_content(config_file))
    end

    private

    def load_devel_config
      devel_config = dir.join(DEVELOPMENT_FILE)
      return unless File.exist?(devel_config)

      merge!(devel_config)
      autoload_config_files
    end

    def load_content file
      ::YAML.load(ERB.new(File.read(file)).result) || {}
    rescue Errno::ENOENT
      abort "Configuration file '#{file}' not found"
    end

    def autoload_config_files
      return unless content['autoload_config_files']

      content['autoload_config_files'].each do |config_file|
        next if config_file.to_s.match(/\A#{DEFAULT_FILE}$/)
        next if !File.exist?(dir.join( config_file + EXT))

        merge!(config_file)
      end
    end

    def load_default_config
      default_config = dir.join(DEFAULT_FILE)
      files << default_config
      load_content(default_config.to_s)
    end
  end
end

