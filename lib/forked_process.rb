require "English"

# ForkedProcess exposes a small API for performing a block of code in a
# forked process, and relaying its output to another block.
class ForkedProcess

  class UnsuccessfulExit < RuntimeError; end

  # Public: Define a callback which will be run in a forked process.
  #
  # Yields an IO object opened for writing when `run` is invoked.
  # Returns nothing.
  def write(&block)
    @write_block = block
  end

  # Public: Define a callback which reads in the output from the forked
  # process.
  #
  # Yields an IO object opened for reading when `run` is invoked.
  # Returns nothing.
  def read(&block)
    @read_block = block
  end

  # Public: Fork a process, opening a pipe for IO and yielding the write and
  # read components to the relevant blocks.
  #
  # Returns nothing.
  def run
    reader, writer = IO.pipe

    pid = fork do
      reader.close
      @write_block.call(writer)
      writer.close
      exit!(0)
    end

    writer.close
    @read_block.call(reader)
    Process.wait(pid)

    raise UnsuccessfulExit unless $CHILD_STATUS.success?
  end

end
