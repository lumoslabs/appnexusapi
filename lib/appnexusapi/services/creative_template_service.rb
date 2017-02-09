class AppnexusApi::CreativeTemplateService < AppnexusApi::Service
  def name
    "template"
  end

  def uri_suffix
    "template"
  end

  def delete(id)
    raise AppnexusApi::NotImplemented
  end
end
