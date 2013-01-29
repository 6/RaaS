require 'spec_helper'

describe EncodingHelper do
  describe ".detect" do
    context "when it returns confidence lower than the cutoff" do
      it "returns the default encoding" do
        CharlockHolmes::EncodingDetector.should_receive(:detect).and_return(confidence: 5, encoding: "GB2312")

        encoding = EncodingHelper.detect(string: "a string", default: "Shift_JIS")
        encoding.should == "Shift_JIS"
      end
    end

    context "when it returns a confidence greater than or equal to the cutoff" do
      it "returns the detected encoding" do
        CharlockHolmes::EncodingDetector.should_receive(:detect).and_return(confidence: 60, encoding: "GB2312")

        encoding = EncodingHelper.detect(string: "a string", default: "Shift_JIS")
        encoding.should == "GB2312"
      end

      it "returns the default encoding if no encoding is returned" do
        CharlockHolmes::EncodingDetector.should_receive(:detect).and_return(confidence: 100, type: :binary)

        EncodingHelper.detect(string: "", default: "Shift_JIS").should == "Shift_JIS"
      end
    end

    context "when an execption is raised while attempting to detecting encoding" do
      it "returns the default encoding" do
        CharlockHolmes::EncodingDetector.should_receive(:detect).and_raise(StandardError)

        encoding = EncodingHelper.detect(string: "a string", default: "Shift_JIS")
        encoding.should == "Shift_JIS"
      end
    end
  end

  describe ".convert" do
    it "force encodes to the given initial encoding" do
      String.any_instance.should_receive(:force_encoding).with("ASCII").and_return("fool")

      EncodingHelper.convert(string: "fool", from: "ASCII", to: "UTF-8")
    end

    it "converts encoding to the given encoding" do
      String.any_instance.should_receive(:encode).with("UTF-8")

      EncodingHelper.convert(string: "fool", from: "ASCII", to: "UTF-8")
    end
  end
end
