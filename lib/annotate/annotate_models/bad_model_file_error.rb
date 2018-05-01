module AnnotateModels
  # This error class is used in AnnotateModels.#get_model_class
  class BadModelFileError < StandardError
    def to_s
      "file doesn't contain a valid model class"
    end
  end
end
