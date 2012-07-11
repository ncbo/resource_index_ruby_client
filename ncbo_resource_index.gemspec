Gem::Specification.new do |s|
  s.name        = 'ncbo_resource_index'
  s.version     = '1.1'
  s.date        = '2012-07-11'
  s.summary     = "The NCBO Resource Index Gem is a Ruby client for NCBO's Resource Index Web service"
  s.description = "The NCBO Resource Index Gem is a Ruby client for NCBO's Resource Index Web service. The NCBO Resource Index is a system for ontology based annotation and indexing of biomedical data; the key functionality of this system is to enable users to locate biomedical data resources related to particular concepts. A set of annotations is generated automatically and presented through integration with BioPortal, enabling researchers to search for biomedical resources associated (annotated) with specific ontology terms. This service uses a concept recognizer (developed by the National Center for Integrative Biomedical Informatics, University of Michigan) to produce a set of annotations and expand them using ontology is_a relations."
  s.authors     = ["Paul R Alexander"]
  s.email       = 'support@bioontology.org'
  s.files       = Dir['lib/**/*.rb'] + ["lib/ncbo_resource_index.rb"]
  s.homepage    = 'http://github.com/ncbo/ncbo_resource_index'
  s.add_runtime_dependency 'libxml-ruby', '~> 2.2.0'
end
