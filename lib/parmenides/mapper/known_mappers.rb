module Parmenides
  module Mappers

    max_proc = lambda { |data| data.max_by { |_, v| v }[0] unless data.empty? }

    BasicKlassMapper = Mapper.new(
      preprocessor: MergePreprocessor,
      processor: HistogramProcessor,
      finisher: max_proc
      )

    SpecificKlassMapper = Mapper.new(
      preprocessor: MergePreprocessor,
      processor: SpecificProcessor,
      finisher: max_proc
      )

    GenericKlassMapper = Mapper.new(
      preprocessor: MergePreprocessor,
      processor: GenericProcessor,
      finisher: max_proc
      )

    BasicPropertyMapper = Mapper.new(
      processor: lambda do |data|
        Hash[data.reject do |prop, rel|
          rel.max_by { |_, score| score }[1] <= 3
        end.map do |prop, rel|
          [ prop, rel.max_by { |_, score| score }[0] ]
        end]
      end
      )

  end
end
