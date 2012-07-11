module NCBO
  class ResourceIndex

    class Annotations
      attr_accessor :resource, :annotations, :total_annotation_count, :offset, :limit
    end
    
    class Annotation
      attr_accessor :score, :concept, :context, :element
    end

    class RankedElements
      attr_accessor :concepts, :resources
    end

  end
end