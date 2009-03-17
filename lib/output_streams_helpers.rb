module OutputStreamsHelpers
  def output_stream(otype, *parts)
    OutputStreams::OutputStream.new(otype).output(*parts)
  end
end
