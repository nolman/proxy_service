class DocumentConverter

  def initialize(document, mapping)
    @document = document
    @mapping = mapping
  end

  def mapping_to_json
    {}.tap do |result|
      @mapping.each do |key, locator|
        result[key] = value_for(normalize_locator(locator))
      end
    end
  end

  def normalize_locator(locator)
    if locator.is_a?(Hash)
      locator
    elsif locator.is_a?(Array) && locator.first.is_a?(Hash)
      locator
    elsif locator.is_a?(Array) && !locator.first.is_a?(Hash)
      [{'path' => locator.first}]
    else
      {'path' => locator}
    end
  end

  def value_for(locator)
    if locator.is_a?(Array)
      locator = locator.first
      elements = @document.search(locator['path'])
      elements.map {|element| get_value_for(element, locator) }
    else
      element = @document.at(locator['path'])
      get_value_for(element, locator)
    end
  end

  def get_value_for(element, locator)
    if locator['attr'].to_s == ""
      element.inner_html
    else
      element[locator['attr']]
    end
  end

end
