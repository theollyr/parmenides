require "yaml"

require "rdf"
require "sparql/client"

require "configatron/core"

require "parmenides/environment"

require "parmenides/cachable"

require "parmenides/entity"
require "parmenides/ontology/klass"
require "parmenides/ontology/property"
require "parmenides/ontology"
require "parmenides/resource"

require "parmenides/infobox"
# require "parmenides/loader/klass_loader"

require "parmenides/processor"
require "parmenides/processor/histogram_processor"
require "parmenides/processor/generic_processor"
require "parmenides/processor/specific_processor"
require "parmenides/processor/merge_preprocessor"

require "parmenides/mapper/mapper"
require "parmenides/mapper/known_mappers"

require "parmenides/evaluation/evaluation_result"
require "parmenides/evaluation/resource_base"
require "parmenides/evaluation/evaluator"
require "parmenides/evaluation/resource_evaluator"
require "parmenides/evaluation/property_evaluator"

require "parmenides/version"

module Parmenides
  # Your code goes here...
  ENV = Environment.from_parameters client: "http://localhost:8890/sparql", main_language: "sk",
  		other_languages: [ "en", "es", "de" ], template: "Šablóna:Infobox_",
  		cache_dir: "/home/brenin/swe/cache"

  InfoboxStat = Infobox.new name: "štát", environment: ENV
  # StatKlassMapping = Mappers::BasicKlassMapper.mapping_for InfoboxStat.resources
  # StatRB = Evaluation::ResourceBase.build based_on: InfoboxStat.resources
end
