require 'net/http'
require 'xml'
require 'uri'
require 'open-uri'
require 'cgi'
require 'ncbo_resource_index/parser'
require 'ncbo_resource_index/data'


module NCBO
  class ResourceIndex

    def initialize(args = {})
      @options = {}
  
      # Shared with Annotator
      @options[:resource_index_location] = "http://rest.bioontology.org/resource_index/"
      @options[:filterNumber] = true
      @options[:isStopWordsCaseSensitive] = false
      @options[:isVirtualOntologyId] = true
      @options[:levelMax] = 0
      @options[:longestOnly] = false
      @options[:ontologiesToExpand] = []
      @options[:ontologiesToKeepInResult] = []
      @options[:mappingTypes] = []
      @options[:minTermSize] = 3
      @options[:scored] = true
      @options[:semanticTypes] = []
      @options[:stopWords] = []
      @options[:wholeWordOnly] = true
      @options[:withDefaultStopWords] = true
      @options[:withSynonyms] = true
      
      # RI-specific
      @options[:conceptids] = []
      @options[:mode] = :union
      @options[:elementid] = []
      @options[:resourceids] = []
      @options[:elementDetails] = false
      @options[:withContext] = true
      @options[:offset] = 0
      @options[:limit] = 10
      @options[:format] = :xml
      @options[:counts] = false
      @options[:request_timeout] = 300
      
      @options.merge!(args)
      
      @ontologies = nil
      @options[:resourceids] ||= []
      
      # Check to make sure mappingTypes are capitalized
      fix_params
    
      raise ArgumentError, ":apikey is required, you can obtain one at http://bioportal.bioontology.org/accounts/new" if @options[:apikey].nil?
    end

    def self.find_by_concept(concepts, options = {})
      new(options).find_by_concept(concepts)
    end
  
    def find_by_concept(concepts = [], options = {})
      @options[:conceptids] = concepts unless concepts.nil? || concepts.empty?
      @options.merge!(options) unless options.empty?
      fix_params
      
      raise ArgumentError, ":conceptids must be included" if @options[:conceptids].nil? || @options[:conceptids].empty?
      
      result_xml = resource_index_post
      Parser::ResourceIndex.parse_results(result_xml)
    end
    
    def self.find_by_element(element, resource, options = {})
      new(options).find_by_element(element, resource)
    end
    
    def find_by_element(element, resource, options = {})
      @options[:elementid] = element unless element.nil? || element.empty?
      @options[:resourceids] = [resource] unless resource.nil? || resource.empty?
      @options.merge!(options) unless options.empty?
      fix_params
      raise ArgumentError, ":elementid must be included" if @options[:elementid].nil? || @options[:elementid].empty?
      raise ArgumentError, ":resourceids must be included" if @options[:resourceids].nil? || @options[:resourceids].empty?
      Parser::ResourceIndex.parse_results(resource_index_post)
    end
    
    def self.element_annotations(element, concepts, resource, options = {})
      new(options).element_annotations(element, concepts)
    end
    
    def element_annotations(element, concepts, resource)
      @options[:conceptids] = concepts unless concepts.nil? || concepts.empty?
      raise ArgumentError, ":conceptids must be included" if @options[:conceptids].nil? || @options[:conceptids].empty?
      raise ArgumentError, ":resourceids must be an array" unless @options[:resourceids].kind_of? Array
      resource = resource.upcase
      
      concept_annotations = []
      concepts.each do |concept|
        split_concept = concept.split("/")
        ontology_id = split_concept[0]
        concept_id = split_concept[1]
        virtual = @options[:isVirtualOntologyId] ? "/virtual" : ""
        result_xml = open(["#{@options[:resource_index_location]}",
                           "details/#{@options[:elementDetails]}",
                           virtual,
                           "/concept/#{ontology_id}",
                           "/resource/#{resource}",
                           "/#{@options[:offset]}",
                           "/#{@options[:limit]}",
                           "?conceptid=#{CGI.escape(concept_id)}",
                           "&elementid=#{CGI.escape(element)}",
                           "&apikey=#{@options[:apikey]}"].join("")).read

        annotations = Parser::ResourceIndex.parse_element_annotations(result_xml)
        concept_annotations << annotations
      end

      if concept_annotations.length > 1
        # Merge the two result sets
        primary_annotations = Annotations.new
        primary_annotations.annotations = []
        primary_annotations.resource = resource
        concept_annotations.each do |result|
          primary_annotations.annotations.concat result.annotations
        end
      elsif concept_annotations.length == 1
        primary_annotations = concept_annotations[0]
      else
        primary_annotations = nil
      end
      primary_annotations
    end

    def self.ranked_elements(concepts, options = {})
      new(options).ranked_elements(concepts)
    end
  
    def ranked_elements(concepts = [], options = {})
      @options[:conceptids] = concepts unless concepts.nil? || concepts.empty?
      @options[:resourceids] ||= []
      @options.merge!(options) unless options.empty?
      fix_params
      
      raise ArgumentError, ":conceptids must be included" if @options[:conceptids].nil? || @options[:conceptids].empty?
      raise ArgumentError, ":resourceids must be an array" unless @options[:resourceids].kind_of? Array
      
      puts ["#{@options[:resource_index_location]}",
                         "elements-ranked-by-concepts/#{@options[:resourceids].join(",")}",
                         "?offset=#{@options[:offset]}",
                         "&limit=#{@options[:limit]}",
                         "&conceptids=#{@options[:conceptids].join(",")}",
                         "&ontologiesToKeepInResult=#{@options[:ontologiesToKeepInResult].join(",")}",
                         "&isVirtualOntologyId=#{@options[:isVirtualOntologyId]}",
                         "&apikey=#{@options[:apikey]}"].join("")
      result_xml = open(["#{@options[:resource_index_location]}",
                         "elements-ranked-by-concepts/#{@options[:resourceids].join(",")}",
                         "?offset=#{@options[:offset]}",
                         "&limit=#{@options[:limit]}",
                         "&conceptids=#{@options[:conceptids].join(",")}",
                         "&ontologiesToKeepInResult=#{@options[:ontologiesToKeepInResult].join(",")}",
                         "&isVirtualOntologyId=#{@options[:isVirtualOntologyId]}",
                         "&apikey=#{@options[:apikey]}"].join("")).read
      Parser::ResourceIndex.parse_ranked_element_results(result_xml)
    end
    
    def self.popular_concepts(resources = nil, options = {})
      new(options).popular_concepts(resources)
    end
    
    def popular_concepts(resources = nil, options = {})
      @options[:resourceids] = resources
      @options[:resourceids] = [resources] unless resources.nil? || resources.empty? || resources.kind_of?(Array)
      @options.merge!(options) unless options.empty?
      fix_params
      
      if @options[:resourceids].nil? || @options[:resourceids].empty?
        @options[:resourceids] = self.resources.collect {|resource| resource[:resourceId]}
      end
      
      popular_concepts = {}
      @options[:resourceids].each do |resource|
        popular_concepts_xml = open("#{@options[:resource_index_location]}most-used-concepts/#{resource}?apikey=#{@options[:apikey]}&offset=#{@options[:offset]}&limit=#{@options[:limit]}").read
        popular_concepts[resource] = Parser::ResourceIndex.parse_popular_concepts(popular_concepts_xml)
      end
      popular_concepts
    end

    def self.ontologies(options)
      new(options).ontologies
    end
    
    def ontologies(options = {})
      @options.merge!(options) unless options.empty?

      if @ontologies.nil?
        ontologies_xml = open("#{@options[:resource_index_location]}ontologies?apikey=#{@options[:apikey]}").read
        @ontologies = Parser::ResourceIndex.parse_included_ontologies(ontologies_xml)
      else
        @ontologies
      end
    end

    def self.resources(options)
      new(options).resources
    end
    
    def resources(options = {})
      @options.merge!(options) unless options.empty?

      if @resources.nil?
        resources_xml = open("#{@options[:resource_index_location]}resources?apikey=#{@options[:apikey]}").read
        @resources = Parser::ResourceIndex.parse_resources(resources_xml)
      else
        @resources
      end
    end
    
    def self.resources_hash(options)
      new(options).resources_hash
    end

    def resources_hash(options = {})
      @options.merge!(options) unless options.empty?
      resources = resources()
      resources_hash = {}
      resources.each {|res| resources_hash[res[:resourceId].downcase.to_sym] = res}
      resources_hash
    end
    
    def options
      @options
    end
    
    private
    
    def fix_params
      @options[:mappingTypes] = @options[:mappingTypes].split(",") if @options[:mappingTypes].kind_of?(String)
      @options[:ontologiesToExpand] = @options[:ontologiesToExpand].split(",") if @options[:ontologiesToExpand].kind_of?(String)
      @options[:ontologiesToKeepInResult] = @options[:ontologiesToKeepInResult].split(",") if @options[:ontologiesToKeepInResult].kind_of?(String)
      @options[:semanticTypes] = @options[:semanticTypes].split(",") if @options[:semanticTypes].kind_of?(String)
      @options[:stopWords] = @options[:stopWords].split(",") if @options[:stopWords].kind_of?(String)
      @options[:mappingTypes].collect! {|e| e.capitalize} unless @options[:mappingTypes].nil?
    end

    def resource_index_post
      url = URI.parse(@options[:resource_index_location])
      request_body = []
      @options.each do |k,v|
        next if v.kind_of?(Array) && v.empty?
        if v.kind_of?(Array)
          request_body << "#{k}=#{v.collect {|val| CGI.escape(val)}.join(",")}"
        else
          request_body << "#{k}=#{v}"
        end
      end
      req = Net::HTTP::Post.new(url.path)
      req.body = request_body.join("&")
      http = Net::HTTP.new(url.host, url.port)
      http.read_timeout = @options[:request_timeout]
      res = http.start {|http| http.request(req)}
      res.body
    end
  end
end
