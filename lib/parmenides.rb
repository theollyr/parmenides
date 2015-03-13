require "yaml"

require "rdf"
require "sparql/client"

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
  Client = SPARQL::Client.new "http://localhost:8890/sparql"
  DBpOntology = Ontology.new client: Client, resource_vocab: RDF::Vocabulary.new( "http://dbpedia.org/ontology/" )
  InfoboxStat = Infobox.new name: "štát", ontology: Parmenides::DBpOntology, client: Parmenides::Client
  StatKlassMapping = Mappers::BasicKlassMapper.mapping_for InfoboxStat.resources
  StatRB = Evaluation::ResourceBase.build based_on: InfoboxStat.resources
end
