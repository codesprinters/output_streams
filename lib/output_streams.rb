module OutputStreams

  # The OutputStream class.
  # OutputStream objects have only one useful method: output. It takes aribitrary
  # number of StreamParts and returns textual representation of them
  # in the format supplied to OutputStream constructor
  class OutputStream
    attr_reader :output_type

    # Creates a new output stream with specified output_type
    #
    # example: OutputStream.new(:'text/html')
    def initialize(output_type)
      @output_type = output_type
    end

    # returns concatenated contents of given parts in this stream output format
    def output(*parts)
      parts.map {|part| part.convert(output_type).content}.join ''
    end
  end

  class ConvertersHash #:nodoc:
    def initialize
      @converters = Hash.new
    end

    def [](from,to)
      coll_from = @converters[from]
      return nil if coll_from.nil?
      return coll_from[to]
    end
    def []=(from,to,cnv)
      @converters[from] ||= Hash.new
      @converters[from][to] = cnv
    end
  end


  # A stream part - piece of data that can be output into OutputStream.
  # Basically this is just a string that knows its content-type (eg. if it's
  # plaintext or html). When supplied to an output stream it will automatically
  # get converted to proper output type if a converter is known (only text/plain -> text/html
  # converter is built-in).
  # 
  # To add your own converters just insert a Proc object to converters property:
  # StreamPart.converters[:'text/plain', :'text/javascript'] = lambda {|x| code_that_escapes_text_to_make_it_js_safe(x)}
  class StreamPart
    extend ERB::Util
    attr_reader :type
    attr_reader :content
    cattr_reader :converters

    @@converters = ConvertersHash.new
    @@converters[:'text/plain', :'text/html'] = lambda {|x| html_escape(x)}

    # creates a new StreamPart with given content-type (a symbol, like :"text/plain") and contents
    def initialize(type, content)
      @type = type
      @content = content
    end

    # ensures that the output is a stream part
    # if supplied with stream part it returns that part, if supplied with anything else it returns
    # a part with text/plain type containing x.to_s 
    def self.to_stream_part(x)
      return nil if x.nil?
      case x
        when StreamPart
          return x
        else
          return StreamPart.new(:'text/plain', x.to_s)
      end
    end

    # converts this part to given output type (overwriting old content)
    def convert!(output_type)
      return if output_type == type

      converter = @@converters[type,output_type]
      
      raise "No conversion found from #{@type} to #{output_type}" if converter.nil?

      @content = converter.call(@content)
      @type = output_type
    end

    # creates a copy of this part converted to given content-type
    def convert(output_type)
      msg = self.dup
      msg.convert!(output_type)
      return msg
    end
  end
end
