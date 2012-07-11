module NCBO
  module Parser
    
    class BaseParser
      def parse_xml(xml)
        if xml.kind_of?(String)
          parser = XML::Parser.string(xml, :options => LibXML::XML::Parser::Options::NOBLANKS)
        else
          parser = XML::Parser.io(xml, :options => LibXML::XML::Parser::Options::NOBLANKS)
        end
        parser.parse
      end
      
      def safe_to_i(str)
        Integer(str) rescue str
      end
    end
    
    class ResourceIndex < BaseParser
      def initialize(results)
        @root = "/success/data/annotatorResultBean"
        @results = parse_xml(results)
      end
      
      def self.parse_included_ontologies(ontologies)
        new(ontologies).parse_included_ontologies
      end
        
      def parse_included_ontologies
        @root = "/success/data/set"
        ontologies = parse_ontologies("ontology")
      end
      
      def self.parse_resources(resources)
        new(resources).parse_resources
      end
        
      def parse_resources
        resources = []
        @results.find("/success/data/set/resource").each do |resource|
          a = {}
          resource.children.each {|child| a[child.name.to_sym] = safe_to_i(child.content) if !child.first.nil? && !child.first.children?}
          a[:contexts] = parse_resource_structure(resource.find_first("resourceStructure"))
          resources << a
        end
        resources
      end
      
      def self.parse_results(results, options = {})
        new(results).parse_results(options)
      end
      
      def parse_results(options = {})
        resource ||= options[:resource]
        annotation_location ||= options[:annotation_location]
        
        results = []
        @results.find("/success/data/list/*").each do |result|
          resource_annotations = NCBO::ResourceIndex::Annotations.new
          resource_annotations.resource = resource ||= result.find_first("resourceId").content

          # Check to see if parameters are enabled that will change how we process the output
          with_context = result.find_first("withContext").content.eql?("true") rescue false
          counts = result.find_first("counts").content.eql?("true") rescue false

          # Update total count (if available)
          resource_annotations.total_annotation_count = result.find_first("resultStatistics/statistics/annotationCount").content.to_i if counts
          
          resource_annotations.annotations = parse_annotations(result, with_context, annotation_location)
          results << resource_annotations
        end
        results = results[0] if results.kind_of?(Array) && results.length == 1
        results
      end
      
      def self.parse_ranked_element_results(results)
        new(results).parse_ranked_element_results
      end

      def parse_ranked_element_results
        ranked_elements = NCBO::ResourceIndex::RankedElements.new

        ranked_elements.concepts = []
        @results.find("/success/data/map/entry[string='concepts']/list/*").each do |concept|
          concept = parse_concept(concept, ".")
          ranked_elements.concepts << concept
        end

        ranked_elements.resources = []
        @results.find("/success/data/map/entry[string='elements']/list/resourceElements").each do |resource|
          r = {}
          r[:resourceId] = resource.find_first("resourceId").content
          r[:offset] = resource.find_first("offset").content.to_i
          r[:limit] = resource.find_first("limit").content.to_i
          r[:totalResults] = resource.find_first("totalResults").content.to_i
          r[:elements] = []
          resource.find("./elementResults/elementResult").each do |element|
            r[:elements] << parse_element(element)
          end
          ranked_elements.resources << r
        end

        ranked_elements
      end

      def self.parse_popular_concepts(results)
        new(results).parse_popular_concepts
      end

      def parse_popular_concepts
        concepts = []
        @results.find("/success/data/list/*").each do |concept_frequency|
          concept = {}
          concept[:counts] = concept_frequency.find_first("counts").content.to_i
          concept[:score] = concept_frequency.find_first("score").content.to_i
          concept[:concept] = parse_concept(concept_frequency)
          concepts << concept
        end
        concepts
      end

      def self.parse_element_annotations(results)
        new(results).parse_element_annotations
      end
      
      def parse_element_annotations
        annotation_location = "annotation"
        with_context = false
        
        annotations = NCBO::ResourceIndex::Annotations.new
        annotations.annotations = parse_annotations(@results.find_first("/success/data/list"), with_context, annotation_location)
        annotations
      end

      private

      def parse_annotations(result, with_context = false, annotation_location = "annotations/*")
        annotations = []
        if with_context
          result.find("mgrepAnnotations/*").each do |annotation|
            annotations << parse_annotation(annotation)
          end
          result.find("reportedAnnotations/*").each do |annotation|
            annotations << parse_annotation(annotation)
          end
          result.find("isaAnnotations/*").each do |annotation|
            annotations << parse_annotation(annotation)
          end
          result.find("mappingAnnotations/*").each do |annotation|
            annotations << parse_annotation(annotation)
          end
        else
          result.find(annotation_location).each do |annotation|
            annotations << parse_annotation(annotation)
          end
        end
        annotations
      end
      
      def parse_annotation(annotation, context = false)
        new_annotation = NCBO::ResourceIndex::Annotation.new
        new_annotation.score = annotation.find_first("score").content.to_f
        new_annotation.concept = parse_concept(annotation)
        new_annotation.context = parse_context(annotation)
        new_annotation.element = parse_element(annotation)
        new_annotation
      end
      
      # The only thing we care about from here is the contexts, everything else is internal info
      def parse_resource_structure(resource_structure)
        contexts = []
        resource_structure.find_first("contexts").each {|context| contexts << context.first.content}
        contexts
      end
      
      def parse_ontologies(ontology_location = "ontologies/ontologyUsedBean")
        ontologies = []
        @results.find(@root + "/#{ontology_location}").each do |ontology|
          ont = {}
          ontology.children.each {|child| ont[child.name.to_sym] = safe_to_i(child.content)}
          ontologies << ont
        end
        ontologies
      end
      
      def parse_concept(annotation, concept_location = "concept")
        a = {}
        annotation.find("#{concept_location}/*").each {|child| a[child.name.to_sym] = safe_to_i(child.content) if !child.first.nil? && !child.first.children?}
        a[:synonyms] = annotation.find("#{concept_location}/synonyms/string").map {|syn| safe_to_i(syn.content)}
        semantic_types = parse_semantic_types(annotation.find_first("#{concept_location}/localSemanticTypeIds"))
        a[:semantic_types] = semantic_types
        a
      end

      def parse_semantic_types(semantic_types_xml)
        return Array.new if semantic_types_xml.nil?
        
        semantic_types = []
        semantic_types_xml.each do |semantic_type_bean|
          semantic_type_bean.children.each { |child| semantic_types << safe_to_i(child.content) }
        end
        semantic_types
      end
      
      def parse_context(annotation)
        a = {}
        annotation.find("context/*").each {|child| a[child.name.to_sym] = safe_to_i(child.content) if !child.first.nil? && !child.first.children?}
        a[:contextType] = annotation.find_first("context").attributes["class"] unless annotation.find_first("context").nil?
        a
      end
      
      def parse_element(annotation)
        a = {}
        a[:localElementId] = annotation.find_first("element/localElementId").content unless annotation.find_first("element/localElementId").nil?
        # element text
        a[:text] = {}
        annotation.find("element/elementStructure/contexts/*").each {|context| a[:text][context.children[0].content] = context.children[1].content}
        # element weights
        a[:weights] = []
        annotation.find("element/elementStructure/weights/*").each {|weight| a[:weights] << {:name => weight.children[0].content, :weight => weight.children[1].content.to_f} }
        # which element portions are associated with an ontology
        a[:ontoIds] = {}
        annotation.find("element/elementStructure/ontoIds/*").each {|ont_id| a[:ontoIds][ont_id.children[0].content] = ont_id.children[1].content.to_i}
        return a
      end
    end
    
  end
end