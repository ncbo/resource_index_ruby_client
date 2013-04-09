require "test/unit"
require_relative "../lib/ncbo_resource_index"

class TestResourceIndex < Test::Unit::TestCase
  APIKEY = ENV["APIKEY"] || ""
  LOCATION = "http://rest.bioontology.org/resource_index/"

  def test_apikey
    raise ArgumentError, "You must provide an API Key" if APIKEY.nil? || APIKEY.empty?
  end

  def test_instantiation
    resource_index = NCBO::ResourceIndex.new(:apikey => APIKEY, :resource_index_location => LOCATION)
    assert resource_index.kind_of?(NCBO::ResourceIndex)
    
    melanoma = resource_index.find_by_concept("1032/Melanoma")
    cancer = resource_index.find_by_concept("1032/Malignant_Neoplasm")
    assert cancer != melanoma
  end
  
  def test_direct_usage
    result = NCBO::ResourceIndex.find_by_concept("1032/Melanoma", :apikey => APIKEY, :resource_index_location => LOCATION)
    assert !result.nil? && result.length > 0
  end
  
  def test_alternative_location
    alt_location = "http://stagerest.bioontology.org/resource_index/"
    resource_index = NCBO::ResourceIndex.new(:apikey => APIKEY, :resource_index_location => alt_location)
    assert resource_index.options[:resource_index_location] == alt_location
  end
  
  def test_find_by_concept
    result = NCBO::ResourceIndex.find_by_concept("1032/Melanoma", :apikey => APIKEY, :resource_index_location => LOCATION)
    assert result[1].annotations.kind_of?(Array)
    contains_results = false
    result.each do |res|
      contains_results = true if res.annotations.length > 1
    end
    assert contains_results
  end
  
  def test_find_by_element
    resource = "CANANO"
    result = NCBO::ResourceIndex.find_by_element("12451849", resource, :apikey => APIKEY, :resource_index_location => LOCATION)
    assert result.annotations.kind_of?(Array)
    assert result.annotations.length > 1
    assert result.resource = resource
  end
  
  def test_popular_concepts_one_resource
    result = NCBO::ResourceIndex.popular_concepts("CANANO", :apikey => APIKEY, :resource_index_location => LOCATION)
    result.length == 1
  end
  
  def test_popular_concepts_multiple_resources
    result = NCBO::ResourceIndex.popular_concepts(["CANANO", "PM"], :apikey => APIKEY, :resource_index_location => LOCATION)
    result.length == 1
  end
  
  def test_popular_concepts_all_resources
    ri = NCBO::ResourceIndex.new(:apikey => APIKEY, :resource_index_location => LOCATION)
    result = ri.popular_concepts
    result.length == ri.resources.length
  end
  
  def test_resources
    ri = NCBO::ResourceIndex.new(:apikey => APIKEY, :resource_index_location => LOCATION)
    assert ri.resources.length >= 23
    test_resource = nil
    ri.resources.each {|resource| test_resource = resource if resource[:resourceId].downcase == "bsm"}
    assert !test_resource.nil?
  end
    
  def test_ontologies
    ri = NCBO::ResourceIndex.new(:apikey => APIKEY, :resource_index_location => LOCATION)
    assert ri.ontologies.length >= 250
    test_ontology = nil
    ri.ontologies.each {|ont| test_ontology = ont if ont[:virtualOntologyId] == 1032}
    assert !test_ontology.nil?
  end
  
end