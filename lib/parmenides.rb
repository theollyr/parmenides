require "yaml"
require "rdf"
require "configatron/core"

require "parmenides/client"
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
require "parmenides/evaluation/pnr_resource_evaluator"
require "parmenides/evaluation/tag_resource_evaluator"
require "parmenides/evaluation/resource_evaluator"
require "parmenides/evaluation/property_evaluator"

require "parmenides/version"
