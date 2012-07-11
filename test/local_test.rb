require 'rubygems'
require File.expand_path("../../lib/ncbo_resource_index", __FILE__)
require 'active_support'
require "pp"

APIKEY = "your_apikey"

puts "local test"

# ri = NCBO::ResourceIndex.new(:apikey => APIKEY, :resource_index_location => "http://localhost:8080/resource_index_api/")
ri = NCBO::ResourceIndex.new(:apikey => APIKEY, :resource_index_location => "http://stagerest.bioontology.org/resource_index/")

# pp ri.resources
# pp ri.popular_concepts
# pp NCBO::ResourceIndex.ranked_elements(["1032/Melanoma"], :apikey => APIKEY, :resource_index_location => "http://stagerest.bioontology.org/resource_index/")
pp NCBO::ResourceIndex.find_by_element("E-GEOD-19229", "GEO", :apikey => APIKEY, :resource_index_location => "http://stagerest.bioontology.org/resource_index/")


# ann = ri.element_annotations("E-GEOD-18509", ["1032/Melanoma", "1032/Ribonucleic_Acid"], "AE")
# ann = ri.element_annotations("#113900", ["1114/BILA:0000020", "1032/Ribonucleic_Acid"], "OMIM")
# pp ann.annotations

# pp ri.ontologies

# melanoma = ri.find_by_concept("1032/Melanoma")
# cancer = ri.find_by_concept("1032/Malignant_Neoplasm")
# pp cancer
# counts = ri.find_by_concept("1032/Melanoma", :limit => 10, :counts => true)
# pp counts
# counts.each do |result|
#   pp result.resource + " " + result.total_annotation_count.to_s
# end

# pp ri.find_by_concept("1032/Melanoma", :limit => 50, :counts => true, :resourceids => ["AE"])

# ae = ri.find_by_concept("1032/Melanoma", :limit => 50, :counts => true, :withContext => true, :resourceids => ["AE"], :elementDetails => true)

# Mixin for UTF-8 supported substring
class String
  def utf8_slice(index, size = 1)
    self[/.{#{index}}(.{#{size}})/, 1]
  end

  def utf8_slice!(index, size = 1)
    str = self[/.{#{index}}(.{#{size}})/, 1]
    self[/.{#{index}}(.{#{size}})/, 1] = ""
    str
  end
end

def highlight_and_get_context(text, position, words_to_keep = 4)
  # Process the highlighted text
  highlight = ["############", "", "############"]
  highlight[1] = text.utf8_slice(position[0] - 1, position[1] - position[0] + 1)

  # Use scan to split the text on spaces while keeping the spaces
  scan_filter = Regexp.new(/[ ]+?[-\?'"\+\.,]+\w+|[ ]+?[-\?'"\+\.,]+\w+[-\?'"\+\.,]|\w+[-\?'"\+\.,]+|[ ]+?\w+/)
  before = text.utf8_slice(0, position[0] - 1).match(/(\s+\S+|\S+\s+){0,4}$/).to_s
  after = text.utf8_slice(position[1], ActiveSupport::Multibyte::Chars.new(text).length - position[1]).match(/^(\S+\s+\S+|\s+\S+|\S+\s+){0,4}/).to_s

  # The process above will not keep a space right before the highlighted word, so let's keep it here if needed
  kept_space = text.utf8_slice(position[0] - 2) == " " ? " " : ""

  # Put it all together
  [before, kept_space, highlight.join, after].join
end

# ae.annotations.each do |result|
#   # pp result
#   pp "#{result.context[:from]}, #{result.context[:to]}"
#   pp result.element[result.context[:contextName]].length
#   pp result.element
#   pp highlight_and_get_context(result.element[result.context[:contextName]], [result.context[:from], result.context[:to]])
# end

