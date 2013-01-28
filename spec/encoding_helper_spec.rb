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
    end

    context "when an execption is raised while attempting to detecting encoding" do
      it "returns the default encoding" do
        CharlockHolmes::EncodingDetector.should_receive(:detect).and_raise(StandardError)

        encoding = EncodingHelper.detect(string: "a string", default: "Shift_JIS")
        encoding.should == "Shift_JIS"
      end
    end
  end
end
