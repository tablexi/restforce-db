require_relative "../test_helper"

describe ForkedProcess do

  describe "running a forked process" do
    let(:process) do
      ForkedProcess.new.tap do |forked|
        forked.write { |writer| writer.write("Hello!") }
      end
    end

    describe "#run" do

      it "synchronizes the `write` block's output into a `read` block" do
        value = nil

        process.read { |reader| value = reader.read }
        process.run

        expect(value).to_equal("Hello!")
      end

      describe "when the write block exits unsuccessfully due to an error" do
        let(:process) do
          ForkedProcess.new.tap do |forked|
            forked.write { |_| raise "Whoops!" }
            forked.read { |_| nil }
          end
        end

        it "raises an UnsuccessfulExit exception" do
          expect { silence_stream(STDERR) { process.run } }.to_raise(
            ForkedProcess::UnsuccessfulExit,
          )
        end
      end
    end
  end
end
