module EncodingHelper
  def self.detect(attributes = {})
    result = CharlockHolmes::EncodingDetector.detect(attributes[:string])
    if result[:encoding] && result[:confidence] >= (attributes[:confidence_cutoff] || 10)
      result[:encoding]
    else
      attributes[:default]
    end
  rescue
    attributes[:default]
  end

  def self.convert(attributes = {})
    attributes[:string].force_encoding(attributes[:from]).encode(attributes[:to])
  end
end
