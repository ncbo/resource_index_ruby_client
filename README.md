## About

The NCBO Resource Index Gem is a Ruby client for NCBO's Rsource Index Web service. The NCBO Resource Index is a system for ontology based annotation and indexing of biomedical data; the key functionality of this system is to enable users to locate biomedical data resources related to particular concepts. A set of annotations is generated automatically and presented through integration with BioPortal, enabling researchers to search for biomedical resources associated (annotated) with specific ontology terms. This service uses a concept recognizer (developed by the National Center for Integrative Biomedical Informatics, University of Michigan) to produce a set of annotations and expand them using ontology is_a relations.

## Installation

    gem install ncbo_resource_index

## Usage
You must always supply an NCBO API Key when using the Resource Index. To get an NCBO API Key, please create an account at [NCBO BioPortal](http://bioportal.bioontology.org/accounts/new).

### Without instantiation
    # Return a set of annotations for a given set of concepts
    result = NCBO::ResourceIndex.find_by_concept(["1032/Melanoma"], :apikey => "your API Key")
    # Return a set of annotations for a given element/resource pair
    result = NCBO::ResourceIndex.find_by_element("E-GEOD-19229", "GEO", :apikey => "your API Key")

### With instantiation
    ri = NCBO::ResourceIndex.new(:apikey => "your API Key")
    result_concept = ri.find_by_concept(["1032/Melanoma"])
    result_element = ri.find_by_element("E-GEOD-19229", "GEO")
    
### Getting a list of Resources available in the Resource Index

    NCBO::ResourceIndex.resources(:apikey => "your API Key")

### Getting a list of ontologies available in the Resource Index
The NCBO Resource Index uses a set of ontologies when annotating resources. To see the set currently in use, you can do the following:

    NCBO::ResourceIndex.ontologies(:apikey => "your API Key")
    
## Available Options
The following default options are used with the NCBO Resource Web service via the client.

      @options[:resource_index_location]  = "http://rest.bioontology.org/resource_index/"
      @options[:filterNumber]             = true
      @options[:isStopWordsCaseSensitive] = false
      @options[:isVirtualOntologyId]      = true
      @options[:levelMax]                 = 0
      @options[:longestOnly]              = false
      @options[:ontologiesToExpand]       = []
      @options[:ontologiesToKeepInResult] = []
      @options[:mappingTypes]             = []
      @options[:minTermSize]              = 3
      @options[:scored]                   = true
      @options[:semanticTypes]            = []
      @options[:stopWords]                = []
      @options[:wholeWordOnly]            = true
      @options[:withDefaultStopWords]     = true
      @options[:withSynonyms]             = true
      @options[:conceptids]               = []
      @options[:mode]                     = :union
      @options[:elementid]                = []
      @options[:resourceids]              = []
      @options[:elementDetails]           = false
      @options[:withContext]              = true
      @options[:offset]                   = 0
      @options[:limit]                    = 10
      @options[:format]                   = :xml
      @options[:counts]                   = false
      @options[:request_timeout]          = 300
    
Default options may be overridden by providing them as follows:

    ri = NCBO::ResourceIndex.new(:apikey => "your API Key", :minTermSize => 5, :ontologiesToKeepInResult => [1032, 1084])
    ri = NCBO::ResourceIndex.new(:apikey => "your API Key", :wholeWordOnly => false, :levelMax => 2)
    ri = NCBO::ResourceIndex.new(:apikey => "your API Key", :semanticTypes => ["T047", "T048", "T191"])
    
For more information on available option values, please see the NCBO Resource Index [Web service documentation](http://www.bioontology.org/wiki/index.php/Resource_Index_REST_Web_Service_User_Guide).

## Contact
For questions please email [support@bioontology.org](support@bioontology.org).

On Twitter: [@palexander](https://twitter.com/palexander), [@bioontology](https://twitter.com/bioontology)

## License (BSD two-clause)

Copyright (c) 2011, The Board of Trustees of Leland Stanford Junior University
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
      conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
      of conditions and the following disclaimer in the documentation and/or other materials
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE BOARD OF TRUSTEES OF LELAND STANFORD JUNIOR UNIVERSITY
''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL The Board of Trustees of Leland Stanford Junior University OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those of the
authors and should not be interpreted as representing official policies, either expressed
or implied, of The Board of Trustees of Leland Stanford Junior University.




