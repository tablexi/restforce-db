# FileDaemon defines some standard hooks for forking processes which retain
# file descriptors.
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

    # Public: Store the list of currently open file descriptors so that they
    # may be reopened when a new process is spawned.
    #
    # Returns nothing.
    def before_fork
      return if @files_to_reopen

      @files_to_reopen = []
      ObjectSpace.each_object(File) do |file|
        @files_to_reopen << file unless file.closed?
      end
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
        rescue ::Exception # rubocop:disable HandleExceptions, RescueException
        end
      end
    end

  end

end
