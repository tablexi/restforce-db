# FileDaemon defines some standard hooks for forking processes which retain
# file descriptors. Implementation derived from the Delayed::Job library:
# https://github.com/collectiveidea/delayed_job/blob/master/lib/delayed/worker.rb#L77-L98.
module FileDaemon

  # Public: Extend the including class with before/after_fork hooks.
  #
  # base - The including class.
  #
  # Returns nothing.
  def self.included(base)
    base.extend(ClassMethods)
  end

  # :nodoc:
  module ClassMethods

    # Public: Force-reopen all files at their current paths. Allows for rotation
    # of log files outside of the context of an actual process fork.
    #
    # Returns nothing.
    def reopen_files
      before_fork
      after_fork
    end

    # Public: Store the list of currently open file descriptors so that they
    # may be reopened when a new process is spawned.
    #
    # Returns nothing.
    def before_fork
      @files_to_reopen = ObjectSpace.each_object(File).reject(&:closed?)
    end

    # Public: Reopen all file descriptors that have been stored through the
    # before_fork hook.
    #
    # Returns nothing.
    def after_fork
      @files_to_reopen.each do |file|
        begin
          file.reopen file.path, "a+"
          file.sync = true
        rescue ::IOError # rubocop:disable HandleExceptions
        end
      end
    end

  end

end
