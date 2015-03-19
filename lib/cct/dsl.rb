module Cct
  module Dsl
    def local_user
      Cct.user
    end

    def config
      Cct.config
    end

    def log
      Cct.logger
    end

    def include_config filename
      Cct.config.merge!(filename.to_s)
    end

    def invoke_task task_name
      Rake::Task[task_name].invoke
    end

    def feature_name name=nil
      name ? @feature_name = name : @feature_name
    end

    def feature_task name, options={}
      fail "Feature name not defined" unless feature_name

      rake_desc = Rake.application.last_description
      tags = resolve_tags(options[:tags])

      Cucumber::Rake::Task.new(name, rake_desc) do |task|
        task.cucumber_opts = ["--name '#{feature_name}'"]
        task.cucumber_opts << "--tags #{tags}" unless tags.empty?
        task.cucumber_opts << "--require #{Cct.root.join("features")}"
        yield(task) if block_given?
      end
    end

    def before task, prerequisite=nil, *args, &block
      if prerequisite.nil?
        letters = [*'a'..'z']
        prerequisite = letters.shuffle.take(10).join
      end

      prerequisite = Rake::Task.define_task(prerequisite, *args, &block)
      Rake::Task[task].enhance([prerequisite])
    end

    def after task, post_task=nil, *args, &block
      if post_task.nil?
        letters = [*'a'..'z']
        post_task = letters.shuffle.take(10).join
      end

      Rake::Task.define_task(post_task, *args, &block)

      post_task = Rake::Task[post_task]
      Rake::Task[task].enhance do
        post_task.invoke
      end
    end

    private

    def resolve_tags tags
      case tags
      when String, Symbol
        tags.to_s
      when Array
        tags.join(",")
      when nil
        ""
      else
        fail "Tags must be an array or string"
      end
    end
  end
end

self.extend(Cct::Dsl)