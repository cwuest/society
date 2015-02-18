require 'digest'
require 'fileutils'

module Society

  class FileCache

    attr_reader :cache_dir

    def initialize(cache_dir, *file_paths)
      self.cache_dir = cache_dir
      self.files = file_paths.map { |file| explode_paths(file) }.flatten
    end

    def unchanged_files
      md5_filter(:select)
    end

    def updated_files
      md5_filter(:reject)
    end

    def []=(path, data)
      ensure_directory_exists(path)
      File.open(file_path(path), 'w') { |file| file.write Marshal.dump(data) }
    end

    def [](path)
      Marshal.load(File.read(file_path(path)))
    end

    private

    attr_writer   :cache_dir
    attr_accessor :files

    def explode_paths(path)
      if File.directory?(path)
        Dir.glob("#{path}/**/*.rb")
      else
        path
      end
    end

    def md5_digest(path)
      Digest::MD5.new.hexdigest(File.read(path))
    end

    def md5_filter(target_method)
      files.public_send(target_method) { |path| File.exist?(file_path(path)) }
    end

    def file_path(path)
      target_path = "#{md5_digest(path)}_#{File.basename(path)}"
      File.join(cache_dir, File.dirname(path), target_path)
    end

    def ensure_directory_exists(path)
      dirname = File.dirname(File.join(cache_dir, path))
      FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    end

  end

end

