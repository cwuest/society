require 'society/file_cache'

module Society

  class Parser

    FILECACHE_PATH = './doc/society/cache'

    def self.for_files(*file_paths)
      cache = FileCache.new(FILECACHE_PATH, *file_paths)
      asts  = [process_updated_files(cache), process_unchanged_files(cache)]
      new(asts.flatten.compact)
    end

    def self.for_source(source)
      new(::Analyst.for_source(source))
    end

    def initialize(classes)
      @classes = classes.flatten
    end

    def report(format, output_path=nil)
      raise ArgumentError, "Unknown format #{format}" unless known_formats.include?(format)
      options = { json_data: json_data }
      options[:output_path] = output_path unless output_path.nil?
      FORMATTERS[format].new(options).write
    end

    private

    attr_reader :classes

    def self.process_updated_files(cache)
      ast          = ::Analyst.for_files(*cache.updated_files)
      class_tuples = ast.classes.map do |klass|
        [klass.location.gsub(/:.*/, ''), klass]
      end
      class_tuples.map(&:first).uniq.each do |file|
        data = class_tuples.select { |tuple| tuple.first == file }.map(&:last)
        cache[file] = data
      end

      ast.classes
    end

    def self.process_unchanged_files(cache)
      cache.unchanged_files.map { |path| cache[path] }
    end

    FORMATTERS = {
      html: Society::Formatter::Report::HTML,
      json: Society::Formatter::Report::Json
    }

    def class_graph
      @class_graph ||= begin
        associations = associations_from(classes) + references_from(classes)
        # TODO: merge identical classes, and (somewhere else) deal with
        #       identical associations too. need a WeightedEdge, and each
        #       one will be unique on [from, to], but will have a weight

        ObjectGraph.new(nodes: classes, edges: associations)
      end
    end

    def json_data
      Society::Formatter::Graph::JSON.new(class_graph).to_json
    end

    def known_formats
      FORMATTERS.keys
    end

    def associations_from(all_classes)
      @association_processor ||= AssociationProcessor.new(all_classes)
      @association_processor.associations
    end

    def references_from(all_classes)
      @reference_processor ||= ReferenceProcessor.new(all_classes)
      @reference_processor.references
    end

  end

end

